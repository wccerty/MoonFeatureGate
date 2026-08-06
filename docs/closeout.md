# MoonFeatureGate Re-acceptance Closeout

Date: 2026-08-07

## Submission identity

- Project: MoonFeatureGate
- Author: 魏承昌
- Git author: `Wccerty <3496197313@qq.com>`
- GitHub: <https://github.com/wccerty/MoonFeatureGate>
- GitLink: <https://gitlink.org.cn/Wccerty/MoonFeatureGate>
- Mooncakes: <https://mooncakes.io/docs/wccerty/moonfeaturegate>

## Remediation delivered

- Updated empty maps to explicit `Map([])` so `moon check --deny-warn` is stable
  on the MoonBit 0.10.3-compatible toolchain.
- Updated the CLI package to `pkgtype(kind: "executable")` and documented the
  exact `moon run cmd/moonfeaturegate` command.
- Added strict JSON schema validation and tests for malformed JSON, wrong field
  types, empty maps, disabled flags, type mismatches, targets and rollout edges.
- Rewrote the README and acceptance materials as UTF-8 with reproducible
  installation, `moon add`, JSON, DSL, CLI and CI instructions.
- Kept the public API package-local and regenerated `.mbti` files with `moon info`.

## Verification commands

```powershell
moon fmt --check
moon check --deny-warn
moon info
moon test --deny-warn
moon test --deny-warn --target native --enable-coverage
moon coverage report -f summary
moon coverage analyze
moon run cmd/moonfeaturegate
```

## Future maintenance

The next useful extensions are TOML/provider adapters, remote configuration
polling, metrics hooks, and a small web preview. They should preserve the
current local evaluator and provider contracts.
