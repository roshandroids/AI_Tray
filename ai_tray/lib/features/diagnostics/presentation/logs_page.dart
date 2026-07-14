import 'dart:async';
import 'dart:io';

import 'package:ai_tray/core/components/log_chip.dart';
import 'package:ai_tray/core/components/section_chrome.dart';
import 'package:ai_tray/core/logging/buffered_app_logger.dart';
import 'package:ai_tray/core/logging/log_entry.dart';
import 'package:ai_tray/core/logging/log_level.dart';
import 'package:ai_tray/core/logging/logging_providers.dart';
import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Design-system log viewer (PD-021).
final class LogsPage extends ConsumerStatefulWidget {
  const LogsPage({super.key});

  @override
  ConsumerState<LogsPage> createState() => _LogsPageState();
}

final class _LogsPageState extends ConsumerState<LogsPage> {
  final _search = TextEditingController();
  LogLevel? _filter;
  StreamSubscription<List<LogEntry>>? _sub;
  List<LogEntry> _entries = const [];

  @override
  void initState() {
    super.initState();
    final logger = ref.read(bufferedAppLoggerProvider);
    _entries = logger.entries;
    _sub = logger.watch.listen((entries) {
      if (mounted) setState(() => _entries = entries);
    });
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel() ?? Future<void>.value());
    _search.dispose();
    super.dispose();
  }

  List<LogEntry> get _filtered {
    final q = _search.text.trim().toLowerCase();
    return _entries.reversed.where((e) {
      if (_filter != null && e.level != _filter) return false;
      if (q.isEmpty) return true;
      return e.toPlainLine().toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final logger = ref.watch(bufferedAppLoggerProvider);
    final rows = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs'),
        actions: [
          IconButton(
            tooltip: 'Copy',
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await Clipboard.setData(
                ClipboardData(text: logger.exportPlainText()),
              );
              messenger.showSnackBar(
                const SnackBar(content: Text('Logs copied')),
              );
            },
            icon: const Icon(Icons.copy_outlined),
          ),
          IconButton(
            tooltip: 'Clear',
            onPressed: () => setState(logger.clear),
            icon: const Icon(Icons.delete_outline),
          ),
          IconButton(
            tooltip: 'Export',
            onPressed: () => unawaited(_export(logger)),
            icon: const Icon(Icons.download_outlined),
          ),
          IconButton(
            tooltip: 'Open folder',
            onPressed: () => unawaited(_openFolder()),
            icon: const Icon(Icons.folder_open_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.md,
              Spacing.sm,
              Spacing.md,
              Spacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    style: context.typography.body,
                    decoration: const InputDecoration(
                      hintText: 'Search logs…',
                      prefixIcon: Icon(Icons.search, size: 16),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
            child: Row(
              children: [
                _Chip(
                  label: 'ALL',
                  selected: _filter == null,
                  onTap: () => setState(() => _filter = null),
                ),
                for (final level in LogLevel.values)
                  _Chip(
                    label: level.label,
                    selected: _filter == level,
                    onTap: () => setState(() => _filter = level),
                  ),
              ],
            ),
          ),
          const SectionDivider(),
          Expanded(
            child: rows.isEmpty
                ? Center(
                    child: Text(
                      'No log entries yet.',
                      style: context.typography.caption,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                    itemCount: rows.length,
                    itemBuilder: (context, index) {
                      final entry = rows[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: Spacing.sm),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 64,
                              child: Text(
                                entry.formattedTime,
                                style: context.typography.caption,
                              ),
                            ),
                            LogChip(level: entry.level),
                            const SizedBox(width: Spacing.sm),
                            SizedBox(
                              width: 110,
                              child: Text(
                                entry.component ?? 'ai_tray',
                                style: context.typography.label,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              child: SelectableText(
                                entry.message +
                                    (entry.recoveryHint == null
                                        ? ''
                                        : '\n→ ${entry.recoveryHint}'),
                                style: context.typography.terminalOutput,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(Spacing.sm),
            child: Text(
              '${rows.length} shown · ${logger.entries.length} buffered',
              style: context.typography.caption,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _export(BufferedAppLogger logger) async {
    try {
      final file = File(
        '${Directory.systemTemp.path}/ai-tray-logs-'
        '${DateTime.now().millisecondsSinceEpoch}.txt',
      );
      await file.writeAsString(logger.exportPlainText());
      await Clipboard.setData(ClipboardData(text: file.path));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported → ${file.path}')),
        );
      }
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $error')),
        );
      }
    }
  }

  Future<void> _openFolder() async {
    final dir = Directory.systemTemp.path;
    await Clipboard.setData(ClipboardData(text: dir));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Temp folder path copied: $dir')),
      );
    }
  }
}

final class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: Spacing.xs),
      child: FilterChip(
        label: Text(label, style: context.typography.caption),
        selected: selected,
        onSelected: (_) => onTap(),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
