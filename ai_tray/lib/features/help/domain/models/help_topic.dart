import 'package:meta/meta.dart';

/// One static Help Center entry (V4 §9.2) — content authored from the
/// app's own existing copy/tooltips, not new documentation.
@immutable
final class HelpTopic {
  const HelpTopic({
    required this.title,
    required this.body,
    this.keywords = const [],
  });

  final String title;
  final String body;

  /// Extra search terms beyond [title]/[body] — e.g. a topic titled
  /// "Queue" also matches "unattended" or "budget cap".
  final List<String> keywords;

  bool matches(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return title.toLowerCase().contains(q) ||
        body.toLowerCase().contains(q) ||
        keywords.any((k) => k.toLowerCase().contains(q));
  }
}

/// Static Help Center content — grounded in what the app actually does
/// today, not aspirational copy.
const List<HelpTopic> helpTopics = [
  HelpTopic(
    title: 'Queue',
    body:
        'Queue a task to run later, unattended, as a separate copy of a '
        "session — it never touches the session you're actively using. "
        'Tasks run one at a time and nothing executes until you press '
        '"Run next"; queuing a task never starts it on its own. Cancelled '
        'and finished tasks move to the History section below the active '
        'list.',
    keywords: ['unattended', 'resume', 'run next', 'history', 'cancel'],
  ),
  HelpTopic(
    title: 'Budget cap',
    body:
        'Every queued task requires a budget cap in USD. The task stops '
        'itself once its cost reaches that cap, even mid-response — '
        "there's no 'run without a cap' path.",
    keywords: ['cost', 'spend', 'limit'],
  ),
  HelpTopic(
    title: 'Providers',
    body:
        'AI Tray tracks usage for Claude and GitHub Copilot. Switch the '
        'active provider anytime from the dropdown in the header — the '
        'tray icon and dashboard reflect whichever provider is selected.',
    keywords: ['claude', 'copilot', 'switch'],
  ),
  HelpTopic(
    title: 'Diagnostics',
    body:
        'Diagnostics shows connection, auth, and CLI health for your '
        'providers. When a check fails, a repair action — retry, force '
        'refresh — appears next to it.',
    keywords: ['health', 'repair', 'cli', 'auth'],
  ),
  HelpTopic(
    title: 'Notifications',
    body:
        'AI Tray notifies you when usage crosses a threshold you set, and '
        'when a queued task finishes. Every notification the app has '
        'shown is recorded under Settings → Notifications → View '
        'notification history.',
    keywords: ['alert', 'threshold', 'history'],
  ),
  HelpTopic(
    title: 'Sessions',
    body:
        'The Sessions page lists past Claude Code sessions grouped by '
        'project, most recently active first. Open a session to continue '
        'the conversation or queue a follow-up task from it.',
    keywords: ['browser', 'project', 'continue'],
  ),
];
