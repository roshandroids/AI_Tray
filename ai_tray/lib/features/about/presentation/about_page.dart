import 'dart:async';
import 'dart:io';

import 'package:ai_tray/core/components/section_chrome.dart';
import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:ai_tray/core/theme/typography.dart';
import 'package:ai_tray/features/diagnostics/presentation/diagnostics_page.dart';
import 'package:ai_tray/features/settings/domain/models/release_history.dart';
import 'package:ai_tray/features/settings/release_history_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

const _repositoryUrl = 'https://github.com/roshandroids/AI_Tray';
const _issuesUrl = '$_repositoryUrl/issues';

/// About / product page (V3 redesign) — a dedicated destination instead
/// of one more accordion-less Settings section: hero, live version/build,
/// a rendered (not raw-markdown) changelog, external links, system
/// information, and a way into Diagnostics for support.
final class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packageInfo = ref.watch(packageInfoProvider);
    final history = ref.watch(releaseHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Spacing.contentMaxWidth),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Hero(),
                const SizedBox(height: Spacing.md),
                _VersionCard(packageInfo: packageInfo, history: history),
                const SizedBox(height: Spacing.md),
                const _LinksCard(),
                const SizedBox(height: Spacing.md),
                _ChangelogCard(packageInfo: packageInfo, history: history),
                const SizedBox(height: Spacing.md),
                const _SystemInfoCard(),
                const SizedBox(height: Spacing.md),
                const _SupportCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceAlt,
            shape: BoxShape.circle,
            border: Border.all(color: colors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 40,
              color: colors.success,
            ),
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Text('AI Tray', style: context.typography.display),
        const SizedBox(height: Spacing.xs),
        Text(
          'Terminal-inspired desktop companion for AI coding providers.',
          style: context.typography.caption,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

final class _VersionCard extends StatelessWidget {
  const _VersionCard({required this.packageInfo, required this.history});

  final AsyncValue<PackageInfo> packageInfo;
  final AsyncValue<ReleaseHistory> history;

  @override
  Widget build(BuildContext context) {
    final info = packageInfo.value;
    final releaseHistory = history.value;
    final version = info?.version;
    final current = version == null
        ? null
        : releaseHistory?.entryForVersion(version);

    return SectionCard.divided(
      title: 'Version',
      children: [
        if (packageInfo.isLoading && info == null)
          const InfoRow(label: 'Version', value: '…')
        else if (packageInfo.hasError && info == null)
          const InfoRow(label: 'Version', value: 'unavailable')
        else ...[
          InfoRow(label: 'Version', value: version ?? '—'),
          InfoRow(label: 'Build', value: info?.buildNumber ?? '—'),
          InfoRow(label: 'Released', value: current?.date ?? '—'),
          const InfoRow(
            label: 'Mode',
            value: kReleaseMode ? 'Release' : 'Debug',
          ),
        ],
      ],
    );
  }
}

final class _LinksCard extends StatelessWidget {
  const _LinksCard();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Links',
      child: Wrap(
        spacing: Spacing.sm,
        runSpacing: Spacing.sm,
        children: [
          OutlinedButton.icon(
            onPressed: () => unawaited(_openUrl(context, _repositoryUrl)),
            icon: const Icon(Icons.code_rounded, size: 16),
            label: const Text('View on GitHub'),
          ),
          OutlinedButton.icon(
            onPressed: () => unawaited(_openUrl(context, _issuesUrl)),
            icon: const Icon(Icons.bug_report_outlined, size: 16),
            label: const Text('Report an issue'),
          ),
        ],
      ),
    );
  }
}

final class _SystemInfoCard extends StatelessWidget {
  const _SystemInfoCard();

  @override
  Widget build(BuildContext context) {
    return SectionCard.divided(
      title: 'System',
      children: [
        InfoRow(label: 'Platform', value: _platformLabel()),
        InfoRow(label: 'OS version', value: Platform.operatingSystemVersion),
      ],
    );
  }

