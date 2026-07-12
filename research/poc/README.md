# Claude CLI Usage PoC

Minimal prototype for Task 0001. Not part of the Flutter app.

## Run

```bash
python3 fetch_usage.py
python3 fetch_usage.py --raw
```

## Exit codes

| Code | Meaning |
|------|---------|
| 0 | Success; rate-limit fields parsed |
| 1 | Hard failure (process/JSON) |
| 2 | `claude` binary not found |
| 3 | Soft failure; CLI responded but rate-limit lines missing |

## Fixtures

- `sample_usage_text_with_rate_limits.txt` — complete Shape A
- `sample_usage_text_contribution_only.txt` — incomplete Shape B
- `timing_benchmark.json` — latency / zero-cost evidence
