# OSC2026 Acceptance Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 MoonFeatureGate 的非测试 MoonBit 源码扩展到约 4k 行，并补齐发布治理、流量暴露分析、CI 可复现性、README 与验收文档，使项目更接近 OSC2026 最终验收标准。

**Architecture:** 在现有 Provider、audit、policy、compatibility 和 deployment API 之上增加两个职责清晰的纯函数模块：release planning 负责把健康检查、兼容性和审批信息组合为可审计的发布计划；exposure analysis 负责对一组真实请求上下文统计 flag 的命中、默认值、目标不匹配和灰度分布。所有新能力保持无网络、无全局状态，便于 CI 和服务端复用。

**Tech Stack:** MoonBit 0.10.3, moon check/test/info/fmt, GitHub Actions, Markdown/PDF documentation.

---

### Task 1: Add failing acceptance tests for release planning

**Files:**
- Create: `release_test.mbt`
- Modify: none

- [ ] **Step 1: Write tests for risk classification, approval, rollback and summary.**
- [ ] **Step 2: Run `moon test release_test.mbt` and confirm the missing API failure.**

### Task 2: Implement release planning and audit trail

**Files:**
- Create: `release.mbt`
- Modify: none

- [ ] **Step 1: Add typed release environment, risk, approval, change and plan records.**
- [ ] **Step 2: Add pure plan construction from health, policy and compatibility reports.**
- [ ] **Step 3: Add deterministic rendering, approval transitions and rollback recommendation.**
- [ ] **Step 4: Run focused and full tests.**

### Task 3: Add failing acceptance tests for exposure analysis

**Files:**
- Create: `exposure_test.mbt`
- Modify: none

- [ ] **Step 1: Write tests for empty samples, typed evaluations, target misses, rollout buckets and aggregation.**
- [ ] **Step 2: Run the focused test and confirm the missing API failure.**

### Task 4: Implement reusable exposure analysis

**Files:**
- Create: `exposure.mbt`
- Modify: none

- [ ] **Step 1: Add request sample, exposure row, distribution and report types.**
- [ ] **Step 2: Implement value-kind aware evaluation with stable default values.**
- [ ] **Step 3: Add rollout concentration, reason aggregation, anomaly detection and rendering.**
- [ ] **Step 4: Run tests and coverage.**

### Task 5: Correct CI and documentation discrepancies

**Files:**
- Modify: `.github/workflows/ci.yml`
- Modify: `README.md`
- Modify: `docs/acceptance-checklist.md`
- Modify: `docs/closeout.md`
- Modify: `CHANGELOG.md`

- [ ] **Step 1: Make CI pin/reveal the requested MoonBit 0.10.3 toolchain and use the official all-target checks.**
- [ ] **Step 2: Correct the executable package description from `pkgtype` to `options("is-main": true)`.**
- [ ] **Step 3: Update source-scale, release-planning, exposure-analysis and verification documentation.**

### Task 6: Final verification and publication handoff

**Files:**
- Modify: generated `pkg.generated.mbti` only if `moon info` changes it.

- [ ] **Step 1: Run `moon fmt`, `moon info`, strict checks, all available targets, CLI and coverage.**
- [ ] **Step 2: Verify clean worktree, source line count, commit identity and both remote refs.**
- [ ] **Step 3: Report any environment-only native limitation separately from project results.**

---

## Self-review

- The plan covers the four identified acceptance risks: failed CI, stale README syntax, inaccurate source-scale statements, and insufficient operationally meaningful scope.
- New code is split into two cohesive files and is tested before implementation.
- No new network dependency, generated filler, or unrelated refactor is planned.
