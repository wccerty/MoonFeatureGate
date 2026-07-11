# MoonFeatureGate

MoonFeatureGate is a MoonBit-native feature flag and gradual rollout toolkit.
It evaluates flags locally, explains why a value was chosen, and keeps the
core runtime independent from a hosted control plane.

This repository is prepared for the 2026 MoonBit open-source ecosystem
competition. The project focuses on reusable engineering infrastructure:
targeting rules, stable percentage rollout, typed flag values, CLI validation,
examples, tests, and a clear path toward OpenFeature-style providers.

## Project Summary

MoonFeatureGate provides a compact local runtime for feature management in
MoonBit projects. It is useful for libraries, demos, WASM applications, and
small services that need auditable rollout decisions without depending on a
remote feature-flag platform.

Core capabilities in `0.1.0`:

- typed flag values for bool, string, int, and double values
- local evaluation for bool, string, int, double, and generic FlagValue types
- Trait-decoupled `FeatureProvider` interface for custom providers
- JSON configuration parsing & JSON provider
- local evaluation with default, disabled, static, rollout, and target match explanations
- deterministic 0..9999 rollout buckets over `flag_key:targeting_key`
- a compact text configuration DSL
- a runnable CLI demo & iteration benchmark
- black-box and white-box MoonBit tests
- CI verification for formatting, checks, tests, and demo execution

## Quick Start

Run the verification set from the repository root:

```powershell
moon fmt --check
moon check --deny-warn
moon info
moon test --deny-warn
moon run cmd/moonfeaturegate
```

Expected demo output:

```text
========================================
MoonFeatureGate Premium CLI Demo
========================================
[JSON Config Loaded successfully]

1. Boolean Flag (enable_new_ui):
   Value:  true
   Reason: rollout_match

2. String Flag (theme_color):
   Value:  ocean-blue
   Reason: static

3. Integer Flag (max_connections):
   Value:  128
   Reason: target_match

========================================
Performance Benchmark Status
========================================
Completed 100000 iterations of multi-type evaluation successfully.
========================================
```

## Core API

```mbt
test {
  let provider = @moonfeaturegate.empty_provider().with_bool_rollout(
    "new_checkout",
    true,
    percentage=2500,
  )
  let ctx = @moonfeaturegate.context("user-42").with_attr(
    "plan",
    @moonfeaturegate.string_value("beta"),
  )
  let detail = @moonfeaturegate.evaluate_bool(
    provider,
    "new_checkout",
    ctx,
    default=false,
  )
  inspect(detail.flag_key, content="new_checkout")
}
```

## Configuration DSL

Each non-empty line defines one flag. Lines starting with `#` are comments.

```text
flag new_checkout bool true rollout 2500
flag beta_banner bool true target plan beta
```

Supported `0.1.0` forms:

- `flag <key> bool <true|false>`
- `flag <key> bool <true|false> rollout <0..10000>`
- `flag <key> bool <true|false> target <attribute> <string-value>`

## Repository Layout

- `MoonFeatureGate.mbt`, `provider.mbt`, `rollout.mbt`, `parser.mbt`:
  core library implementation
- `*_test.mbt`: library test coverage
- `cmd/moonfeaturegate`: runnable CLI demo
- `examples/flags.mfg`: sample configuration file
- `docs/design.md`: design notes and extension direction
- `docs/acceptance-checklist.md`: competition closeout checklist
- `docs/closeout.md`: final submission notes

## Competition Notes

- This is an original MoonBit project, not a direct port of a single upstream
  library.
- The design is informed by mature feature-flag systems and the
  vendor-neutral OpenFeature idea, while the first release intentionally keeps
  a compact local API.
- The repository is public, licensed under Apache-2.0, and prepared for
  Mooncakes publication.
- Planned extensions include JSON/TOML providers, an OpenFeature-like provider
  boundary, metrics hooks, remote config polling, and a small web preview.

## Links

- GitHub: <https://github.com/wccerty/MoonFeatureGate>
- GitLink: <https://gitlink.org.cn/Wccerty/MoonFeatureGate>
- Mooncakes: <https://mooncakes.io/docs/wccerty/moonfeaturegate>

## 中文简介

MoonFeatureGate 是一个 MoonBit 原生的特性开关与灰度发布工具库。它支持本地规则评估、用户定向、
稳定百分比分桶、命中原因解释和 CLI 校验，适合用于 MoonBit 项目的功能灰度、实验开关和配置策略管理。

项目面向 MoonBit 开源生态建设，重点补齐工程基础设施方向中的“可测试、可审查、可复用”的本地特性管理能力。
