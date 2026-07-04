///|
pub fn demo_output() -> String {
  let provider = empty_provider().with_bool_rollout(
    "new_checkout",
    true,
    percentage=10000,
  )
  let ctx = context("user-42").with_attr("plan", string_value("beta"))
  let detail = evaluate_bool(provider, "new_checkout", ctx, default=false)
  let output =
    $|MoonFeatureGate demo
    $|flag=\{detail.flag_key}
    $|user=\{ctx.targeting_key}
    $|value=\{detail.value}
    $|reason=\{detail.reason}
    $|
  output
}
