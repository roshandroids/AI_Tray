import 'dart:async';
import 'dart:io';

import 'package:ai_tray/core/logging/buffered_app_logger.dart';
import 'package:ai_tray/core/logging/log_entry.dart';
import 'package:ai_tray/core/logging/log_level.dart';
import 'package:ai_tray/core/logging/logging_providers.dart';
import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:ai_tray/core/widgets/terminal_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-app ring-buffer log viewer (PD-020).
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
            tooltip: 'Copy all',
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
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.lg,
              Spacing.sm,
              Spacing.lg,
              Spacing.sm,
            ),
            child: Column(
              children: [
                TextField(
                  controller: _search,
                  style: context.typography.body,
                  decoration: const InputDecoration(
                    hintText: 'Search logs…',
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: Spacing.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _LevelChip(
                        label: 'ALL',
                        selected: _filter == null,
                        onTap: () => setState(() => _filter = null),
                      ),
                      for (final level in LogLevel.values)
                        _LevelChip(
                          label: level.label,
                          selected: _filter == level,
                          color: _colorFor(level, context),
                          onTap: () => setState(() => _filter = level),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const AsciiSeparator(length: 40),
          Expanded(
            child: rows.isEmpty
                ? Center(
                    child: Text(
                      'No log entries yet.',
                      style: context.typography.muted,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                    itemCount: rows.length,
                    itemBuilder: (context, index) {
                      final entry = rows[index];
                      return _LogLine(
                        entry: entry,
                        color: _colorFor(entry.level, context),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Text(
              '${rows.length} shown · ${logger.entries.length} buffered',
              style: context.typography.muted.copyWith(fontSize: 11),
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

  static Color _colorFor(LogLevel level, BuildContext context) {
    final c = context.colors;
    return switch (level) {
      LogLevel.debug => c.textMuted,
      LogLevel.info => c.textSecondary,
      LogLevel.warning => c.warning,
      LogLevel.error => c.error,
      LogLevel.success => c.success,
    };
  }
}

final class _LevelChip extends StatelessWidget {
  const _LevelChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: Spacing.xs),
      child: FilterChip(
        label: Text(label, style: context.typography.caption),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: (color ?? context.colors.primary).withValues(alpha: 0.2),
        checkmarkColor: color ?? context.colors.primary,
        side: BorderSide(color: context.colors.divider),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

final class _LogLine extends StatelessWidget {
  const _LogLine({required this.entry, required this.color});

  final LogEntry entry;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: SelectableText.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '${entry.formattedTime} ',
              style: context.typography.muted.copyWith(fontSize: 11),
            ),
            TextSpan(
              text: '${entry.level.label} ',
              style: context.typography.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (entry.component != null)
              TextSpan(
                text: '[${entry.component}] ',
                style: context.typography.muted.copyWith(fontSize: 11),
              ),
            TextSpan(
              text: entry.message,
              style: context.typography.body.copyWith(fontSize: 12),
            ),
            if (entry.recoveryHint != null)
              TextSpan(
                text: '\n  → ${entry.recoveryHint}',
                style: context.typography.caption.copyWith(
                  color: context.colors.warning,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
