#!/usr/bin/env python3
"""
Task 0001 — Claude CLI Usage Proof of Concept

Minimal prototype only. Not part of the future Flutter application.
Validates that the installed Claude CLI can be launched, queried for
usage, and that stdout can be parsed into structured fields.
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
import time
from dataclasses import asdict, dataclass, field
from typing import Any


SESSION_RE = re.compile(
    r"Current session:\s*(\d+(?:\.\d+)?)%\s*used\s*[·\.]\s*resets\s+(.+)",
    re.IGNORECASE,
)
WEEK_RE = re.compile(
    r"Current week\s*\(([^)]+)\):\s*(\d+(?:\.\d+)?)%\s*used"
    r"(?:\s*[·\.]\s*resets\s+(.+))?",
    re.IGNORECASE,
)


@dataclass
class WeekUsage:
    label: str
    used_percent: float
    resets_at: str | None


@dataclass
class ParsedUsage:
    rate_limits_present: bool
    session_used_percent: float | None = None
    session_resets_at: str | None = None
    weeks: list[WeekUsage] = field(default_factory=list)
    subscription_powered: bool = False
    raw_text: str = ""


@dataclass
class FetchResult:
    ok: bool
    exit_code: int
    elapsed_ms: int
    command: list[str]
    stdout: str
    stderr: str
    envelope: dict[str, Any] | None
    parsed: ParsedUsage | None
    error: str | None = None


def find_claude(explicit: str | None) -> str:
    if explicit:
        return explicit
    path = shutil.which("claude")
    if not path:
        raise FileNotFoundError(
            "claude CLI not found on PATH. Install Claude Code and retry."
        )
    return path


def parse_usage_text(text: str) -> ParsedUsage:
    session = SESSION_RE.search(text)
    weeks = [
        WeekUsage(
            label=label.strip(),
            used_percent=float(pct),
            resets_at=(resets.strip() if resets else None),
        )
        for label, pct, resets in WEEK_RE.findall(text)
    ]
    return ParsedUsage(
        rate_limits_present=session is not None or bool(weeks),
        session_used_percent=float(session.group(1)) if session else None,
        session_resets_at=session.group(2).strip() if session else None,
        weeks=weeks,
        subscription_powered="subscription to power your Claude Code usage"
        in text,
        raw_text=text,
    )


def fetch_usage(
    claude_bin: str,
    *,
    output_format: str = "json",
    timeout_s: float = 30.0,
) -> FetchResult:
    command = [
        claude_bin,
        "-p",
        "/usage",
        "--output-format",
        output_format,
    ]
    started = time.perf_counter()
    try:
        completed = subprocess.run(
            command,
            stdin=subprocess.DEVNULL,
            capture_output=True,
            text=True,
            timeout=timeout_s,
            check=False,
        )
    except subprocess.TimeoutExpired as exc:
        elapsed_ms = int((time.perf_counter() - started) * 1000)
        return FetchResult(
            ok=False,
            exit_code=-1,
            elapsed_ms=elapsed_ms,
            command=command,
            stdout=(exc.stdout or "") if isinstance(exc.stdout, str) else "",
            stderr=(exc.stderr or "") if isinstance(exc.stderr, str) else "",
            envelope=None,
            parsed=None,
            error=f"timeout after {timeout_s}s",
        )

    elapsed_ms = int((time.perf_counter() - started) * 1000)
    stdout = completed.stdout or ""
    stderr = completed.stderr or ""
    envelope: dict[str, Any] | None = None
    text = stdout

    if output_format == "json":
        try:
            envelope = json.loads(stdout)
            text = str(envelope.get("result") or "")
        except json.JSONDecodeError as exc:
            return FetchResult(
                ok=False,
                exit_code=completed.returncode,
                elapsed_ms=elapsed_ms,
                command=command,
                stdout=stdout,
                stderr=stderr,
                envelope=None,
                parsed=None,
                error=f"invalid JSON envelope: {exc}",
            )

    parsed = parse_usage_text(text)
    ok = completed.returncode == 0 and bool(text.strip())
    return FetchResult(
        ok=ok,
        exit_code=completed.returncode,
        elapsed_ms=elapsed_ms,
        command=command,
        stdout=stdout,
        stderr=stderr,
        envelope=envelope,
        parsed=parsed,
        error=None if ok else "non-zero exit or empty usage text",
    )


def result_to_dict(result: FetchResult) -> dict[str, Any]:
    parsed = None
    if result.parsed is not None:
        parsed = asdict(result.parsed)
        parsed["weeks"] = [asdict(w) for w in result.parsed.weeks]

    envelope_summary = None
    if result.envelope is not None:
        envelope_summary = {
            "type": result.envelope.get("type"),
            "subtype": result.envelope.get("subtype"),
            "is_error": result.envelope.get("is_error"),
            "total_cost_usd": result.envelope.get("total_cost_usd"),
            "duration_ms": result.envelope.get("duration_ms"),
            "duration_api_ms": result.envelope.get("duration_api_ms"),
            "session_id": result.envelope.get("session_id"),
            "usage": result.envelope.get("usage"),
        }

    return {
        "ok": result.ok,
        "exit_code": result.exit_code,
        "elapsed_ms": result.elapsed_ms,
        "command": result.command,
        "error": result.error,
        "stderr": result.stderr,
        "envelope_summary": envelope_summary,
        "parsed": parsed,
    }


def main() -> int:
    parser = argparse.ArgumentParser(
        description="PoC: fetch and parse Claude CLI /usage output"
    )
    parser.add_argument(
        "--claude",
        default=None,
        help="Path to claude binary (default: resolve from PATH)",
    )
    parser.add_argument(
        "--format",
        choices=("json", "text"),
        default="json",
        help="CLI --output-format (default: json)",
    )
    parser.add_argument(
        "--timeout",
        type=float,
        default=30.0,
        help="Process timeout in seconds",
    )
    parser.add_argument(
        "--raw",
        action="store_true",
        help="Also print raw usage text to stderr",
    )
    args = parser.parse_args()

    try:
        claude_bin = find_claude(args.claude)
    except FileNotFoundError as exc:
        print(json.dumps({"ok": False, "error": str(exc)}, indent=2))
        return 2

    result = fetch_usage(
        claude_bin,
        output_format=args.format,
        timeout_s=args.timeout,
    )
    payload = result_to_dict(result)
    print(json.dumps(payload, indent=2))

    if args.raw and result.parsed is not None:
        print("\n--- raw usage text ---", file=sys.stderr)
        print(result.parsed.raw_text, file=sys.stderr)

    if not result.ok:
        return 1
    if result.parsed and not result.parsed.rate_limits_present:
        # Soft failure: CLI responded, but MVP-critical rate-limit lines missing.
        return 3
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
