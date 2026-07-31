/// Best-effort reversal of Claude Code's lossy `/` → `-` project-path
/// sanitization (confirmed for POSIX in
/// `docs/claude_code_cli_capability_report.md` §3B:
/// `/home/claude/testproj` → `-home-claude-testproj`).
///
/// The encoding is ambiguous whenever a real path segment itself contains a
/// literal `-`, so [decode] only returns a result when the straightforward
/// reversal resolves to a directory `directoryExists` confirms is real —
/// otherwise it returns `null` rather than guessing (design principle 3:
/// never invent data). Callers should fall back to showing the raw
/// sanitized name when this returns `null`; deliberately not attempted here:
/// a backtracking reconstruction that tries every `-`/segment-boundary
/// combination, which would add real complexity to correctly handle an edge
/// case this project has not observed causing problems in practice.
///
/// Windows-side sanitization was not observed in the capability report
/// (tested only in a Linux container), so this only attempts the confirmed
/// `/`-based reconstruction.
final class ClaudeProjectPathDecoder {
  const ClaudeProjectPathDecoder._();

  static String? decode(
    String sanitizedDirName, {
    required bool Function(String path) directoryExists,
  }) {
    if (sanitizedDirName.isEmpty || !sanitizedDirName.startsWith('-')) {
      return null;
    }
    final candidate = sanitizedDirName.replaceAll('-', '/');
    return directoryExists(candidate) ? candidate : null;
  }
}
