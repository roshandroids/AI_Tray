/// Where a usage snapshot originated.
enum UsageSource {
  /// Installed Claude Code CLI (`claude -p /usage`).
  cli,

  /// Reserved for a future structured OAuth/API source.
  oauth,
}
