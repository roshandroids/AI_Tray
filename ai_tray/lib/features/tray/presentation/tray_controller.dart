import 'dart:async';
import 'dart:io';

import 'package:ai_tray/core/di/providers.dart';
import 'package:ai_tray/core/logging/app_logger.dart';
import 'package:ai_tray/core/logging/logging_providers.dart';
import 'package:ai_tray/features/settings/domain/models/app_settings.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_status.dart';
import 'package:ai_tray/features/usage/domain/repositories/usage_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
    size: Size(420, 560),
    center: true,
    skipTaskbar: true,
    titleBarStyle: TitleBarStyle.normal,
  );
  await windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.setPreventClose(true);
    await windowManager.hide();
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

/// Menu bar / system tray controller.
final class TrayController with TrayListener, WindowListener {
  TrayController({
    required this.repository,
    required this.logger,
    required this.onOpenSettings,
  });

  final UsageRepository repository;
  final AppLogger logger;
  final VoidCallback onOpenSettings;

  bool _started = false;

  Future<void> start() async {
    if (_started || kIsWeb) return;
    if (!(Platform.isMacOS || Platform.isWindows)) return;
    _started = true;

    trayManager.addListener(this);
    windowManager.addListener(this);

    try {
      // Bundled Flutter assets (required for packaged Release builds).
      if (Platform.isMacOS) {
        await trayManager.setIcon(
          'assets/tray/tray_icon_32.png',
          isTemplate: false,
        );
      } else if (Platform.isWindows) {
        await trayManager.setIcon('assets/tray/tray_icon.ico');
      }
    } on Exception catch (error) {
      logger.warning('tray icon failed: $error', name: 'tray');
    }

    await trayManager.setToolTip('AI Tray');
    await _rebuildMenu(repository.status);
    repository.watchStatus().listen((status) {
      unawaited(_rebuildMenu(status));
      unawaited(maybeNotify(status));
    });
  }

  Future<void> _rebuildMenu(RefreshStatus status) async {
    final usage = status.lastResult?.usage;
    final label = usage == null
        ? 'Usage unavailable'
        : 'Session ${usage.sessionUsedPercent.toStringAsFixed(0)}%'
            '${usage.isFromCache ? ' (cached)' : ''}';

    await trayManager.setContextMenu(
      Menu(
        items: [
          MenuItem(key: 'status', label: label, disabled: true),
          MenuItem.separator(),
          MenuItem(key: 'open', label: 'Open'),
          MenuItem(key: 'refresh', label: 'Refresh'),
          MenuItem(key: 'settings', label: 'Settings'),
          MenuItem.separator(),
          MenuItem(key: 'quit', label: 'Quit'),
        ],
      ),
    );
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
    } on Exception catch (error) {
      logger.warning('launchAtLogin update failed: $error', name: 'tray');
    }
  }

  Future<void> maybeNotify(RefreshStatus status) async {
    final settings = await repository.getSettings();
    if (!settings.notificationsEnabled) return;
    final threshold = settings.notifyAtSessionPercent;
    final usage = status.lastResult?.usage;
    if (threshold == null || usage == null || usage.isFromCache) return;
    if (usage.sessionUsedPercent < threshold) return;

    try {
      final notification = LocalNotification(
        title: 'AI Tray',
        body:
            'Session usage at ${usage.sessionUsedPercent.toStringAsFixed(0)}%',
      );
      await notification.show();
    } on Exception catch (error) {
      logger.warning('notification failed: $error', name: 'tray');
    }
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
    logger: ref.watch(appLoggerProvider),
    onOpenSettings: () {
      ref.read(settingsOpenRequestProvider.notifier).open();
    },
  );
});
