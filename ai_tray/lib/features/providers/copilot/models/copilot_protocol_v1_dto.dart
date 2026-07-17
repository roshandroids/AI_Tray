/// Transport-only protocol-v1 quota response.
final class CopilotQuotaResponseDto {
  const CopilotQuotaResponseDto({
    required this.premium,
    required this.chat,
    required this.completion,
  });

  /// Retains only allowlisted protocol fields.
  factory CopilotQuotaResponseDto.fromJson(Map<String, Object?> json) {
    return CopilotQuotaResponseDto(
      premium: json['premium'],
      chat: json['chat'],
      completion: json['completion'],
    );
  }

  final Object? premium;
  final Object? chat;
  final Object? completion;
}

/// Transport-only protocol-v1 session usage response.
final class CopilotSessionUsageDto {
  const CopilotSessionUsageDto(this.json);

  final Map<String, Object?> json;
}

/// Transport-only protocol-v1 health response.
final class CopilotHealthDto {
  const CopilotHealthDto(this.json);

  final Map<String, Object?> json;
}

/// Transport-only protocol-v1 compatibility response.
final class CopilotVersionDto {
  const CopilotVersionDto(this.json);

  final Map<String, Object?> json;
}
