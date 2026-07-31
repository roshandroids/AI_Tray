/// Testable notification boundary — mirrors `ProcessRunner`'s port+fake
/// shape (`features/providers/data/process/process_runner.dart`), per §12
/// of `docs/planning/v2-vision-and-roadmap.md`.
///
/// Cross-cutting infrastructure: used by the existing usage-threshold
/// notification (`TrayController.maybeNotify`) today and, later, by
/// queue-completion and scheduled-resume notifications (Epic 2.3, M3) —
/// not Sessions-specific, so it lives in `core/`, not `features/sessions/`
/// (§7 placement rule 2).
abstract interface class NotificationGateway {
  /// Shows a local OS notification. [onClick] is invoked if the user
  /// clicks it — the closure is created and consumed within the same
  /// running process, so no payload/data field is needed on the
  /// notification itself.
  Future<void> notify({
    required String title,
    required String body,
    void Function()? onClick,
  });
}
