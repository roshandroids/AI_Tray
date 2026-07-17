import 'dart:async';
import 'dart:convert';

import 'package:ai_tray/core/logging/app_logger.dart';
import 'package:ai_tray/features/providers/copilot/sdk/copilot_sdk.dart';
import 'package:ai_tray/features/providers/copilot/sdk/sidecar_process.dart';

/// Protocol transport surface injected into versioned Copilot SDK clients.
abstract interface class SidecarTransport {
  /// Starts the transport and completes protocol negotiation.
  Future<void> initialize();

  /// Sends one versioned method call and returns its decoded result.
  Future<Object?> request(
    String method, {
    Map<String, Object?> params = const {},
    CopilotSdkCancellationToken? cancellationToken,
  });

  /// Gracefully stops the transport and releases process resources.
  Future<void> shutdown();
}

/// Correlated request/response transport over one persistent NDJSON process.
final class SidecarProcessTransport implements SidecarTransport {
  SidecarProcessTransport({
    required SidecarProcessLauncher launcher,
    required AppLogger logger,
    required String executable,
    required List<String> arguments,
    this.workingDirectory,
    this.requestTimeout = const Duration(seconds: 15),
    this.shutdownTimeout = const Duration(seconds: 5),
    this.maxRestarts = 1,
  }) : _launcher = launcher,
       _logger = logger,
       _executable = executable,
       _arguments = List.unmodifiable(arguments) {
    if (maxRestarts < 0) {
      throw ArgumentError.value(maxRestarts, 'maxRestarts');
    }
  }

  static const protocolVersion = 1;

  final SidecarProcessLauncher _launcher;
  final AppLogger _logger;
  final String _executable;
  final List<String> _arguments;
  final String? workingDirectory;
  final Duration requestTimeout;
  final Duration shutdownTimeout;
  final int maxRestarts;

  final Map<String, _PendingRequest> _pending = {};
  SidecarProcessConnection? _process;
  Future<void>? _initializing;
  Future<void>? _restart;
  StreamSubscription<String>? _stdoutSubscription;
  StreamSubscription<String>? _stderrSubscription;
  var _nextRequestId = 0;
  var _restartCount = 0;
  var _restartExhausted = false;
  var _shuttingDown = false;
  var _initialized = false;

  /// Starts the process once and validates its protocol handshake.
  @override
  Future<void> initialize() {
    if (_initialized) {
      return Future.value();
    }
    if (_restartExhausted) {
      return Future.error(
        const CopilotSdkException(
          code: CopilotSdkErrorCode.processCrashed,
          message: 'Copilot SDK sidecar restart limit was reached',
        ),
      );
    }
    return _initializing ??= _start().whenComplete(() => _initializing = null);
  }

  /// Sends one correlated request with timeout and cooperative cancellation.
  @override
  Future<Object?> request(
    String method, {
    Map<String, Object?> params = const {},
    CopilotSdkCancellationToken? cancellationToken,
  }) async {
    if (_shuttingDown) {
      throw const CopilotSdkException(
        code: CopilotSdkErrorCode.processCrashed,
        message: 'Copilot SDK sidecar is shutting down',
      );
    }
    final restart = _restart;
    if (restart != null) {
      await restart;
    } else {
      await initialize();
    }
    return _send(
      method,
      params: params,
      cancellationToken: cancellationToken,
    );
  }

  /// Requests graceful shutdown, then force-kills only after the deadline.
  @override
  Future<void> shutdown() async {
    if (_shuttingDown) {
      return;
    }
    _shuttingDown = true;
    final process = _process;
    if (process == null) {
      await _cancelSubscriptions();
      return;
    }

    try {
      if (_initialized) {
        await _send(
          'shutdown',
          timeout: shutdownTimeout,
        );
      }
    } on CopilotSdkException catch (error) {
      _logger.warning(
        'sidecar graceful shutdown failed code=${error.code.name}',
        name: 'copilot_sdk_transport',
      );
    } finally {
      await process.closeInput().catchError((_) {});
      try {
        await process.exitCode.timeout(shutdownTimeout);
      } on TimeoutException {
        process.kill();
      }
      _process = null;
      _initialized = false;
      _failPending(
        const CopilotSdkException(
          code: CopilotSdkErrorCode.cancelled,
          message: 'Copilot SDK sidecar stopped',
        ),
      );
      await _cancelSubscriptions();
    }
  }