  static String _platformLabel() {
    if (kIsWeb) return 'web';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isLinux) return 'Linux';
    return Platform.operatingSystem;
  }
}

final class _SupportCard extends StatelessWidget {
  const _SupportCard();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Support',
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Diagnostics can help narrow down a problem before you '
              'report it.',
              style: context.typography.caption,
            ),
          ),
          const SizedBox(width: Spacing.sm),
          OutlinedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const DiagnosticsPage()),
            ),
            child: const Text('Open Diagnostics'),
          ),
        ],
      ),
    );
  }
}

final class _ChangelogCard extends StatelessWidget {
  const _ChangelogCard({required this.packageInfo, required this.history});

  final AsyncValue<PackageInfo> packageInfo;
  final AsyncValue<ReleaseHistory> history;

  @override
  Widget build(BuildContext context) {
    final version = packageInfo.value?.version;
    final releaseHistory = history.value;
    final current = version == null
        ? null
        : releaseHistory?.entryForVersion(version);
    final previous = version == null || releaseHistory == null
        ? const <ReleaseEntry>[]
        : releaseHistory.previousReleases(currentVersion: version);

    return SectionCard(
      title: 'What’s New',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (history.isLoading && releaseHistory == null)
            Text(
              'Loading release notes…',
              style: context.typography.caption,
            )
          else if (history.hasError && releaseHistory == null)
            Text(
              'Release notes could not be loaded.',
              style: context.typography.caption.copyWith(
                color: context.colors.error,
              ),
            )
          else if (current == null || current.notesMarkdown.trim().isEmpty)
            Text(
              'No notes for this build yet.',
              style: context.typography.caption,
            )
          else
            ChangelogView(markdown: current.notesMarkdown),
          if (previous.isNotEmpty) ...[
            const SizedBox(height: Spacing.md),
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: Text(
                  'Previous releases',
                  style: context.typography.section,
                ),
                children: [
                  for (final entry in previous) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${entry.version} — ${entry.date}',
                        style: context.typography.monoData,
                      ),
                    ),
                    const SizedBox(height: Spacing.xs),
                    ChangelogView(markdown: entry.notesMarkdown),
                    const SizedBox(height: Spacing.md),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Renders "Keep a Changelog"-style markdown (`### Heading` / `- bullet`
/// lines) as formatted text instead of a raw monospace dump.
final class ChangelogView extends StatelessWidget {
  const ChangelogView({required this.markdown, super.key});

  final String markdown;

  @override
  Widget build(BuildContext context) {
    final type = context.typography;
    final lines = markdown.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final rawLine in lines)
          if (rawLine.trim().isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                top: rawLine.trimLeft().startsWith('#') ? Spacing.sm : 2,
              ),
              child: _changelogLine(rawLine, type),
            ),
      ],
    );
  }

  Widget _changelogLine(String rawLine, TrayTypography type) {
    final line = rawLine.trimLeft();
    if (line.startsWith('#')) {
      final text = line.replaceFirst(RegExp(r'^#+\s*'), '');
      return Text(
        text,
        style: type.label.copyWith(fontWeight: FontWeight.w700),
      );
    }
    if (line.startsWith('-') || line.startsWith('*')) {
      final text = line.replaceFirst(RegExp(r'^[-*]\s*'), '');
      return Padding(
        padding: const EdgeInsets.only(left: Spacing.sm),
        child: Text('•  $text', style: type.body),
      );
    }
    return Text(line, style: type.body);
  }
}

Future<void> _openUrl(BuildContext context, String url) async {
  try {
    final command = Platform.isMacOS
        ? ('open', <String>[url])
        : Platform.isWindows
        ? ('cmd', <String>['/c', 'start', '', url])
        : ('xdg-open', <String>[url]);
    final result = await Process.run(
      command.$1,
      command.$2,
    ).timeout(const Duration(seconds: 5));
    if (result.exitCode != 0) {
      throw StateError('link could not be opened');
    }
  } on Object catch (_) {
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Could not open the link. Copied: $url')),
        );
    }
  }
}
