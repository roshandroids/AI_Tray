import 'dart:io';

/// PATH / executable helpers for GUI-launched desktop apps.
///
/// Finder / Dock launches inherit a minimal PATH (often without Homebrew),
/// so `claude` must be resolved explicitly.
///
/// Resolution only probes known CLI prefixes — never the full inherited
/// PATH — to avoid macOS TCC “Files and Folders” prompts from
/// `existsSync` on Desktop/Documents/Downloads entries.
final class DesktopProcessEnvironment {
  const DesktopProcessEnvironment._();

  /// Directories that commonly contain `claude` (Homebrew / usr local).
  static const knownCliPrefixes = <String>[
    '/opt/homebrew/bin',
    '/opt/homebrew/sbin',
    '/usr/local/bin',
    '/usr/local/sbin',
  ];

  /// Environment map with Homebrew-friendly PATH prepended when missing.
  static Map<String, String> enriched() {
    final env = Map<String, String>.from(Platform.environment);
    final current = env['PATH'] ?? '';
    final missing = <String>[
      for (final entry in knownCliPrefixes)
        if (!current.split(':').contains(entry)) entry,
    ];
    if (missing.isNotEmpty) {
      env['PATH'] = '${missing.join(':')}:$current';
    }
    return env;
  }

  /// Resolves [executable] to an absolute path when possible.
  ///
  /// Only checks [knownCliPrefixes] (and an absolute/custom path). Does not
  /// walk the full PATH with filesystem probes.
  static String resolveExecutable(String executable) {
    final trimmed = executable.trim();
    if (trimmed.isEmpty) return executable;
    if (trimmed.contains('/') || trimmed.contains('\\')) {
      return trimmed;
    }

    for (final dir in knownCliPrefixes) {
      final candidate = File('$dir/$trimmed');
      if (candidate.existsSync()) {
        return candidate.absolute.path;
      }
    }

    return trimmed;
  }
}