  Future<void> _start() async {
    _logger.debug(
      'starting persistent Copilot SDK sidecar',
      name: 'copilot_sdk_transport',
    );
    SidecarProcessConnection process;
    try {
      process = await _launcher.start(
        _executable,
        _arguments,
        workingDirectory: workingDirectory,
      );
    } on Exception {
      throw const CopilotSdkException(
        code: CopilotSdkErrorCode.processLaunchFailed,
        message: 'Could not start the Copilot SDK sidecar',
        retryable: true,
      );
    }

    _process = process;
    _stdoutSubscription = process.stdoutLines.listen(
      _handleStdout,
      onError: (_) => _handleProtocolFailure(),
    );
    _stderrSubscription = process.stderrLines.listen(_handleStderr);
    unawaited(process.exitCode.then((code) => _handleExit(process, code)));

    try {
      final handshake = await _send(
        'handshake',
        params: const {
          'supportedVersions': [protocolVersion],
        },
      );
      final result = _expectMap(handshake, 'handshake');
      if (result['negotiatedVersion'] != protocolVersion) {
        throw const CopilotSdkException(
          code: CopilotSdkErrorCode.protocolMismatch,
          message: 'Copilot SDK bridge protocol is incompatible',
        );
      }
      _initialized = true;
    } on Exception {
      process.kill();
      rethrow;
    }
  }

  Future<Object?> _send(
    String method, {
    Map<String, Object?> params = const {},
    CopilotSdkCancellationToken? cancellationToken,
    Duration? timeout,
  }) {
    final process = _process;
    if (process == null) {
      return Future.error(
        const CopilotSdkException(
          code: CopilotSdkErrorCode.processCrashed,
          message: 'Copilot SDK sidecar is not running',
          retryable: true,
        ),
      );
    }
    if (cancellationToken?.isCancelled ?? false) {
      return Future.error(
        const CopilotSdkException(
          code: CopilotSdkErrorCode.cancelled,
          message: 'Copilot SDK request was cancelled',
        ),
      );
    }

    final id = '${DateTime.now().microsecondsSinceEpoch}-${_nextRequestId++}';
    final completer = Completer<Object?>();
    final timer = Timer(timeout ?? requestTimeout, () {
      final pending = _pending.remove(id);
      if (pending == null) {
        return;
      }
      pending.completeError(
        const CopilotSdkException(
          code: CopilotSdkErrorCode.timeout,
          message: 'Copilot SDK request timed out',
          retryable: true,
        ),
      );
      unawaited(_sendCancellation(id));
    });
    _pending[id] = _PendingRequest(completer, timer);

    if (cancellationToken != null) {
      unawaited(
        cancellationToken.whenCancelled.then((_) {
          final pending = _pending.remove(id);
          if (pending == null) {
            return;
          }
          pending.completeError(
            const CopilotSdkException(
              code: CopilotSdkErrorCode.cancelled,
              message: 'Copilot SDK request was cancelled',
            ),
          );
          unawaited(_sendCancellation(id));
        }),
      );
    }

    final payload = jsonEncode({
      'protocolVersion': protocolVersion,
      'id': id,
      'method': method,
      'params': params,
    });
    unawaited(
      process.writeLine(payload).catchError((_) {
        final pending = _pending.remove(id);
        pending?.completeError(
          const CopilotSdkException(
            code: CopilotSdkErrorCode.processCrashed,
            message: 'Could not write to the Copilot SDK sidecar',
            retryable: true,
          ),
        );
      }),
    );
    return completer.future;
  }

  Future<void> _sendCancellation(String requestId) async {
    final process = _process;
    if (process == null || _shuttingDown) {
      return;
    }
    final id = 'cancel-${_nextRequestId++}';
    await process
        .writeLine(
          jsonEncode({
            'protocolVersion': protocolVersion,
            'id': id,
            'method': 'cancel',
            'params': {'requestId': requestId},
          }),
        )
        .catchError((_) {});
  }

  void _handleStdout(String line) {
    Object? decoded;
    try {
      decoded = jsonDecode(line);
    } on FormatException {
      _handleProtocolFailure();
      return;
    }
    if (decoded is! Map<String, Object?> ||
        decoded['protocolVersion'] != protocolVersion ||
        decoded['id'] is! String) {
      _handleProtocolFailure();
      return;
    }
    final id = decoded['id']! as String;
    final pending = _pending.remove(id);
    if (pending == null) {
      return;
    }
    if (decoded.containsKey('error')) {
      pending.completeError(_mapBridgeError(decoded['error']));
      return;
    }
    if (!decoded.containsKey('result')) {
      pending.completeError(
        const CopilotSdkException(
          code: CopilotSdkErrorCode.malformedResponse,
          message: 'Copilot SDK bridge returned a malformed response',
        ),
      );
      return;
    }
    pending.complete(decoded['result']);
  }

  void _handleStderr(String line) {
    final redacted = _redact(line);
    if (redacted.isEmpty) {
      return;
    }
    _logger.warning(
      'sidecar stderr: $redacted',
      name: 'copilot_sdk_transport',
    );
  }

  void _handleProtocolFailure() {
    _failPending(
      const CopilotSdkException(
        code: CopilotSdkErrorCode.malformedResponse,
        message: 'Copilot SDK bridge returned malformed NDJSON',
      ),
    );
    _process?.kill();
  }

