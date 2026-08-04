import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One request to open a session's detail page, tagged with a revision so
/// requesting the *same* session id twice in a row still counts as a
/// distinct event for `ref.listen` (which only fires on a value change).
typedef SessionDetailOpenRequestState = ({int revision, String sessionId})?;

/// Requests that the app navigate to a session's detail page — the same
/// "request notifier + `ref.listen` at the root page" shape
/// `SettingsOpenRequest`/`settingsOpenRequestProvider` already use
/// (`features/tray/presentation/tray_controller.dart`) for
/// `TrayController`'s settings-menu-item click.
///
/// Exists so a click on a queue-completion notification (Feature 2.3.1) —
/// which fires from outside any widget's `BuildContext` — can still
/// navigate to the right page: the notification's `onClick` closure calls
/// [open], and the root page's `ref.listen` reacts by pushing
/// `SessionDetailPage`.
final class SessionDetailOpenRequest
    extends Notifier<SessionDetailOpenRequestState> {
  @override
  SessionDetailOpenRequestState build() => null;

  int _revision = 0;

  void open(String sessionId) {
    _revision++;
    state = (revision: _revision, sessionId: sessionId);
  }
}

final NotifierProvider<SessionDetailOpenRequest, SessionDetailOpenRequestState>
sessionDetailOpenRequestProvider =
    NotifierProvider<SessionDetailOpenRequest, SessionDetailOpenRequestState>(
      SessionDetailOpenRequest.new,
    );
