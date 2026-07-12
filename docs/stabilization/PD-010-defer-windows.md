# PD-010 — Defer Windows Validation

**Decision:** Product Owner Decision PD-010  
**Date:** 2026-07-12

## Ruling

Windows verification is **deferred** due to lack of a Windows build host. This is an **environmental** limitation, not an implementation defect.

## Platform status for v1.0.0 line

| Platform | Status |
|--|--|
| **macOS** | Officially validated platform for v1.0.0 |
| **Windows** | **Experimental** — scaffolded; not validated until S-001A |

## Deferred backlog

| ID | Item | Gate |
|--|--|--|
| **S-001A** | Windows Validation | Suitable Windows Flutter + VS build host available |

S-001A includes: Release build, startup, tray, notifications, launch-at-login, and an updated Windows validation report (superseding the blocked S-001 report).

## Phase 2 impact

S-001 is closed as **Deferred (PD-010)**. Stabilization continues from **S-002** on macOS.
