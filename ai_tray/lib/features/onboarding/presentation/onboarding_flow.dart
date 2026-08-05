import 'dart:async';

import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:ai_tray/features/diagnostics/presentation/copilot_diagnostics_controller.dart';
import 'package:ai_tray/features/providers/domain/models/provider_id.dart';
import 'package:ai_tray/features/providers/presentation/provider_selection_controller.dart';
import 'package:ai_tray/features/settings/domain/models/app_settings.dart';
import 'package:ai_tray/features/settings/presentation/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// First-launch flow (V4 §9.1): welcome, pick a provider, confirm its CLI
/// works, a one-screen feature teaser, then finish. Shown once — gated on
/// [AppSettings.hasCompletedOnboarding] in `AiTrayApp` (`app.dart`), not on
/// anything this widget owns itself.
final class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

enum _Step { welcome, provider, cliCheck, tour, ready }

final class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  _Step _step = _Step.welcome;
  bool _finishing = false;
  String? _finishError;

  void _next() {
    final next = _Step.values[_step.index + 1];
    setState(() => _step = next);
  }

  void _back() {
    final previous = _Step.values[_step.index - 1];
    setState(() => _step = previous);
  }

  Future<void> _finish() async {
    setState(() {
      _finishing = true;
      _finishError = null;
    });
    final current =
        ref.read(settingsControllerProvider).value ?? AppSettings.defaults();
    final ok = await ref
        .read(settingsControllerProvider.notifier)
        .save(current.copyWith(hasCompletedOnboarding: true));
    if (!mounted) return;
    setState(() {
      _finishing = false;
      if (!ok) _finishError = "Couldn't save — please try again.";
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = switch (_step) {
      _Step.welcome => const _WelcomeStep(),
      _Step.provider => const _ProviderStep(),
      _Step.cliCheck => const _CliCheckStep(),
      _Step.tour => const _TourStep(),
      _Step.ready => const _ReadyStep(),
    };

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(Spacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Semantics(
                      container: true,
                      label:
                          'Step ${_step.index + 1} of ${_Step.values.length}',
                      child: content,
                    ),
                  ),
                  if (_finishError != null) ...[
                    Text(
                      _finishError!,
                      key: const ValueKey('onboarding-finish-error'),
                      style: context.typography.caption.copyWith(
                        color: context.colors.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: Spacing.sm),
                  ],
                  Row(
                    children: [
                      if (_step != _Step.welcome)
                        TextButton(
                          key: const ValueKey('onboarding-back'),
                          onPressed: _finishing ? null : _back,
                          child: const Text('Back'),
                        ),
                      const Spacer(),
                      if (_step == _Step.ready)
                        FilledButton(
                          key: const ValueKey('onboarding-finish'),
                          onPressed: _finishing
                              ? null
                              : () => unawaited(_finish()),
                          child: _finishing
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Get started'),
                        )
                      else
                        FilledButton(
                          key: const ValueKey('onboarding-next'),
                          onPressed: _next,
                          child: const Text('Next'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep();

  @override
  Widget build(BuildContext context) {
    final type = context.typography;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.auto_awesome, size: 48, color: context.colors.purpleAccent),
        const SizedBox(height: Spacing.lg),
        Text(
          'Welcome to AI Tray',
          style: type.title,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          'Track usage, manage sessions, and queue work for Claude and '
          'Copilot — all from your menu bar.',
          style: type.body,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

final class _ProviderStep extends ConsumerWidget {
  const _ProviderStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = context.typography;
    final providers = ref.watch(selectableAIProvidersProvider);
    final selected = ref.watch(selectedProviderIdProvider).value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Choose a provider', style: type.title),
        const SizedBox(height: Spacing.sm),
        Text(
          'You can switch this anytime from Settings.',
          style: type.caption,
        ),
        const SizedBox(height: Spacing.lg),
        for (final provider in providers)
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.sm),
            child: _ProviderOption(
              label: provider.displayName,
              selected: provider.providerId == selected,
              onTap: () => unawaited(
                ref
                    .read(selectedProviderIdProvider.notifier)
                    .select(provider.providerId),
              ),
            ),
          ),
      ],
    );
  }
}

final class _ProviderOption extends StatelessWidget {
  const _ProviderOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: selected ? colors.purpleAccent : colors.border,
          width: selected ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(RadiusTokens.md),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(RadiusTokens.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.sm,
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 18,
                  color: selected ? colors.purpleAccent : colors.textMuted,
                ),
                const SizedBox(width: Spacing.sm),
                Text(label, style: context.typography.body),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _CliCheckStep extends ConsumerWidget {
  const _CliCheckStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = context.typography;
    final selected = ref.watch(selectedAIProviderProvider);

    if (selected.providerId != ProviderId.copilot) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 40,
            color: context.colors.info,
          ),
          const SizedBox(height: Spacing.md),
          Text('Claude CLI works out of the box', style: type.title),
          const SizedBox(height: Spacing.sm),
          Text(
            "No extra setup needed — you're ready to go.",
            style: type.body,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    final diagnosticsAsync = ref.watch(copilotDiagnosticsProvider);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Checking the Copilot CLI', style: type.title),
        const SizedBox(height: Spacing.md),
        diagnosticsAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (_, stackTrace) => Text(
            "Couldn't check the Copilot CLI.",
            style: type.body,
            textAlign: TextAlign.center,
          ),
          data: (diagnostics) => Column(
            children: [
              Icon(
                diagnostics.available
                    ? Icons.check_circle_outline
                    : Icons.error_outline,
                size: 40,
                color: diagnostics.available
                    ? context.colors.info
                    : context.colors.error,
              ),
              const SizedBox(height: Spacing.md),
              Text(
                diagnostics.available
                    ? 'Copilot CLI is ready'
                    : diagnostics.healthStatus,
                style: type.body,
                textAlign: TextAlign.center,
              ),
              if (!diagnostics.available) ...[
                const SizedBox(height: Spacing.sm),
                TextButton(
                  onPressed: () => unawaited(
                    ref.read(copilotDiagnosticsProvider.notifier).retry(),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

final class _TourStep extends StatelessWidget {
  const _TourStep();

  static const List<(IconData, String, String)> _items = [
    (
      Icons.dashboard_outlined,
      'Dashboard',
      'Usage, health, and quick actions at a glance.',
    ),
    (
      Icons.folder_outlined,
      'Sessions',
      'Browse past sessions, grouped by project.',
    ),
    (
      Icons.pending_actions_outlined,
      'Queue',
      'Queue tasks to run unattended, one at a time.',
    ),
    (
      Icons.monitor_heart_outlined,
      'Diagnostics',
      'Check provider health and repair issues.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final type = context.typography;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('A quick tour', style: type.title),
        const SizedBox(height: Spacing.lg),
        for (final (icon, title, body) in _items)
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 22, color: context.colors.purpleAccent),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: type.body.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(body, style: type.caption),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

final class _ReadyStep extends StatelessWidget {
  const _ReadyStep();

  @override
  Widget build(BuildContext context) {
    final type = context.typography;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.rocket_launch_outlined,
          size: 48,
          color: context.colors.purpleAccent,
        ),
        const SizedBox(height: Spacing.lg),
        Text("You're all set", style: type.title, textAlign: TextAlign.center),
        const SizedBox(height: Spacing.sm),
        Text(
          'AI Tray lives in your menu bar from here on.',
          style: type.body,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
