# MoonFeatureGate

MoonFeatureGate 是一个 MoonBit 原生的功能开关与渐进式发布工具库。它在本地完成类型安全的旗标评估、用户定向、稳定百分比 rollout 和决策原因解释，不依赖远程控制平面，适合库、服务、WASM 应用和教学示例。

当前版本：**0.1.3**。本项目面向 2026 MoonBit 国产开源生态大赛的工程基础设施方向，重点是可复用、可审计、可测试的本地功能发布能力。

## 功能范围

- `Bool`、`String`、`Int`、`Double` 四类旗标值。
- 默认值、禁用、静态、属性定向和百分比 rollout 的评估原因。
- 基于 `flag_key:targeting_key` 的确定性 `0..9999` rollout 桶。
- `FeatureProvider` trait，支持自定义 provider。
- JSON provider：支持嵌套 `flags` 对象或根对象配置；畸形 JSON、错误字段类型和非法 schema 返回 `None`。
- 多类型文本 DSL：支持 `Bool`、`String`、`Int`、`Double`、rollout、target 和 `disabled`，并可导出后回读。
- 批量评估、决策原因统计、隐私友好的 ledger、provider 审计/指纹/差异比较和部署前健康检查。
- 12 个确定性真实业务形态基准场景、4 个上下文的验收矩阵、可执行 CLI 示例、黑盒/白盒测试和跨平台 CI。

## 环境要求

- MoonBit CLI 0.10.3 验收基线，或更新的稳定版工具链。
- Git（仅在从源码运行时需要）。

MoonBit 官方安装器：<https://www.moonbitlang.com/download/>。

