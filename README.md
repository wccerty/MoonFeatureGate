# MoonFeatureGate

MoonFeatureGate 是一个 MoonBit 原生的功能开关与渐进式发布工具库。它在本地完成类型安全的旗标评估、用户定向、稳定百分比 rollout 和决策原因解释，不依赖远程控制平面，适合库、服务、WASM 应用和教学示例。

当前版本：**0.1.1**。本项目面向 2026 MoonBit 国产开源生态大赛的工程基础设施方向，重点是可复用、可审计、可测试的本地功能发布能力。

## 功能范围

- `Bool`、`String`、`Int`、`Double` 四类旗标值。
- 默认值、禁用、静态、属性定向和百分比 rollout 的评估原因。
- 基于 `flag_key:targeting_key` 的确定性 `0..9999` rollout 桶。
- `FeatureProvider` trait，支持自定义 provider。
- JSON provider：支持嵌套 `flags` 对象或根对象配置；畸形 JSON、错误字段类型和非法 schema 返回 `None`。
- 紧凑文本 DSL、可执行 CLI 示例、黑盒/白盒测试和跨平台 CI。

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

如果目标环境需要固定版本，请在 `moon.mod` 中确认依赖解析到 `0.1.1`，并将 `moon.lock`（若项目生成该文件）纳入版本控制。

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
```

支持的形式：

- `flag <key> bool <true|false>`
- `flag <key> bool <true|false> rollout <0..10000>`
- `flag <key> bool <true|false> target <attribute> <string-value>`

文本 DSL 的负数、空百分比、缺字段和多余字段会抛出 `ParseError.InvalidLine`；超出上限的 builder API/DSL 百分比会钳制到 `10000`。

## 仓库结构

- 根包的 `*.mbt`：provider、上下文、值类型、评估器、JSON/文本解析器和 benchmark。
- `*_test.mbt` / `*_wbtest.mbt`：黑盒和白盒测试，覆盖正常路径与边界条件。
- `cmd/moonfeaturegate`：使用 `pkgtype(kind: "executable")` 声明的 CLI 包。
- `examples/flags.mfg`：可读的 DSL 配置样例。
- `docs/design.md`：评估顺序和扩展边界。
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

## 开源与项目链接

- License：Apache-2.0，见 [LICENSE](LICENSE)。
- GitHub：<https://github.com/wccerty/MoonFeatureGate>
- GitLink：<https://gitlink.org.cn/Wccerty/MoonFeatureGate>
- Mooncakes：<https://mooncakes.io/docs/wccerty/moonfeaturegate>

MoonFeatureGate 的首版保持本地运行边界，后续可以在不破坏当前 evaluator API 的前提下扩展 TOML provider、远程配置轮询、指标钩子和可视化预览。
