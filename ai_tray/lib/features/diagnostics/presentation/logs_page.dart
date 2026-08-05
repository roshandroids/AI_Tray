import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ai_tray/core/components/log_chip.dart';
import 'package:ai_tray/core/components/page_header.dart';
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

/// Professional log explorer (V3 redesign): search, level + dynamic
/// provider filters, optional grouping by provider, expandable rows with
/// a metadata drawer (full timestamp, error, stack trace, recovery
/// hint), and plain-text/JSON export — built on `BufferedAppLogger`'s
/// existing broadcast stream (PD-020), no new data plumbing needed.
final class LogsPage extends ConsumerStatefulWidget {
  const LogsPage({super.key});

  @override
  ConsumerState<LogsPage> createState() => _LogsPageState();
}

final class _LogsPageState extends ConsumerState<LogsPage> {
  final _search = TextEditingController();
  LogLevel? _filter;
  String? _providerFilter;
  bool _groupByProvider = false;
  final Set<String> _expandedKeys = {};
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

  String _rowKey(LogEntry e) =>
      '${e.timestamp.microsecondsSinceEpoch}-${e.message.hashCode}';

  List<LogEntry> get _filtered {
    final q = _search.text.trim().toLowerCase();
    return _entries.reversed.where((e) {
      if (_filter != null && e.level != _filter) return false;
      if (_providerFilter != null && e.provider != _providerFilter) {
        return false;
      }
      if (q.isEmpty) return true;
      return e.toPlainLine().toLowerCase().contains(q);
    }).toList();
  }

  List<String> get _availableProviders {
    final providers =
        _entries.map((e) => e.provider).whereType<String>().toSet().toList()
          ..sort();
    return providers;
  }

