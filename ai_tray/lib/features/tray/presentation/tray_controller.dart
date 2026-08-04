import 'dart:async';
import 'dart:io';

import 'package:ai_tray/core/components/status_badge.dart';
import 'package:ai_tray/core/di/providers.dart';
import 'package:ai_tray/core/logging/app_logger.dart';
import 'package:ai_tray/core/logging/logging_providers.dart';
import 'package:ai_tray/core/notifications/notification_gateway.dart';
import 'package:ai_tray/features/providers/domain/ports/ai_provider.dart';
import 'package:ai_tray/features/settings/domain/models/app_settings.dart';
import 'package:ai_tray/features/tray/presentation/tray_icon_resolver.dart';
import 'package:ai_tray/features/tray/presentation/tray_menu_builder.dart';
import 'package:ai_tray/features/tray/presentation/tray_ring_icon_renderer.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_status.dart';
import 'package:ai_tray/features/usage/domain/repositories/usage_repository.dart';
import 'package:ai_tray/features/usage/presentation/usage_status.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

/// Initializes tray / window chrome for desktop shells.
Future<void> initializeDesktopShell(AppLogger logger) async {
  if (kIsWeb || !(Platform.isMacOS || Platform.isWindows)) {
    return;
  }

  await windowManager.ensureInitialized();
  const options = WindowOptions(
    size: Size(720, 640),
    minimumSize: Size(420, 480),
    center: true,
    // Keep Dock presence so double-clicking the .app is discoverable.
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );
  await windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.setPreventClose(true);
    // Visibility is finalized after the first Flutter frame (Release-safe).
  });

  try {
    await localNotifier.setup(
      appName: 'AI Tray',
      shortcutPolicy: ShortcutPolicy.requireCreate,
    );
  } on Exception catch (error) {
    logger.warning('local_notifier setup failed: $error', name: 'tray');
  }

  try {
    launchAtStartup.setup(
      appName: 'AI Tray',
      appPath: Platform.resolvedExecutable,
    );
  } on Exception catch (error) {
    logger.warning('launch_at_startup setup failed: $error', name: 'tray');
  }
}

/// Shows and focuses the main window (call after runApp / first frame).
Future<void> ensureDesktopWindowVisible(AppLogger logger) async {
  if (kIsWeb || !(Platform.isMacOS || Platform.isWindows)) {
    return;
  }
  try {
    await windowManager.show();
    await windowManager.focus();
  } on Exception catch (error) {
    logger.warning('show window failed: $error', name: 'tray');
  }
}

/// Menu bar / system tray controller.
final class TrayController with TrayListener, WindowListener {
  TrayController({
    required this.repository,
    required this.provider,
    required this.logger,
    required this.onOpenSettings,
    required this.notificationGateway,
  });

  final UsageRepository repository;
  final AIProvider provider;
  final AppLogger logger;
  final VoidCallback onOpenSettings;
  final NotificationGateway notificationGateway;

  bool _started = false;
  String? _lastIconPath;

  Future<void> start() async {
    if (_started || kIsWeb) return;
    if (!(Platform.isMacOS || Platform.isWindows)) return;
    _started = true;

    trayManager.addListener(this);
    windowManager.addListener(this);

    await _rebuildMenu(repository.status);
    repository.watchStatus().listen((status) {
      unawaited(_rebuildMenu(status));
      unawaited(maybeNotify(status));
    });
  }

  /// Renders and applies the color-coded status ring (PD-021 revived):
  /// healthy/high-usage/near-limit/exhausted bands for live or cached
  /// usage, plus dedicated refreshing/offline/waiting states. Falls back
  /// to the monochrome template glyph if rendering fails for any reason.
  Future<void> _applyIcon({
    required TrayStatusKind kind,
    required double? sessionPercent,
  }) async {
    try {
      final path = await TrayRingIconRenderer.render(
        kind: kind,
        sessionPercent: sessionPercent,
      );
      if (path != _lastIconPath) {
        await trayManager.setIcon(path, isTemplate: false);
        _lastIconPath = path;
      }
    } on Exception catch (error) {
      logger.warning('tray icon render failed: $error', name: 'tray');
      await _applyFallbackIcon();
    }
  }

