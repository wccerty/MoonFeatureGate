///|
test "exposure report aggregates defaults and typed matches" {
  let provider = empty_provider()
    .with_value("release.banner", StringValue("blue"))
    .with_value_target(
      "release.beta",
      BoolValue(true),
      attr="plan",
      equals=StringValue("pro"),
    )
  let samples = [
    context("u-1").with_attr("plan", StringValue("pro")),
    context("u-2").with_attr("plan", StringValue("free")),
    context("u-3"),
  ]
  let report = analyze_exposure(
    provider,
    [
      exposure_request("release.banner", StringValue("default")),
      exposure_request("release.beta", BoolValue(false)),
    ],
    samples,
  )
  assert_eq(report.sample_count(), 3)
  assert_eq(report.row("release.banner").unwrap().matches, 3)
  assert_eq(report.row("release.beta").unwrap().target_misses, 2)
  assert_true(report.has_anomalies())
  assert_true(report.render().contains("release.beta"))
  assert_eq(report.rows_for_prefix("release.").length(), 2)
  assert_true(report.coverage_percent() > 0.0)
  assert_false(report.assess(safe_exposure_threshold()).passed)
  assert_true(report.recommendation().contains("review"))
  assert_true(report.is_representative(minimum=2))
  assert_true(report.reason_totals().contains("target_miss"))
  assert_eq(report.rollout_rows().length(), 0)
  assert_true(report.compact_signature().contains("release.banner"))
  assert_true(report.kind_summary().contains("string"))
  assert_eq(report.targeting_miss_rate(), 2.0 / 6.0)
}

///|
test "exposure report preserves rollout boundaries and empty input" {
  let provider = empty_provider().with_value_rollout(
    "release.experiment",
    BoolValue(true),
    percentage=10000,
  )
  let report = analyze_exposure(
    provider,
    [exposure_request("release.experiment", BoolValue(false))],
    [context("u-1"), context("u-2")],
  )
  let row = report.row("release.experiment").unwrap()
  assert_eq(row.matches, 2)
  assert_eq(row.rollout_matches, 2)
  let empty = analyze_exposure(provider, [], [])
  assert_eq(empty.sample_count(), 0)
  assert_false(empty.has_anomalies())
  assert_eq(empty.coverage_percent(), 0.0)
  assert_true(empty.assess(permissive_exposure_threshold()).passed)
  assert_eq(
    empty.recommendation(),
    "collect a representative sample before release",
  )
  assert_false(empty.is_representative(minimum=1))
  assert_false(empty.healthy_for_release())
  assert_eq(empty.rollout_rows().length(), 0)
}

///|
test "exposure analysis records disabled, mismatch and rollout misses" {
  let provider = empty_provider()
    .with_value("release.int", IntValue(7))
    .with_value("release.disabled", BoolValue(true), enabled=false)
    .with_value_rollout("release.zero", BoolValue(true), percentage=0)
  let report = analyze_exposure(
    provider,
    [
      exposure_request("release.int", IntValue(0)),
      exposure_request("release.disabled", BoolValue(false)),
      exposure_request("release.int", StringValue("wrong")),
      exposure_request("release.zero", BoolValue(false)),
    ],
    [context("u-1"), context("u-2")],
  )
  assert_true(report.default_count() > 0)
  assert_true(report.rows_with_defaults().length() > 0)
  assert_true(report.reason_totals().contains("disabled"))
  assert_true(report.reason_totals().contains("rollout_miss"))
  assert_true(report.quality_score() < 100)
  assert_true(report.recommendation().contains("review"))
}