### Windows PowerShell

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
irm https://cli.moonbitlang.com/install/powershell.ps1 | iex
$env:Path += ";$HOME\.moon\bin"
moon version
```

### Linux / macOS

```bash
curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash
export PATH="$HOME/.moon/bin:$PATH"
moon version
```

安装器会安装当前稳定版；如果要严格复现组委会预验收环境，请使用 MoonBit 0.10.3，并确认 `moon version` 输出与通知一致。

## 从源码复现

```bash
git clone https://github.com/wccerty/MoonFeatureGate.git
cd MoonFeatureGate
moon install
moon fmt --check
moon check --deny-warn
moon info
moon test --deny-warn
moon run cmd/moonfeaturegate
moon test --deny-warn --target wasm-gc
moon run --target wasm-gc cmd/moonfeaturegate
```

Windows PowerShell 可使用完全相同的 `moon` 命令。`moon run` 的预期输出包含 `JSON Config Loaded successfully`、`rollout_match`、`target_match` 和 `Completed 100000 iterations`。

## 在其他 MoonBit 项目中安装

在目标项目的模块根目录执行：

```bash
moon add wccerty/moonfeaturegate
moon update
```

然后在 MoonBit 包中导入根包：

```mbt
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
println(detail.reason)
```

如果目标环境需要固定版本，请在 `moon.mod` 中确认依赖解析到 `0.1.3`，并将 `moon.lock`（若项目生成该文件）纳入版本控制。

## JSON 配置

推荐使用显式 `flags` 根字段：

```json
{
  "flags": {
    "new_checkout": {
      "value": true,
      "enabled": true,
      "rollout_percentage": 2500
    },
    "beta_banner": {
      "value": "beta",
      "target_attr": "plan",
      "target_value": "beta"
    }
  }
}
```

`value` 和 `target_value` 只能是布尔、字符串或数字；整数数字会解析为 `Int`，其他数字解析为 `Double`。`enabled` 必须是布尔值，`rollout_percentage` 必须是 `0..10000` 的整数；字段类型错误、目标字段不成对、非法百分比、错误 JSON 或非对象 `flags` 都会使 `parse_json_provider` 返回 `None`。空的 `"flags": {}` 是合法配置。

## 文本 DSL

`examples/flags.mfg` 可直接作为配置参考：

```text
# comments are allowed
flag new_checkout bool true rollout 2500
flag beta_banner bool true target plan beta
flag kill_switch bool false
flag theme string ocean-blue
flag max_connections int 256 target environment production
flag legacy_banner bool true disabled
```

支持的形式：

- `flag <key> <bool|string|int|double> <value>`
- 上述形式追加 `rollout <0..10000>`、`target <attribute> <string-value>` 或 `disabled`。

文本 DSL 的负数格式错误、空百分比、缺字段和多余字段会抛出 `ParseError.InvalidLine`；builder API 超出上限的百分比会钳制到 `10000`。`Provider::to_dsl()` 输出可以再次交给 `parse_provider()`。

## 批量评估、审计与部署检查

对于服务请求或 WASM 页面，可以把同一上下文中的多种旗标组成请求批次：

```mbt
let result = @moonfeaturegate.evaluate_batch(
  provider,
  [
    @moonfeaturegate.request("checkout.new_ui", @moonfeaturegate.bool_value(false)),
    @moonfeaturegate.request("service.max_connections", @moonfeaturegate.int_value(128)),
  ],
  @moonfeaturegate.context("user-42"),
)
println(result.summary())
```

发布配置前可执行 `provider.health_check(@moonfeaturegate.ProviderPolicy::production())`，检查 schema、禁用开关、rollout 约束和 provider inventory；`compare_providers` 可判断新旧配置是 identical、additive、changed 还是 breaking。`run_acceptance_scenario()` 提供可重复的 12 场景 × 4 上下文验收矩阵。

## 仓库结构

- 根包的 `*.mbt`：provider、上下文、值类型、评估器、JSON/文本解析器和 benchmark。
- `*_test.mbt` / `*_wbtest.mbt`：黑盒和白盒测试，覆盖正常路径与边界条件。
- `cmd/moonfeaturegate`：使用 `options("is-main": true)` 声明的 CLI 包。
- `examples/flags.mfg`：可读的 DSL 配置样例。
- `docs/design.md`：评估顺序和扩展边界。
- `benchmark_cases.mbt` / `scenario.mbt`：真实业务形态基准数据和验收矩阵。
- `audit.mbt` / `policy.mbt` / `deployment.mbt`：配置审计、发布策略和部署前检查。
- `release.mbt`：把健康检查、兼容性和审批信息组合为可审计的发布计划。
- `exposure.mbt`：统计请求上下文中的命中、默认值、目标不匹配和灰度分布。
- `docs/acceptance-checklist.md`：可重复的验收命令与仓库检查项。
- `.github/workflows/ci.yml`：Linux、macOS、Windows 的格式、检查、测试和 coverage 工作流。

## CI 与本地检查

CI 使用官方 MoonBit 安装器，并执行：

```text
moon fmt --check
moon check --deny-warn
moon info
moon test --deny-warn --enable-coverage
moon test --deny-warn --target native --enable-coverage
moon coverage report -f summary
moon coverage analyze
```

官方社区 CI 模板还要求检查所有目标；本仓库的 CI 在三平台执行格式检查、所有目标检查、测试、覆盖率和 native 路径，并在安装后显式验证 `moon` 可执行文件。

当前工程规模约为 4k 行非测试 MoonBit 源码，新增发布计划和暴露分析模块均服务于实际的配置发布、灰度观察和回滚审计流程。

## 开源与项目链接

- License：Apache-2.0，见 [LICENSE](LICENSE)。
- GitHub：<https://github.com/wccerty/MoonFeatureGate>
- GitLink：<https://gitlink.org.cn/Wccerty/MoonFeatureGate>
- Mooncakes：<https://mooncakes.io/docs/wccerty/moonfeaturegate>

MoonFeatureGate 保持本地运行边界，后续可以在不破坏当前 evaluator API 的前提下扩展 TOML provider、远程配置轮询、指标钩子和可视化预览。
