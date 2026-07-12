# Flutter Folder Structure — MVP Proposal

**Phase:** Lightweight Planning · Task 0002  
**Principles:** Clean Architecture · Feature-first · Provider-extensible  
**Note:** Structure only. No source files are created in this phase.

---

## Proposed tree

```text
ai_tray/
├── pubspec.yaml
├── analysis_options.yaml
├── README.md
├── macos/                          # Flutter desktop (created at scaffold time)
├── windows/
├── test/
│   ├── fixtures/
│   │   └── claude_usage/           # Golden Shape A / Shape B text + JSON
│   ├── unit/
│   │   ├── parser/
│   │   ├── validator/
│   │   └── refresh/
│   └── widget/                     # Minimal later; not MVP planning focus
└── lib/
    ├── main.dart
    ├── app.dart
    ├── bootstrap.dart              # ProviderContainer overrides, logging init
    │
    ├── core/
    │   ├── constants/
    │   ├── errors/
    │   │   └── app_failure.dart
    │   ├── logging/
    │   ├── result/
    │   │   └── result.dart         # Optional shared Result/Either style
    │   └── utils/
    │       └── time_utils.dart
    │
    ├── shared/                     # Cross-feature UI primitives only when needed
    │   └── widgets/
    │
    └── features/
        ├── tray/
        │   ├── presentation/
        │   │   ├── tray_controller.dart
        │   │   └── tray_shell.dart
        │   └── ...
        │
        ├── usage/
        │   ├── domain/
        │   │   ├── models/
        │   │   │   ├── usage_info.dart
        │   │   │   ├── refresh_result.dart
        │   │   │   ├── parser_state.dart
        │   │   │   └── refresh_status.dart
        │   │   ├── repositories/
        │   │   │   └── usage_repository.dart      # abstract port
        │   │   └── providers/                     # Riverpod domain-facing
        │   │       └── usage_providers.dart
        │   ├── data/
        │   │   ├── dto/
        │   │   │   └── claude_usage_raw_dto.dart
        │   │   ├── parsers/
        │   │   │   └── usage_parser.dart
        │   │   ├── validators/
        │   │   │   └── usage_validator.dart
        │   │   ├── cache/
        │   │   │   └── usage_cache.dart
        │   │   ├── services/
        │   │   │   └── refresh_service.dart
        │   │   ├── repositories/
        │   │   │   └── usage_repository_impl.dart
        │   │   └── sources/
        │   │       └── claude_cli_usage_source.dart
        │   └── presentation/
        │       ├── usage_popup.dart
        │       └── usage_notifier.dart
        │
        ├── settings/
        │   ├── domain/
        │   │   ├── models/
        │   │   │   └── app_settings.dart
        │   │   └── repositories/
        │   │       └── settings_repository.dart
        │   ├── data/
        │   │   ├── repositories/
        │   │   │   └── settings_repository_impl.dart
        │   │   └── sources/
        │   │       └── settings_local_source.dart
        │   └── presentation/
        │       ├── settings_page.dart
        │       └── settings_notifier.dart
        │
        ├── notifications/
        │   ├── domain/
        │   ├── data/
        │   └── presentation/
        │
        └── providers/              # AI provider abstraction (platform core)
            ├── domain/
            │   ├── models/
            │   │   └── provider_id.dart
            │   └── ports/
            │       └── ai_provider_port.dart
            └── data/
                ├── process/
                │   └── process_runner.dart
                └── claude/
                    ├── claude_cli_adapter.dart
                    └── claude_auth_probe.dart
```

---

## Layer rules

| Layer | May depend on | Must not depend on |
|-------|---------------|--------------------|
| `presentation/` | domain models, Riverpod notifiers, shared widgets | CLI, DTOs, parsers, file/process APIs |
| `domain/` | nothing from data/presentation | Flutter platform channels, packages that do I/O (prefer pure Dart) |
| `data/` | domain ports/models | presentation widgets |

**DTO rule:** Raw CLI envelopes stay in `data/dto`. UI consumes domain models only.

---

## Feature boundaries

| Feature | Owns |
|---------|------|
| `usage` | Fetch orchestration, parse, validate, cache, usage popup state |
| `settings` | Preferences persistence and settings UI |
| `tray` | Menu bar / system tray lifecycle and entry actions |
| `notifications` | Local notification triggers based on usage thresholds |
| `providers` | `AiProviderPort`, Claude adapter, process runner |

Claude-specific process details live under `features/providers/data/claude/`, while usage feature depends on the port + repository — enabling future ChatGPT/Gemini adapters without rewriting usage UI.

---

## Test layout alignment

```text
test/fixtures/claude_usage/
  shape_a_with_rate_limits.txt
  shape_b_contribution_only.txt
  envelope_success.json
```

Parser and validator unit tests are mandatory before tray UI work, reflecting ADR-001 text-contract risk.

---

## Explicitly deferred directories

Not required for MVP scaffolding:

- `features/analytics/`
- `features/providers/data/chatgpt|gemini|cursor/`
- Multi-account / team admin modules

---

## Scaffolding note

This tree is a **target** for the Implementation phase. Lightweight Planning does **not** create `ai_tray/` or any Dart files.
