import 'package:ai_tray/features/help/domain/models/help_topic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HelpTopic.matches', () {
    const topic = HelpTopic(
      title: 'Queue',
      body: 'Tasks run one at a time in the background.',
      keywords: ['unattended'],
    );

    test('an empty query matches everything', () {
      expect(topic.matches(''), isTrue);
    });

    test('matches by title, case-insensitively', () {
      expect(topic.matches('QUEUE'), isTrue);
    });

    test('matches by body text', () {
      expect(topic.matches('background'), isTrue);
    });

    test('matches by keyword even when absent from title/body', () {
      expect(topic.matches('unattended'), isTrue);
    });

    test('does not match unrelated text', () {
      expect(topic.matches('diagnostics'), isFalse);
    });
  });

  test('every static help topic has non-empty title and body', () {
    for (final topic in helpTopics) {
      expect(topic.title, isNotEmpty);
      expect(topic.body, isNotEmpty);
    }
  });
}
