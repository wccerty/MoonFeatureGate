MoonFeatureGate
===============

MoonFeatureGate is a MoonBit-native feature flag and gradual rollout toolkit.
It evaluates flags locally, explains why a value was chosen, and keeps the
core runtime independent from a hosted control plane.

The project is built for the 2026 MoonBit open-source ecosystem competition.
It focuses on reusable engineering infrastructure: targeting rules, stable
percentage rollout, typed flag values, CLI checks, examples, tests, and a
clear path toward OpenFeature-style providers.

Project Name
------------

MoonFeatureGate: MoonBit native feature flags and gradual rollout toolkit.

Short description for proposal forms:

MoonFeatureGate is a MoonBit-native feature flag and gradual rollout toolkit.
It supports local rule evaluation, user targeting, stable percentage buckets,
decision explanations, and CLI validation so MoonBit projects can ship features
through auditable rollout and configuration policies.

Why This Exists
---------------

MoonBit already has growing packages for parsing, databases, UI, tracing, and
tooling. Feature management is a mature engineering area in other ecosystems,
but a small MoonBit-native runtime is still useful for examples, services,
WASM demos, and infrastructure libraries that need local decisions without
calling a hosted feature-flag service.

Core API
--------

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

Configuration DSL
-----------------

Each non-empty line defines one flag. Lines starting with `#` are comments.

```text
flag new_checkout bool true rollout 2500
flag beta_banner bool true target plan beta
```

Supported v0.1 forms:

- `flag <key> bool <true|false>`
- `flag <key> bool <true|false> rollout <0..10000>`
- `flag <key> bool <true|false> target <attribute> <string-value>`

Run
---

```powershell
moon test
moon run cmd/moonfeaturegate
moon check --warn-list +73
```

Expected demo output:

```text
MoonFeatureGate demo
flag=new_checkout
user=user-42
value=true
reason=rollout_match
```

Competition Notes
-----------------

- Original project; not a direct port of a single upstream library.
- General design is informed by mature feature-flag systems and the
  vendor-neutral OpenFeature idea, but v0.1 keeps a compact local API.
- Planned extensions: JSON/TOML providers, OpenFeature-like provider boundary,
  metrics hooks, remote config polling, and a small web preview.
