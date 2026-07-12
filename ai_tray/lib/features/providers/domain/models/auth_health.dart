import 'package:meta/meta.dart';

/// Claude auth probe snapshot (optional MVP support type).
@immutable
final class AuthHealth {
  const AuthHealth({
    required this.loggedIn,
    required this.checkedAt,
    this.subscriptionType,
  });

  final bool loggedIn;
  final String? subscriptionType;
  final DateTime checkedAt;

  AuthHealth copyWith({
    bool? loggedIn,
    String? subscriptionType,
    DateTime? checkedAt,
  }) {
    return AuthHealth(
      loggedIn: loggedIn ?? this.loggedIn,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      checkedAt: checkedAt ?? this.checkedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AuthHealth &&
        other.loggedIn == loggedIn &&
        other.subscriptionType == subscriptionType &&
        other.checkedAt == checkedAt;
  }

  @override
  int get hashCode => Object.hash(loggedIn, subscriptionType, checkedAt);
}
