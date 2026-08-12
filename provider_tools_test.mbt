///|
test "provider tools keep rule metadata during selection" {
  let provider = empty_provider()
    .with_bool_rollout("release.ui", true, percentage=2500)
    .with_string_target(
      "release.theme",
      "dark",
      attr="plan",
      equals=string_value("pro"),
    )
    .with_bool("internal", false, enabled=false)
  let selected = provider.select(["release.ui", "release.theme"])
  assert_eq(selected.stats().total, 2)
  assert_true(selected.get_flag_definition("release.ui").unwrap().is_rollout())
  assert_true(
    selected.get_flag_definition("release.theme").unwrap().has_target(),
  )
  assert_eq(selected.keys_with_prefix("release.").length(), 2)
  assert_eq(provider.without_disabled().stats().total, 2)
  assert_true(provider.to_dsl().contains("rollout 2500"))
}

///|
test "provider diff separates additions removals and changes" {
  let left = empty_provider()
    .with_bool("same", true)
    .with_bool("removed", false)
  let right = empty_provider().with_bool("same", true).with_bool("added", true)
  let diff = diff_providers(left, right)
  assert_true(diff.added is ["added"])
  assert_true(diff.removed is ["removed"])
  assert_true(diff.unchanged is ["same"])
  assert_true(!diff.is_compatible())
  assert_true(diff.summary().contains("changed=0"))
}

///|
test "usage inventory separates operational and static flags" {
  let provider = empty_provider()
    .with_bool("plain", true)
    .with_bool_rollout("release.ui", true, percentage=10000)
    .with_bool("off", false, enabled=false)
  assert_eq(provider.operational_flag_count(), 1)
  assert_true(
    provider.render_usage().contains("release.ui [bool, rollout, enabled]"),
  )
  assert_true(provider.disabled_keys() is ["off"])
}