  @override
  Widget build(BuildContext context) {
    final logger = ref.watch(bufferedAppLoggerProvider);
    final rows = _filtered;
    final providers = _availableProviders;

    return Scaffold(
      body: Column(
        children: [
          PageHeader(
            title: 'Logs',
            actions: [
              IconButton(
                tooltip: _groupByProvider ? 'Ungroup' : 'Group by provider',
                onPressed: () =>
                    setState(() => _groupByProvider = !_groupByProvider),
                icon: Icon(
                  _groupByProvider
                      ? Icons.view_list_outlined
                      : Icons.layers_outlined,
                ),
              ),
              IconButton(
                tooltip: 'Copy',
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await Clipboard.setData(
                    ClipboardData(text: logger.exportPlainText()),
                  );
                  if (!mounted) return;
                  messenger
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(content: Text('Logs copied')),
                    );
                },
                icon: const Icon(Icons.copy_outlined),
              ),
              PopupMenuButton<_ExportFormat>(
                tooltip: 'Export',
                icon: const Icon(Icons.download_outlined),
                onSelected: (format) => unawaited(_export(logger, format)),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _ExportFormat.plainText,
                    child: Text('Export as .txt'),
                  ),
                  PopupMenuItem(
                    value: _ExportFormat.json,
                    child: Text('Export as .json'),
                  ),
                ],
              ),
              IconButton(
                tooltip: 'Clear',
                onPressed: logger.entries.isEmpty
                    ? null
                    : () {
                        logger.clear();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            const SnackBar(content: Text('Logs cleared')),
                          );
                      },
                icon: const Icon(Icons.delete_outline),
              ),
              IconButton(
                tooltip: 'Reveal export folder',
                onPressed: () => unawaited(_reveal(Directory.systemTemp.path)),
                icon: const Icon(Icons.folder_open_outlined),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.md,
              Spacing.sm,
              Spacing.md,
              Spacing.sm,
            ),
            child: Semantics(
              textField: true,
              label: 'Search logs',
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
          const SizedBox(height: Spacing.xs),
          if (providers.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
              child: Row(
                children: [
                  _Chip(
                    label: 'ALL PROVIDERS',
                    selected: _providerFilter == null,
                    onTap: () => setState(() => _providerFilter = null),
                  ),
                  for (final provider in providers)
                    _Chip(
                      label: provider.toUpperCase(),
                      selected: _providerFilter == provider,
                      onTap: () => setState(() => _providerFilter = provider),
                    ),
                ],
              ),
            ),
          const SectionDivider(),
          Expanded(
            child: rows.isEmpty
                ? Semantics(
                    container: true,
                    label: _entries.isEmpty
                        ? 'No log entries yet. Run a refresh or diagnostics '
                              'check to generate logs.'
                        : 'No logs match these filters. Clear the search or '
                              'choose All Providers.',
                    child: Center(
                      child: Text(
                        _entries.isEmpty
                            ? 'No log entries yet. Run a refresh or '
                                  'diagnostics check to generate logs.'
                            : 'No logs match these filters. Clear the '
                                  'search or choose All Providers.',
                        key: ValueKey(
                          _entries.isEmpty ? 'logs-empty' : 'logs-no-match',
                        ),
                        style: context.typography.caption,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : _groupByProvider
                ? _GroupedLogList(
                    rows: rows,
                    expandedKeys: _expandedKeys,
                    rowKey: _rowKey,
                    onToggle: (key) => setState(() {
                      if (!_expandedKeys.remove(key)) _expandedKeys.add(key);
                    }),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                    itemCount: rows.length,
                    itemBuilder: (context, index) {
                      final entry = rows[index];
                      final key = _rowKey(entry);
                      return _LogRow(
                        entry: entry,
                        expanded: _expandedKeys.contains(key),
                        onToggle: () => setState(() {
                          if (!_expandedKeys.remove(key)) {
                            _expandedKeys.add(key);
                          }
                        }),
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

  Future<void> _export(BufferedAppLogger logger, _ExportFormat format) async {
    if (logger.entries.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('No logs to export')));
      return;
    }
    try {
      final extension = format == _ExportFormat.json ? 'json' : 'txt';
      final content = format == _ExportFormat.json
          ? _toJson(logger.entries)
          : logger.exportPlainText();
      final file = File(
        '${Directory.systemTemp.path}/ai-tray-logs-'
        '${DateTime.now().millisecondsSinceEpoch}.$extension',
      );
      await file.writeAsString(content);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Exported → ${file.path}'),
            action: SnackBarAction(
              label: 'Reveal',
              onPressed: () => unawaited(_reveal(file.parent.path)),
            ),
          ),
        );
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text('Export failed: $error')),
          );
      }
    }
  }

  String _toJson(List<LogEntry> entries) {
    return jsonEncode([
      for (final e in entries)
        {
          'timestamp': e.timestamp.toIso8601String(),
          'level': e.level.name,
          'message': e.message,
          if (e.component != null) 'component': e.component,
          if (e.provider != null) 'provider': e.provider,
          if (e.category != null) 'category': e.category,
          if (e.recoveryHint != null) 'recoveryHint': e.recoveryHint,
          if (e.error != null) 'error': e.error.toString(),
          if (e.stackTrace != null) 'stackTrace': e.stackTrace.toString(),
        },
    ]);
  }

  Future<void> _reveal(String dir) async {
    try {
      if (Platform.isMacOS) {
        await Process.run('open', [dir]);
      } else if (Platform.isWindows) {
        await Process.run('explorer', [dir]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [dir]);
      } else {
        throw const OSError('unsupported platform');
      }
    } on Object {
      await Clipboard.setData(ClipboardData(text: dir));
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text("Couldn't open the folder — path copied: $dir"),
            ),
          );
      }
    }
  }
}

enum _ExportFormat { plainText, json }

final class _GroupedLogList extends StatelessWidget {
  const _GroupedLogList({
    required this.rows,
    required this.expandedKeys,
    required this.rowKey,
    required this.onToggle,
  });

  final List<LogEntry> rows;
  final Set<String> expandedKeys;
  final String Function(LogEntry) rowKey;
  final ValueChanged<String> onToggle;

