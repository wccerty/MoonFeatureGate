MoonFeatureGate
===============

MoonFeatureGate is a MoonBit-native feature flag and gradual rollout toolkit.
It evaluates flags locally, keeps rollout decisions deterministic, and returns
an explanation for every decision.

```mbt check
///|
test "README example evaluates a static flag" {
  let provider = empty_provider().with_bool("demo", true)
  let detail = evaluate_bool(provider, "demo", context("user-1"), default=false)
  inspect(detail.value, content="true")
  inspect(detail.reason, content="static")
}
```
