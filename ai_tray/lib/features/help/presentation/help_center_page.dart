import 'package:ai_tray/core/components/empty_state.dart';
import 'package:ai_tray/core/components/section_chrome.dart';
import 'package:ai_tray/core/components/sliver_page_scaffold.dart';
import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:ai_tray/features/help/domain/models/help_topic.dart';
import 'package:flutter/material.dart';

/// Searchable static Help Center (V4 §9.2) — pushed from Settings, not a
/// shell destination (Section 2.3 rule: drill-downs stay pushed).
final class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

final class _HelpCenterPageState extends State<HelpCenterPage> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim();
    final matches = helpTopics.where((t) => t.matches(query)).toList();

    return SliverPageScaffold(
      title: 'Help Center',
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              0,
              Spacing.sm,
              0,
              Spacing.sm,
            ),
            child: Semantics(
              textField: true,
              label: 'Search help topics',
              child: TextField(
                key: const ValueKey('help-search-field'),
                controller: _search,
                style: context.typography.body,
                decoration: const InputDecoration(
                  hintText: 'Search help topics…',
                  prefixIcon: Icon(Icons.search, size: 16),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
        ),
        if (matches.isEmpty)
          const SliverFillRemaining(
            child: EmptyState(
              key: ValueKey('help-empty'),
              icon: Icons.search_off,
              title: 'No help topics match this search',
              body: 'Clear the search to see every topic.',
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.only(bottom: Spacing.md),
            sliver: SliverSemantics(
              container: true,
              label:
                  'Help topics, ${matches.length} '
                  '${matches.length == 1 ? 'result' : 'results'}',
              sliver: SliverList.builder(
                key: const ValueKey('help-list'),
                itemCount: matches.length,
                itemBuilder: (context, index) =>
                    _HelpTopicCard(topic: matches[index]),
              ),
            ),
          ),
      ],
    );
  }
}

final class _HelpTopicCard extends StatelessWidget {
  const _HelpTopicCard({required this.topic});

  final HelpTopic topic;

  @override
  Widget build(BuildContext context) {
    final type = context.typography;
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              topic.title,
              style: type.body.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: Spacing.xs),
            Text(topic.body, style: type.body),
          ],
        ),
      ),
    );
  }
}
