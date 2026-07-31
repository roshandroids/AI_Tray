import 'package:ai_tray/features/sessions/data/fs/claude_project_path_decoder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClaudeProjectPathDecoder.decode', () {
    test('reverses the sanitized name when the candidate path exists', () {
      final decoded = ClaudeProjectPathDecoder.decode(
        '-home-claude-testproj',
        directoryExists: (path) => path == '/home/claude/testproj',
      );

      expect(decoded, '/home/claude/testproj');
    });

    test(
      'returns null (never guesses) when the candidate does not exist — '
      'e.g. the real path contained a literal dash',
      () {
        final decoded = ClaudeProjectPathDecoder.decode(
          '-home-claude-my-project',
          directoryExists: (path) => false,
        );

        expect(decoded, isNull);
      },
    );

    test('returns null for an empty sanitized name', () {
      expect(
        ClaudeProjectPathDecoder.decode(
          '',
          directoryExists: (_) => true,
        ),
        isNull,
      );
    });

    test(
      'returns null when the sanitized name does not start with the '
      'expected leading dash for an absolute path',
      () {
        expect(
          ClaudeProjectPathDecoder.decode(
            'not-sanitized-looking',
            directoryExists: (_) => true,
          ),
          isNull,
        );
      },
    );

    test('never calls directoryExists for input it can reject up front', () {
      var called = false;
      ClaudeProjectPathDecoder.decode(
        '',
        directoryExists: (_) {
          called = true;
          return true;
        },
      );

      expect(called, isFalse);
    });
  });
}
