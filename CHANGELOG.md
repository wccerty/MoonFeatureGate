# Changelog

## 0.1.3 - 2026-08-15

- Added typed release planning with risk classification, approval state,
  compatibility replay requirements, rollback steps, and operator guardrails.
- Added exposure analysis for typed requests and contexts, including fallback,
  targeting, rollout, consistency, threshold, and canary-quality reports.
- Updated CI executable-path checks and removed an unnecessary dependency update
  step so the standard MoonBit checks are more reproducible on all runners.
- Corrected README package syntax and synchronized acceptance documentation with
  the measured non-test MoonBit source.
- Expanded the executable acceptance suite to 53 tests.

## 0.1.2 - 2026-08-12

- Added immutable context helpers, batch evaluation, reason aggregation, and a
  privacy-friendly decision ledger for service and WASM integrations.
- Added provider merge/remove/select tools, deterministic fingerprints, DSL
  export and round-trip parsing, diff/compatibility reports, inventories, and
  health/deployment preflight checks.
- Extended the DSL to bool, string, int, and double values, including explicit
  `disabled` flags and production-shaped configuration examples.
- Added 12 deterministic benchmark scenarios plus a four-context acceptance
  matrix covering release gates, experiments, capacity, regional policy,
  safety, caching, search, mobile, workers, observability, media, and
  maintenance use cases.
- Expanded the test suite to 45 passing tests and raised non-test MoonBit source
  size above 3,000 lines in the 0.1.2 baseline.

## 0.1.1 - 2026-08-07

- Fixed MoonBit 0.10.3-compatible empty-map syntax with explicit `Map([])`.
- Fixed the executable package declaration to use MoonBit 0.10.3-compatible
  `options("is-main": true)`.
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
