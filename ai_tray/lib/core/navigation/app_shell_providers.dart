import 'package:ai_tray/core/navigation/app_destination.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The currently selected top-level shell destination.
///
/// Shared by the app shell's nav rail and the command palette, so either
/// can drive navigation through a single source of truth.
final class AppShellDestinationNotifier extends Notifier<AppDestination> {
  @override
  AppDestination build() => AppDestination.dashboard;

  // ignore: use_setters_to_change_properties - reads better as a method call.
  void select(AppDestination destination) => state = destination;
}

final appShellDestinationProvider =
    NotifierProvider<AppShellDestinationNotifier, AppDestination>(
      AppShellDestinationNotifier.new,
    );
