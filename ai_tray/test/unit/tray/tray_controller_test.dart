import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/logging/console_app_logger.dart';
import 'package:ai_tray/core/notifications/fake_notification_gateway.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/providers/core/models/provider_models.dart';
import 'package:ai_tray/features/providers/core/ports/provider_ports.dart';
import 'package:ai_tray/features/providers/domain/models/provider_id.dart';
import 'package:ai_tray/features/settings/domain/models/app_settings.dart';
import 'package:ai_tray/features/tray/presentation/tray_controller.dart';
import 'package:ai_tray/features/usage/data/cache/usage_cache.dart';
import 'package:ai_tray/features/usage/data/parsers/usage_parser.dart';
import 'package:ai_tray/features/usage/domain/models/parser_state.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_outcome.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_phase.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_result.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_status.dart';
import 'package:ai_tray/features/usage/domain/models/usage_info.dart';
import 'package:ai_tray/features/usage/domain/models/usage_source.dart';
import 'package:ai_tray/features/usage/domain/repositories/usage_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TrayController controller({
    required AppSettings settings,
    required FakeNotificationGateway gateway,
  }) {
    return TrayController(
      repository: _FakeUsageRepository(settings),
      provider: const _FakeProvider(),
      logger: ConsoleAppLogger(defaultName: 'tray_controller_test'),
      notificationGateway: gateway,
      onOpenSettings: () {},
    );
  }

  RefreshStatus statusWithUsage(
    double sessionUsedPercent, {
    bool isFromCache = false,
  }) {
    return RefreshStatus(
      phase: RefreshPhase.idle,
      lastResult: RefreshResult(
        status: RefreshOutcome.success,
        parserState: ParserState.empty(),
        duration: Duration.zero,
        providerId: ProviderId.claude,
        usage: UsageInfo(
          sessionUsedPercent: sessionUsedPercent,
          fetchedAt: DateTime.utc(2026, 7, 31),
          source: UsageSource.oauth,
          isFromCache: isFromCache,
          providerId: ProviderId.claude,
        ),
      ),
    );
  }

  test('notifies via the gateway with the same title/body as before', () async {
    final gateway = FakeNotificationGateway();
    final tray = controller(
      settings: AppSettings.defaults().copyWith(
        notificationsEnabled: true,
        notifyAtSessionPercent: 80,
      ),
      gateway: gateway,
    );

    await tray.maybeNotify(statusWithUsage(90));

    expect(gateway.calls, hasLength(1));
    expect(gateway.calls.single.title, 'AI Tray');
    expect(gateway.calls.single.body, 'Session usage at 90%');
  });

  test('does not notify when usage is below the threshold', () async {
    final gateway = FakeNotificationGateway();
    final tray = controller(
      settings: AppSettings.defaults().copyWith(
        notificationsEnabled: true,
        notifyAtSessionPercent: 80,
      ),
      gateway: gateway,
    );

    await tray.maybeNotify(statusWithUsage(50));

    expect(gateway.calls, isEmpty);
  });

  test('does not notify when notifications are disabled', () async {
    final gateway = FakeNotificationGateway();
    final tray = controller(
      settings: AppSettings.defaults().copyWith(
        notificationsEnabled: false,
        notifyAtSessionPercent: 80,
      ),
      gateway: gateway,
    );

    await tray.maybeNotify(statusWithUsage(95));

    expect(gateway.calls, isEmpty);
  });

  test('does not notify for cached (stale) usage', () async {
    final gateway = FakeNotificationGateway();
    final tray = controller(
      settings: AppSettings.defaults().copyWith(
        notificationsEnabled: true,
        notifyAtSessionPercent: 80,
      ),
      gateway: gateway,
    );

    await tray.maybeNotify(statusWithUsage(95, isFromCache: true));

    expect(gateway.calls, isEmpty);
  });

  test('does not notify when no threshold is configured', () async {
    final gateway = FakeNotificationGateway();
    final tray = controller(
      settings: AppSettings.defaults().copyWith(
        notificationsEnabled: true,
      ),
      gateway: gateway,
    );

    await tray.maybeNotify(statusWithUsage(95));

    expect(gateway.calls, isEmpty);
  });
}

final class _FakeUsageRepository implements UsageRepository {
  _FakeUsageRepository(this._settings);

  final AppSettings _settings;

  @override
  RefreshStatus get status => RefreshStatus(phase: RefreshPhase.idle);

  @override
  Future<Result<UsageInfo?>> getCachedUsage() async {
    return const Result.success(null);
  }

  @override
  Future<AppSettings> getSettings() async => _settings;

  @override
  Future<RefreshResult> refresh({bool manual = false}) async {
    return RefreshResult(
      status: RefreshOutcome.failure,
      parserState: ParserState.empty(),
      duration: Duration.zero,
      error: const AppFailure(code: FailureCode.unknown, message: 'not used'),
      providerId: ProviderId.claude,
    );
  }

  @override
  Future<Result<Unit>> updateSettings(AppSettings settings) async {
    return const Result.success(Unit.unit);
  }

  @override
  Stream<RefreshStatus> watchStatus() => const Stream.empty();
}

final class _FakeProvider implements AIProvider {
  const _FakeProvider();

  @override
  ProviderId get providerId => ProviderId.claude;

  @override
  String get displayName => 'Claude';

  @override
  String get sourceLabel => 'Claude test';

  @override
  bool get enabled => true;

  @override
  ProviderCapabilities get capabilities => ProviderCapabilities.claude;

  @override
  ProviderUsageParser get parser => const UsageParser();

  @override
  String get limitsUnavailableMessage => 'Unavailable';

  @override
  Future<Result<UsageRawFetch>> fetchUsageRaw({
    ProviderExecutionConfig config = const ProviderExecutionConfig(),
  }) async {
    return const Result.failure(
      AppFailure(code: FailureCode.unknown, message: 'Not used'),
    );
  }

  @override
  Future<Result<AuthHealth>> healthCheck({
    ProviderExecutionConfig config = const ProviderExecutionConfig(),
  }) async {
    return const Result.failure(
      AppFailure(code: FailureCode.unknown, message: 'Not used'),
    );
  }
}
