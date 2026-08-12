///|
test "deployment check blocks incompatible replacement" {
  let previous = empty_provider().with_bool("stable", true)
  let next = empty_provider().with_bool("new", true)
  let decision = deployment_check(
    Some(previous),
    next,
    ProviderPolicy::production(),
  )
  assert_false(decision.allowed)
  assert_true(decision.requires_manual_review())
  assert_true(decision.summary().contains("blocked"))
  assert_eq(decision.health_status(), "healthy")
}
