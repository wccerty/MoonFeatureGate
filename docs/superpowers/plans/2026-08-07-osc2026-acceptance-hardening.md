# OSC2026 Acceptance Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make MoonFeatureGate reproducibly installable, executable, testable, and ready for the OSC2026 re-acceptance review on MoonBit 0.10.3-era tooling.

**Architecture:** Keep the existing single public MoonBit package and CLI package. Harden the public contract through README and tested examples, add regression tests at parser/provider/evaluator boundaries, and keep GitHub Actions as the authoritative clean-check workflow mirrored to GitLink.

**Tech Stack:** MoonBit CLI, MoonBit core/json, GitHub Actions, GitLink mirror, Apache-2.0.

---

### Task 1: Restore current MoonBit package compatibility

**Files:**
- Modify: `moon.pkg`
- Test: `moon fmt --check`, `moon check --deny-warn`

- [ ] Replace the deprecated executable declaration with `pkgtype(kind: "executable")`.
- [ ] Run `moon fmt --check` and `moon check --deny-warn`; both must exit 0.

### Task 2: Add failing acceptance-regression tests

**Files:**
- Modify: `json_provider_test.mbt`
- Modify: `parser_test.mbt`
- Modify: `value_provider_test.mbt`
- Modify: `MoonFeatureGate_test.mbt`
- Modify: `targeting_test.mbt`

- [ ] Add tests for empty-map configuration, malformed JSON, wrong JSON value types, disabled flags, missing targeting attributes, rollout boundaries, and invalid DSL ranges.
- [ ] Run the focused tests and confirm each new assertion fails only where behavior is not yet implemented or documented.

### Task 3: Implement minimal behavior and documentation contract

**Files:**
- Modify: `json_provider.mbt`, `parser.mbt`, and the smallest affected evaluator/provider files.
- Modify: `README.md`, `README.mbt.md`, `CHANGELOG.md`.
- Modify: `docs/acceptance-checklist.md`, `docs/closeout.md`.
- Modify: `moon.mod` only if metadata needs synchronization.

- [ ] Preserve safe empty-map handling and return explicit errors for malformed or type-mismatched configuration.
- [ ] Align all user-visible version references to 0.1.1.
- [ ] Replace the garbled Chinese README/closeout content with UTF-8 text.
- [ ] Document exact Windows, macOS, and Linux installation paths, `moon add`/dependency restoration, executable invocation, sample configuration, expected output, and the MoonBit 0.10.3 compatibility note.
- [ ] Record the acceptance remediation in the 0.1.1 changelog.

### Task 4: Strengthen CI and local verification

**Files:**
- Modify: `.github/workflows/ci.yml`

- [ ] Keep Linux/macOS/Windows coverage, install MoonBit through the official installer, and run format, warning-denied check, info, regular tests, native tests, and coverage analysis.
- [ ] Ensure the workflow uses the current executable package syntax and does not rely on generated build artifacts.

### Task 5: Final verification and publication audit

**Files:**
- No source changes unless verification exposes a defect.

- [ ] Run `moon fmt`, `moon info`, `moon fmt --check`, `moon check --deny-warn`, `moon test --deny-warn`, native tests, coverage summary/analyze, and `moon run cmd/moonfeaturegate`.
- [ ] Check repository structure, license, README, changelog, public API interface files, commit authors, default branches, remote heads, and GitHub/GitLink parity.
- [ ] Commit with local author `Wccerty <3496197313@qq.com>` and push the same commit to GitHub `main` and GitLink `master`/`main` only after verification.
