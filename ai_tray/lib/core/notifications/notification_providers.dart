import 'package:ai_tray/core/logging/logging_providers.dart';
import 'package:ai_tray/core/notifications/io_notification_gateway.dart';
import 'package:ai_tray/core/notifications/notification_gateway.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cross-cutting notification dependency, shared by the usage-threshold
/// notification today and, later, queue/scheduler notifications (Epic
/// 2.3/M3) — same DI shape as `processRunnerProvider`.
final notificationGatewayProvider = Provider<NotificationGateway>((ref) {
  return IoNotificationGateway(logger: ref.watch(appLoggerProvider));
});
