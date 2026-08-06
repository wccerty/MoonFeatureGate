# Changelog

## 0.1.1 - 2026-08-07

- Fixed MoonBit 0.10.3-compatible empty-map syntax with explicit `Map([])`.
- Fixed the executable package declaration to use `pkgtype(kind: "executable")`.
- Made JSON provider schema validation explicit for malformed roots, field types,
  target pairs, and rollout percentage bounds.
- Added regression tests for disabled flags, type mismatches, malformed JSON,
  empty maps, invalid DSL lines, and rollout boundaries.
- Reworked README and acceptance documents with reproducible installation,
  `moon add`, CLI, and strict verification commands.
- Added cross-platform CI coverage for formatting, warning-denied checks, tests,
  native tests, and coverage analysis.

## 0.1.0 - 2026-07-05

- Added typed flag values for bool, string, int, and double.
- Added local bool evaluation with default, disabled, static, rollout, and
  target-match explanations.
- Added deterministic percentage buckets over `flag_key:targeting_key`.
- Added a compact text configuration parser.
- Added runnable CLI demo and MoonBit tests.
- Added CI, design notes, acceptance checklist, and closeout documentation for
  the MoonBit OSC2026 submission.
