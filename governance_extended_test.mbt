///|
test "audit report identifies intentional operational risks" {
  let provider = empty_provider()
    .with_bool_rollout("off", false, percentage=0)
    .with_bool("disabled", true, enabled=false)
  let report = provider.audit()
  assert_eq(report.total_flags, 2)
  assert_true(report.is_clean())
  assert_true(report.issue_count(Info) >= 2)
  assert_true(report.summary().has_prefix("2 flags audited"))
  assert_true(provider.describe().contains("off -> bool:rollout"))
  assert_true(provider.fingerprint() != "")
}

///|
test "audit warns when targeting and rollout are combined" {
  let provider = empty_provider().with_value_target(
    "targeted",
    bool_value(true),
    attr="plan",
    equals=string_value("pro"),
  )
  let report = provider.audit()
  assert_false(report.has_warnings())
  let combined_flag : FlagDefinition = {
    key: "combined",
    value: bool_value(true),
    enabled: true,
    rollout_percentage: Some(5000),
    target_attr: Some("plan"),
    target_value: Some(string_value("pro")),
  }
  let combined = empty_provider().with_definition(combined_flag)
  assert_true(combined.audit().has_warnings())
  assert_true(combined.audit().render().contains("target_before_rollout"))
}

///|
test "audit reports malformed hand-built definitions" {
  let invalid : FlagDefinition = {
    key: "",
    value: bool_value(true),
    enabled: true,
    rollout_percentage: Some(12000),
    target_attr: Some(""),
    target_value: None,
  }
  let report = empty_provider().with_definition(invalid).audit()
  assert_false(report.is_clean())
  assert_true(report.issue_count(Error) >= 2)
  assert_true(report.render().contains("rollout_out_of_range"))
}

///|
test "ledger aggregates decisions without retaining identities" {
  let provider = empty_provider().with_bool("flag", true)
  let ledger = new_ledger()
  let result = evaluate_with_ledger(
    provider,
    [request("flag", bool_value(false)), request("missing", bool_value(true))],
    context("user-secret"),
    ledger,
  )
  assert_eq(ledger.total, 2)
  assert_eq(ledger.matches, 1)
  assert_eq(ledger.defaults, 1)
  assert_eq(ledger.count("static"), 1)
  assert_true(ledger.summary().contains("decisions=2"))
  assert_true(result.evaluations[0].is_match())
  ledger.reset()
  assert_eq(ledger.total, 0)
}
