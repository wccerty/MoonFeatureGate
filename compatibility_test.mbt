///|
test "compatibility report distinguishes additive and breaking changes" {
  let previous = empty_provider().with_bool("stable", true)
  let additive = previous.with_string("new", "value")
  let added_report = compare_providers(previous, additive)
  assert_true(added_report.is_safe())
  assert_false(added_report.requires_replay())
  assert_true(added_report.summary().has_prefix("additive"))
  let breaking = additive.remove("stable")
  let breaking_report = compare_providers(additive, breaking)
  assert_false(breaking_report.is_safe())
  assert_true(breaking_report.requires_replay())
  assert_true(breaking_report.summary().has_prefix("breaking"))
}

///|
test "inventory keeps type and rule counts consistent" {
  let provider = empty_provider()
    .with_bool("plain", true)
    .with_string_rollout("rollout", "blue", percentage=5000)
    .with_int_target("target", 1, attr="plan", equals=string_value("pro"))
  let inventory = provider.inventory()
  assert_true(inventory.is_balanced())
  assert_eq(inventory.total, 3)
  assert_true(provider.rollout_keys() is ["rollout"])
  assert_true(provider.targeted_keys() is ["target"])
  assert_true(provider.static_keys() is ["plain"])
  assert_true(inventory.summary().contains("flags=3"))
}
