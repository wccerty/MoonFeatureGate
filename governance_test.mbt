///|
test "context helpers preserve immutable configuration" {
  let base = context("user-7")
  let enriched = base
    .with_attr("plan", string_value("pro"))
    .with_attr("region", string_value("cn-east"))
  assert_true(enriched.has_attr("plan"))
  assert_true(enriched.get_attr("region") is Some(StringValue("cn-east")))
  assert_true(base.get_attr("plan") is None)
  let moved = enriched.with_targeting_key("user-8")
  inspect(moved.targeting_key, content="user-8")
  assert_true(moved.get_attr("plan") is Some(StringValue("pro")))
}

///|
test "provider governance reports useful production metadata" {
  let provider = empty_provider()
    .with_bool("static", true)
    .with_string_rollout("rollout", "blue", percentage=2500)
    .with_int_target("targeted", 42, attr="plan", equals=string_value("pro"))
    .with_double("disabled", 1.5, enabled=false)
  assert_true(provider.contains("static"))
  assert_false(provider.contains("missing"))
  let keys = provider.flag_keys()
  assert_eq(keys.length(), 4)
  let stats = provider.stats()
  assert_eq(stats.total, 4)
  assert_eq(stats.enabled, 3)
  assert_eq(stats.disabled, 1)
  assert_eq(stats.rollout, 1)
  assert_eq(stats.targeted, 1)
  assert_eq(stats.bool_count, 1)
  assert_eq(stats.string_count, 1)
  assert_eq(stats.int_count, 1)
  assert_eq(stats.double_count, 1)
}

///|
test "provider merge uses the overlay as the source of truth" {
  let base = empty_provider().with_bool("shared", false).with_bool("base", true)
  let overlay = empty_provider()
    .with_bool("shared", true)
    .with_bool("new", true)
  let merged = base.merge(overlay)
  let shared = evaluate_bool(merged, "shared", context("u"), default=false)
  assert_true(shared.value)
  assert_eq(merged.stats().total, 3)
  let removed = merged.remove("base")
  assert_false(removed.contains("base"))
  assert_eq(removed.stats().total, 2)
}

///|
test "flag definition metadata identifies rule shape" {
  let provider = empty_provider()
    .with_bool("plain", true)
    .with_bool_rollout("rollout", true, percentage=5000)
    .with_bool_target("target", true, attr="tier", equals=string_value("pro"))
  let plain = provider.get_flag_definition("plain").unwrap()
  let rollout = provider.get_flag_definition("rollout").unwrap()
  let target = provider.get_flag_definition("target").unwrap()
  inspect(plain.value_kind(), content="bool")
  assert_false(plain.is_rollout())
  assert_true(rollout.is_rollout())
  assert_true(target.has_target())
  assert_eq(rollout.validation_errors().length(), 0)
}