  Future<void> _applyFallbackIcon() async {
    try {
      final path = Platform.isMacOS
          ? TrayIconResolver.macOsMenuBarTemplate
          : TrayIconResolver.windowsAsset;
      if (path != _lastIconPath) {
        await trayManager.setIcon(path, isTemplate: Platform.isMacOS);
        _lastIconPath = path;
      }
    } on Exception catch (error) {
      logger.warning('tray icon fallback failed: $error', name: 'tray');
    }
  }

  Future<void> _rebuildMenu(RefreshStatus status) async {
    final settings = await repository.getSettings();
    final kind = UsageStatusMapper.kind(status);
    final sessionPercent = status.lastResult?.usage?.sessionUsedPercent;
    await _applyIcon(kind: kind, sessionPercent: sessionPercent);

    final iconTitle = Platform.isMacOS
        ? TrayIconResolver.macOsTitle(
            mode: settings.trayDisplayMode,
            threshold: settings.trayPercentThreshold,
            kind: kind,
            sessionPercent: sessionPercent,
          )
        : '';

    final snapshot = TrayMenuBuilder.fromStatus(
      status,
      providerDisplayName: provider.displayName,
      providerSourceLabel: provider.sourceLabel,
      iconTitle: iconTitle,
    );
    await trayManager.setContextMenu(snapshot.buildMenu());
    await trayManager.setToolTip(snapshot.toolTip);
    if (Platform.isMacOS) {
      try {
        await trayManager.setTitle(iconTitle);
      } on Exception catch (error) {
        logger.warning('tray title failed: $error', name: 'tray');
      }
    }
  }

  @override
  void onTrayIconMouseDown() {
    unawaited(trayManager.popUpContextMenu());
  }

  @override
  void onTrayIconRightMouseDown() {
    unawaited(trayManager.popUpContextMenu());
  }

  @override
  Future<void> onTrayMenuItemClick(MenuItem menuItem) async {
    switch (menuItem.key) {
      case 'open':
        await windowManager.show();
        await windowManager.focus();
      case 'refresh':
        await repository.refresh(manual: true);
      case 'settings':
        await windowManager.show();
        await windowManager.focus();
        onOpenSettings();
      case 'quit':
        await trayManager.destroy();
        exit(0);
    }
  }

  @override
  void onWindowClose() {
    unawaited(windowManager.hide());
  }

  Future<void> applyLaunchAtLogin(AppSettings settings) async {
    try {
      if (settings.launchAtLogin) {
        await launchAtStartup.enable();
      } else {
        await launchAtStartup.disable();
      }
    } on MissingPluginException catch (error) {
      logger.warning(
        'launchAtLogin unavailable (rebuild macOS runner): $error',
        name: 'tray',
      );
    } on PlatformException catch (error) {
      logger.warning(
        'launchAtLogin update failed: ${error.code} ${error.message}',
        name: 'tray',
      );
    } on Exception catch (error) {
      logger.warning('launchAtLogin update failed: $error', name: 'tray');
    }
  }

  /// Re-applies menu / title after settings change (density mode, threshold).
  Future<void> applyPresentationSettings() async {
    if (!_started) return;
    await _rebuildMenu(repository.status);
  }

  Future<void> maybeNotify(RefreshStatus status) async {
    final settings = await repository.getSettings();
    if (!settings.notificationsEnabled) return;
    final threshold = settings.notifyAtSessionPercent;
    final usage = status.lastResult?.usage;
    if (threshold == null || usage == null || usage.isFromCache) return;
    if (usage.sessionUsedPercent < threshold) return;

    await notificationGateway.notify(
      title: 'AI Tray',
      body: 'Session usage at ${usage.sessionUsedPercent.toStringAsFixed(0)}%',
    );
  }
}

class SettingsOpenRequest extends Notifier<int> {
  @override
  int build() => 0;

  void open() => state++;
}

final NotifierProvider<SettingsOpenRequest, int> settingsOpenRequestProvider =
    NotifierProvider<SettingsOpenRequest, int>(SettingsOpenRequest.new);

final trayControllerProvider = Provider<TrayController>((ref) {
  return TrayController(
    repository: ref.watch(usageRepositoryProvider),
    provider: ref.watch(selectedAIProviderProvider),
    logger: ref.watch(appLoggerProvider),
    notificationGateway: ref.watch(notificationGatewayProvider),
    onOpenSettings: () {
      ref.read(settingsOpenRequestProvider.notifier).open();
    },
  );
});
