import 'package:meta/meta.dart';

/// Declares the normalized features a provider can expose to shared UI.
///
/// Consumers:
/// - Dashboard mappers use these flags to create metric cards.
/// - Settings and diagnostics use them to hide unsupported controls.
@immutable
final class ProviderCapabilities {
  const ProviderCapabilities({
    required this.sessionUsage,
    required this.weeklyUsage,
    required this.healthCheck,
    required this.customExecutable,
  });

  /// Claude Code capabilities supported by the existing implementation.
  static const claude = ProviderCapabilities(
    sessionUsage: true,
    weeklyUsage: true,
    healthCheck: true,
    customExecutable: true,
  );

  /// Copilot capabilities remain disabled until its contracts are implemented.
  static const copilotPlaceholder = ProviderCapabilities(
    sessionUsage: false,
    weeklyUsage: false,
    healthCheck: false,
    customExecutable: false,
  );

  final bool sessionUsage;
  final bool weeklyUsage;
  final bool healthCheck;
  final bool customExecutable;

  @override
  bool operator ==(Object other) {
    return other is ProviderCapabilities &&
        other.sessionUsage == sessionUsage &&
        other.weeklyUsage == weeklyUsage &&
        other.healthCheck == healthCheck &&
        other.customExecutable == customExecutable;
  }

  @override
  int get hashCode => Object.hash(
    sessionUsage,
    weeklyUsage,
    healthCheck,
    customExecutable,
  );
}
