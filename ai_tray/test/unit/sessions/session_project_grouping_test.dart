import 'package:ai_tray/features/sessions/browser/presentation/session_project_grouping.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('truncatePath', () {
    test('returns the path unchanged when at or under maxLength', () {
      expect(truncatePath('/home/claude/proj', maxLength: 48), '/home/claude/proj');
    });

    test('elides from the front, keeping the trailing segment intact', () {
      const path = '/Users/roshanshrestha/Desktop/Projects/personal/AI_Tray_Project';
      final result = truncatePath(path, maxLength: 30);

      expect(result, startsWith('…'));
      expect(result, endsWith('AI_Tray_Project'));
      expect(result.length, 30);
    });
  });
}