  Future<void> _handleExit(
    SidecarProcessConnection process,
    int exitCode,
  ) async {
    if (!identical(_process, process)) {
      return;
    }
    _process = null;
    _initialized = false;
    _failPending(
      CopilotSdkException(
        code: CopilotSdkErrorCode.processCrashed,
        message: 'Copilot SDK sidecar exited unexpectedly',
        retryable: _restartCount < maxRestarts,
      ),
    );
    if (_shuttingDown || _restartCount >= maxRestarts) {
      if (!_shuttingDown) {
        _restartExhausted = true;
      }
      await _cancelSubscriptions();
      return;
    }
    _restartCount += 1;
    _logger.warning(
      'sidecar crashed exit=$exitCode restart=$_restartCount/$maxRestarts',
      name: 'copilot_sdk_transport',
    );
    _restart = _restartAfterCrash();
    try {
      await _restart;
    } on CopilotSdkException catch (error) {
      _logger.error(
        'sidecar restart failed code=${error.code.name}',
        name: 'copilot_sdk_transport',
      );
    } finally {
      _restart = null;
    }
  }

  Future<void> _restartAfterCrash() async {
    await _cancelSubscriptions();
    await _start();
  }

  CopilotSdkException _mapBridgeError(Object? value) {
    if (value is! Map<String, Object?> || value['code'] is! String) {
      return const CopilotSdkException(
        code: CopilotSdkErrorCode.malformedResponse,
        message: 'Copilot SDK bridge returned a malformed error',
      );
    }
    final code = value['code']! as String;
    final retryable = value['retryable'] == true;
    return CopilotSdkException(
      code: switch (code) {
        'request_timeout' => CopilotSdkErrorCode.timeout,
        'unsupported_protocol' => CopilotSdkErrorCode.protocolMismatch,
        'authentication_failed' => CopilotSdkErrorCode.authenticationFailed,
        'authentication_expired' => CopilotSdkErrorCode.authenticationExpired,
        'session_not_found' => CopilotSdkErrorCode.sessionNotFound,
        'unsupported_capability' => CopilotSdkErrorCode.unsupportedCapability,
        'unsupported_sdk' => CopilotSdkErrorCode.unsupportedSdk,
        'rpc_unavailable' => CopilotSdkErrorCode.rpcUnavailable,
        'experimental_disabled' => CopilotSdkErrorCode.experimentalDisabled,
        'network_unavailable' => CopilotSdkErrorCode.networkUnavailable,
        'schema_changed' => CopilotSdkErrorCode.schemaChanged,
        'malformed_response' => CopilotSdkErrorCode.malformedResponse,
        _ => CopilotSdkErrorCode.operationFailed,
      },
      message: switch (code) {
        'authentication_failed' ||
        'authentication_expired' => 'Copilot authentication is required',
        'session_not_found' => 'Copilot session was not found',
        'unsupported_capability' =>
          'Copilot runtime does not support this operation',
        'unsupported_sdk' => 'Copilot SDK version is unsupported',
        'rpc_unavailable' => 'Copilot SDK RPC is unavailable',
        'experimental_disabled' =>
          'Copilot experimental usage capability is disabled',
        'network_unavailable' => 'Copilot network is unavailable',
        'schema_changed' => 'Copilot SDK response schema changed',
        _ => 'Copilot SDK operation failed',
      },
      retryable: retryable,
    );
  }

  Map<String, Object?> _expectMap(Object? value, String operation) {
    if (value is Map<String, Object?>) {
      return value;
    }
    throw CopilotSdkException(
      code: CopilotSdkErrorCode.malformedResponse,
      message: 'Copilot SDK $operation response was malformed',
    );
  }

  void _failPending(CopilotSdkException error) {
    final pending = _pending.values.toList(growable: false);
    _pending.clear();
    for (final request in pending) {
      request.completeError(error);
    }
  }

  Future<void> _cancelSubscriptions() async {
    await _stdoutSubscription?.cancel();
    await _stderrSubscription?.cancel();
    _stdoutSubscription = null;
    _stderrSubscription = null;
  }

  String _redact(String input) {
    var value = input
        .replaceAll(
          RegExp(
            r'\b(?:gh[opsu]_[A-Za-z0-9_]+|github_pat_[A-Za-z0-9_]+)\b',
          ),
          '[REDACTED]',
        )
        .replaceAll(
          RegExp(
            r'\b(?:token|authorization|credential|secret)\s*[:=]\s*\S+',
            caseSensitive: false,
          ),
          '[REDACTED]',
        );
    if (value.length > 512) {
      value = '${value.substring(0, 512)}…';
    }
    return value.trim();
  }
}

final class _PendingRequest {
  _PendingRequest(this.completer, this.timer);

  final Completer<Object?> completer;
  final Timer timer;

  void complete(Object? value) {
    timer.cancel();
    if (!completer.isCompleted) {
      completer.complete(value);
    }
  }

  void completeError(CopilotSdkException error) {
    timer.cancel();
    if (!completer.isCompleted) {
      completer.completeError(error);
    }
  }
}
