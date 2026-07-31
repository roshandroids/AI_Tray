import 'package:ai_tray/features/settings/domain/models/release_history.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const fixture = '''
{
  "schemaVersion": 1,
  "generatedFrom": "CHANGELOG.md",
  "releases": [
    {
      "version": "1.3.3",
      "date": "2026-07-17",
      "notesMarkdown": "### Fixed\\n- Parser optional suffix."
    },
    {
      "version": "1.3.2",
      "date": "2026-07-17",
      "notesMarkdown": "### Fixed\\n- Sidecar payload."
    },
    {
      "version": "1.2.0",
      "date": "2026-07-13",
      "notesMarkdown": "### Added\\n- Design system."
    }
  ]
}
''';

  test('parses fixture and maps notes by version', () {
    final history = ReleaseHistory.parse(fixture);

    expect(history.schemaVersion, 1);
    expect(history.generatedFrom, 'CHANGELOG.md');
    expect(history.releases, hasLength(3));

    final current = history.entryForVersion('1.3.3');
    expect(current, isNotNull);
    expect(current!.date, '2026-07-17');
    expect(current.notesMarkdown, contains('Parser optional suffix'));

    expect(history.entryForVersion('9.9.9'), isNull);
  });

  test('previousReleases excludes current and respects limit', () {
    final history = ReleaseHistory.parse(fixture);

    final previous = history.previousReleases(
      currentVersion: '1.3.3',
      limit: 1,
    );
    expect(previous, hasLength(1));
    expect(previous.single.version, '1.3.2');

    final allOthers = history.previousReleases(currentVersion: '1.3.3');
    expect(allOthers.map((e) => e.version), ['1.3.2', '1.2.0']);
  });
}
