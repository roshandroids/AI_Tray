import 'dart:convert';

/// Parsed Keep a Changelog history for in-app What’s New / previous releases.
///
/// Generated from root `CHANGELOG.md` into `assets/release_history.json`.
/// Never hand-edit the asset — re-run `scripts/release/sync_release_history.sh`.

/// One dated release section derived from `CHANGELOG.md`.
final class ReleaseEntry {
  const ReleaseEntry({
    required this.version,
    required this.date,
    required this.notesMarkdown,
  });

  factory ReleaseEntry.fromJson(Map<String, Object?> json) {
    return ReleaseEntry(
      version: json['version']! as String,
      date: json['date']! as String,
      notesMarkdown: json['notesMarkdown']! as String,
    );
  }

  /// SemVer name (e.g. `1.3.3` or `1.0.0-rc.1`), without build `+N`.
  final String version;

  /// ISO date `YYYY-MM-DD` from the changelog heading.
  final String date;

  /// Body markdown under that heading (Added / Fixed / Changed, etc.).
  final String notesMarkdown;
}

/// Root document for `assets/release_history.json` (generated; do not edit).
final class ReleaseHistory {
  const ReleaseHistory({
    required this.schemaVersion,
    required this.generatedFrom,
    required this.releases,
  });

  factory ReleaseHistory.fromJson(Map<String, Object?> json) {
    final raw = json['releases'];
    if (raw is! List) {
      throw const FormatException('release_history.json: missing releases');
    }
    return ReleaseHistory(
      schemaVersion: json['schemaVersion']! as int,
      generatedFrom: json['generatedFrom']! as String,
      releases: [
        for (final item in raw)
          ReleaseEntry.fromJson(Map<String, Object?>.from(item as Map)),
      ],
    );
  }

  /// Parse JSON text (unit tests / loaders).
  factory ReleaseHistory.parse(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException(
        'release_history.json: root must be an object',
      );
    }
    return ReleaseHistory.fromJson(Map<String, Object?>.from(decoded));
  }

  final int schemaVersion;
  final String generatedFrom;
  final List<ReleaseEntry> releases;

  static const assetPath = 'assets/release_history.json';

  /// Cap for Settings “Previous releases” list.
  static const previousReleasesLimit = 10;

  /// Notes for the binary’s version name (`PackageInfo.version`).
  ReleaseEntry? entryForVersion(String version) {
    for (final entry in releases) {
      if (entry.version == version) {
        return entry;
      }
    }
    return null;
  }

  /// Remaining releases after [currentVersion], newest first, capped.
  List<ReleaseEntry> previousReleases({
    required String currentVersion,
    int limit = previousReleasesLimit,
  }) {
    final others = [
      for (final entry in releases)
        if (entry.version != currentVersion) entry,
    ];
    if (others.length <= limit) {
      return others;
    }
    return others.sublist(0, limit);
  }
}
