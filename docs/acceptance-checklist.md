# OSC2026 Acceptance Checklist

## Reproducible local verification

Run from the repository root with MoonBit 0.10.3 or a newer stable toolchain:

```powershell
moon version
moon fmt --check
moon check --deny-warn
moon info
moon test --deny-warn
moon run cmd/moonfeaturegate
moon check --deny-warn --target wasm-gc
moon test --deny-warn --target wasm-gc
moon test --deny-warn --target native --enable-coverage
moon coverage report -f summary
moon coverage analyze
```

The strict checks must finish with zero warnings and zero failed tests. The CLI
must print the JSON-loaded demo, rollout/target reasons, and the 100000-iteration
benchmark line.

## Repository requirements

- GitHub: `https://github.com/wccerty/MoonFeatureGate`
- GitLink: `https://gitlink.org.cn/Wccerty/MoonFeatureGate`
- License: Apache-2.0, stored as a regular `LICENSE` file.
- README: regular UTF-8 file with installation, pinned `moon add
  wccerty/moonfeaturegate@0.1.3`, CLI, JSON, DSL and verification instructions.
- Public MoonBit API: generated `pkg.generated.mbti` is checked by `moon info`.
- History: existing public history has meaningful development commits; do not
  add empty or artificial split-only commits.
- CI: `.github/workflows/ci.yml` covers Linux, macOS and Windows.
- Scope: non-test MoonBit source is approximately 4,000 lines and is organized
  into evaluator, provider, parser, audit, policy, scenario, deployment,
  release-planning, and exposure-analysis layers.
- Operations: `release.mbt` produces a reviewable release/rollback plan;
  `exposure.mbt` produces typed exposure counters and release gates.

## Boundary coverage

- Empty `Map([])` provider/context and empty JSON `flags` object.
- Disabled flag returns caller default with `disabled` reason.
- Wrong typed evaluator returns caller default with `type_mismatch` reason.
- Missing target attribute and non-matching target return `target_miss`.
- Rollout values cover `0`, `10000`, and over-limit clamping.
- Malformed JSON and malformed DSL lines fail explicitly.
- Multi-type DSL round-trip preserves rollout, target, and disabled metadata.
- The deterministic benchmark contains 12 application-shaped scenarios; the
  acceptance matrix replays them across four contexts.
- Provider audit, production policy, compatibility diff, health check, and
  deployment decision are covered by executable tests.

## Publication metadata

- Module: `wccerty/moonfeaturegate`.
- Version: `0.1.3`, published as `wccerty/moonfeaturegate@0.1.3` on Mooncakes.
- Repository URL in `moon.mod` points to GitHub.
- GitHub and GitLink are synchronized from the same creator-authored commit.
- Mooncakes publication must use the authenticated `wccerty` account.
