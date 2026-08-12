///|
test "acceptance scenario is deterministic and replayable" {
  let report = run_acceptance_scenario()
  assert_true(report.contexts >= 4)
  assert_eq(report.requests_per_context, benchmark_cases().length())
  assert_true(report.is_reproducible())
  assert_true(report.total >= 40)
  assert_true(report.matches > 0)
  assert_true(report.summary().contains("OSC2026 acceptance matrix"))
}

///|
test "DSL export can be read back with rule semantics" {
  let original = empty_provider()
    .with_bool("release.ui", true, enabled=false)
    .with_int_rollout("release.limit", 64, percentage=2500)
    .with_string_target(
      "release.theme",
      "dark",
      attr="plan",
      equals=string_value("pro"),
    )
  let restored = parse_provider(original.to_dsl())
  assert_eq(restored.stats().total, 3)
  assert_false(restored.get_flag_definition("release.ui").unwrap().enabled)
  assert_true(
    restored.get_flag_definition("release.limit").unwrap().is_rollout(),
  )
  assert_true(
    restored.get_flag_definition("release.theme").unwrap().has_target(),
  )
}
