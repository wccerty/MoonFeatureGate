///|
test "release plan blocks breaking changes in production" {
  let previous = empty_provider().with_value(
    "release.checkout",
    BoolValue(true),
  )
  let next = empty_provider().with_value(
    "release.new_checkout",
    BoolValue(true),
  )
  let plan = plan_release(
    Some(previous),
    next,
    environment=Production,
    policy=ProviderPolicy::production(),
    owner="checkout",
    change_ticket="REL-100",
  )
  assert_true(plan.requires_manual_approval())
  assert_false(plan.is_approved())
  assert_true(plan.risk() is Critical)
  assert_true(plan.rollback().length() > 0)
  assert_true(plan.summary().contains("blocked"))
  assert_eq(plan.change_count(), 2)
  assert_true(plan.risk_explanation().contains("removed"))
}

///|
test "release plan can be approved for additive staging change" {
  let previous = empty_provider().with_value(
    "release.checkout",
    BoolValue(true),
  )
  let next = previous.with_value("release.banner", StringValue("new"))
  let plan = plan_release(
    Some(previous),
    next,
    environment=Staging,
    policy=ProviderPolicy::for_tests(),
    owner="growth",
    change_ticket="REL-101",
  )
  let approved = plan.approve("reviewer")
  assert_true(approved.is_approved())
  assert_true(approved.is_release_ready())
  assert_true(approved.render().contains("reviewer"))
  assert_true(approved.approval_steps().length() >= 2)
  assert_true(approved.guardrails().length() >= 2)
  assert_true(approved.risk_score() > 0)
  assert_false(approved.replay_required())
  assert_eq(approved.changed_keys().length(), 1)
  assert_eq(approved.stage(), "staging-ready")
  assert_true(approved.change_summary().contains("added"))
}

///|
test "release plan rejects incomplete metadata" {
  let plan = plan_release(
    None,
    empty_provider(),
    environment=Development,
    policy=ProviderPolicy::for_tests(),
    owner="",
    change_ticket="",
  )
  assert_true(plan.metadata_errors().length() >= 2)
  assert_false(plan.is_release_ready())
  assert_false(plan.audit_ready())
  assert_eq(plan.stage(), "metadata-invalid")
}

///|
test "release plan exposes environment and replay branches" {
  let development : ReleaseEnvironment = Development
  let canary : ReleaseEnvironment = Canary
  let production : ReleaseEnvironment = Production
  assert_eq(development.name(), "development")
  assert_eq(canary.name(), "canary")
  assert_true(canary.requires_approval())
  assert_true(production.maximum_risk() is Critical)
  let previous = empty_provider().with_value("release.limit", IntValue(10))
  let next = empty_provider().with_value("release.limit", IntValue(20))
  let plan = plan_release(
    Some(previous),
    next,
    environment=Canary,
    policy=ProviderPolicy::production(),
    owner="capacity",
    change_ticket="REL-102",
  )
  assert_true(plan.replay_required())
  assert_eq(plan.stage(), "replay-required")
  assert_true(
    plan.reject("reviewer", "unsafe").approval_label().contains("unsafe"),
  )
  assert_true(plan.render().contains("compatibility="))
}

///|
test "initial release plan records operator notes" {
  let plan = plan_release(
    None,
    empty_provider().with_value("release.first", BoolValue(true)),
    environment=Development,
    policy=ProviderPolicy::for_tests(),
    owner="platform",
    change_ticket="REL-103",
  )
  assert_true(plan.operator_notes().length() >= 3)
  assert_true(plan.rollback_fingerprint() is None)
  assert_true(plan.rollback().join(" ").contains("disable newly introduced"))
}