  /// Above this many entries, a group's rows render inside a bounded,
  /// virtualized `ListView.builder` instead of directly as
  /// `ExpansionTile.children` — `ExpansionTile` mounts every child
  /// eagerly (just height-animates them), so a single busy provider could
  /// otherwise build hundreds of `_LogRow`s at once (§7.1).
  static const _virtualizeThreshold = 30;
  static const _virtualizedHeight = 320.0;

  @override
  Widget build(BuildContext context) {
    final byProvider = <String, List<LogEntry>>{};
    for (final entry in rows) {
      (byProvider[entry.provider ?? 'ai_tray'] ??= []).add(entry);
    }
    final groupKeys = byProvider.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      itemCount: groupKeys.length,
      itemBuilder: (context, index) {
        final key = groupKeys[index];
        final entries = byProvider[key]!;
        _LogRow rowBuilder(LogEntry entry) => _LogRow(
          entry: entry,
          expanded: expandedKeys.contains(rowKey(entry)),
          onToggle: () => onToggle(rowKey(entry)),
        );
        return Padding(
          padding: const EdgeInsets.only(bottom: Spacing.sm),
          child: SectionCard(
            padding: EdgeInsets.zero,
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: true,
                title: Text(
                  '${key.toUpperCase()} · ${entries.length}',
                  style: context.typography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                childrenPadding: const EdgeInsets.only(bottom: Spacing.sm),
                children: entries.length > _virtualizeThreshold
                    ? [
                        SizedBox(
                          height: _virtualizedHeight,
                          child: ListView.builder(
                            itemCount: entries.length,
                            itemBuilder: (context, i) => rowBuilder(entries[i]),
                          ),
                        ),
                      ]
                    : [for (final entry in entries) rowBuilder(entry)],
              ),
            ),
          ),
        );
      },
    );
  }
}

final class _LogRow extends StatelessWidget {
  const _LogRow({
    required this.entry,
    required this.expanded,
    required this.onToggle,
  });

  final LogEntry entry;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final type = context.typography;
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  expanded ? Icons.expand_more : Icons.chevron_right,
                  size: 16,
                  color: context.colors.textMuted,
                ),
                SizedBox(
                  width: 64,
                  child: Text(entry.formattedTime, style: type.caption),
                ),
                LogChip(level: entry.level),
                const SizedBox(width: Spacing.sm),
                SizedBox(
                  width: 110,
                  child: Text(
                    [
                      entry.component ?? 'ai_tray',
                      if (entry.category != null) entry.category,
                    ].join(' · '),
                    style: type.label,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: Text(
                    entry.message,
                    style: type.terminalOutput,
                    maxLines: expanded ? null : 1,
                    overflow: expanded ? null : TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (expanded) ...[
              const SizedBox(height: Spacing.xs),
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: _MetadataDrawer(entry: entry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

final class _MetadataDrawer extends StatelessWidget {
  const _MetadataDrawer({required this.entry});

  final LogEntry entry;

  @override
  Widget build(BuildContext context) {
    final type = context.typography;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surfaceAlt,
        borderRadius: BorderRadius.circular(RadiusTokens.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InfoRow(
              label: 'Timestamp',
              value: entry.timestamp.toIso8601String(),
            ),
            if (entry.provider != null)
              InfoRow(label: 'Provider', value: entry.provider!),
            if (entry.category != null)
              InfoRow(label: 'Category', value: entry.category!),
            if (entry.recoveryHint != null)
              InfoRow(label: 'Suggested fix', value: entry.recoveryHint!),
            if (entry.error != null)
              InfoRow(
                label: 'Error',
                value: '${entry.error}',
                valueColor: context.colors.error,
              ),
            if (entry.stackTrace != null) ...[
              const SizedBox(height: Spacing.xs),
              SelectableText(
                '${entry.stackTrace}',
                style: type.terminalOutput.copyWith(fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
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
