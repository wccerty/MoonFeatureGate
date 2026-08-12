///|
test "production policy rejects disabled and zero rollout flags" {
  let provider = empty_provider()
    .with_bool("maintenance", true, enabled=false)
    .with_bool_rollout("release.ui", true, percentage=0)
  let report = provider.check_policy(ProviderPolicy::production())
  assert_false(report.is_compliant())
  assert_eq(report.violation_count(), 2)
  assert_true(report.render().contains("disabled_not_allowed"))
}

///|
test "policy activation keeps compliant providers usable" {
  let provider = empty_provider().with_bool("release.ui", true)
  let activated = provider.activate_if_compliant(ProviderPolicy::production())
  assert_true(activated is Some(_))
  let rejected = empty_provider()
    .with_bool("experiment.ui", true)
    .with_bool("legacy", false, enabled=false)
  assert_true(
    rejected.activate_if_compliant(ProviderPolicy::production()) is None,
  )
}
