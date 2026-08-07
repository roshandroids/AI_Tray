import 'package:ai_tray/core/components/section_chrome.dart';
import 'package:ai_tray/core/components/status_badge.dart';
import 'package:ai_tray/core/components/tray_accordion.dart';
import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:flutter/material.dart';

/// One tappable session row (V4 §4.2) — shared by `SessionBrowserPage`'s
/// per-project session lists and the dashboard's "Recent Sessions" preview,
/// so the two never render a session's row differently.
final class SessionCard extends StatelessWidget {
  const SessionCard({
    required this.primaryText,
    required this.onTap,
    super.key,
    this.secondaryText,
    this.live = false,
  });

  final String primaryText;
  final String? secondaryText;
  final bool live;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type = context.typography;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                primaryText,
                style: type.body,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (secondaryText != null) ...[
              const SizedBox(width: Spacing.sm),
              Text(secondaryText!, style: type.caption),
            ],
            // A live badge appears only when the CLI's live registry
            // matched this session — absence is never shown as "not live".
            if (live) ...[
              const SizedBox(width: Spacing.sm),
              const StatusBadge(kind: TrayStatusKind.live, compact: true),
            ],
          ],
        ),
      ),
    );
  }
}

/// Bordered, expandable project group (V4 §4.2) — the chrome half of what
/// was `session_browser_page.dart`'s private `_ProjectGroupTile`; callers
/// supply [children] (typically [SessionCard] rows).
final class ProjectCard extends StatelessWidget {
  const ProjectCard({
    required this.title,
    required this.subtitle,
    required this.children,
    required this.isExpanded,
    required this.onExpandedChanged,
    super.key,
    this.hasLiveSession = false,
  });

  final String title;
  final String subtitle;
  final bool hasLiveSession;
  final bool isExpanded;
  final ValueChanged<bool> onExpandedChanged;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: SectionCard(
        padding: EdgeInsets.zero,
        child: TrayAccordion(
          title: title,
          subtitle: subtitle,
          isExpanded: isExpanded,
          onExpandedChanged: onExpandedChanged,
          trailing: hasLiveSession
              ? const StatusBadge(kind: TrayStatusKind.live, compact: true)
              : null,
          bodyBuilder: (context) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}
