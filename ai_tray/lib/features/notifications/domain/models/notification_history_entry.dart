import 'package:meta/meta.dart';

/// One notification the app has shown, recorded for the Notifications
/// page (V4 §9.4) — a plain record of what was already sent, not a
/// second delivery mechanism.
@immutable
final class NotificationHistoryEntry {
  const NotificationHistoryEntry({
    required this.title,
    required this.body,
    required this.sentAt,
  });

  final String title;
  final String body;
  final DateTime sentAt;

  Map<String, Object?> toJson() {
    return {
      'title': title,
      'body': body,
      'sentAt': sentAt.toIso8601String(),
    };
  }

  /// Tolerant deserialization (design principle 4) — returns `null`
  /// rather than throwing on a malformed or missing field.
  static NotificationHistoryEntry? tryFromJson(Map<String, Object?> json) {
    final title = json['title'];
    final body = json['body'];
    final sentAtRaw = json['sentAt'];
    if (title is! String || body is! String || sentAtRaw is! String) {
      return null;
    }
    final sentAt = DateTime.tryParse(sentAtRaw);
    if (sentAt == null) return null;
    return NotificationHistoryEntry(title: title, body: body, sentAt: sentAt);
  }

  @override
  bool operator ==(Object other) {
    return other is NotificationHistoryEntry &&
        other.title == title &&
        other.body == body &&
        other.sentAt == sentAt;
  }

  @override
  int get hashCode => Object.hash(title, body, sentAt);

  @override
  String toString() =>
      'NotificationHistoryEntry(title: $title, sentAt: $sentAt)';
}
