///|
test "realistic benchmark dataset is deterministic and non-empty" {
  let cases = benchmark_cases()
  assert_true(cases.length() >= 8)
  assert_true(cases[0].key != "")
  let report = run_scenario_benchmark()
  assert_true(report.total_requests >= 1000)
  assert_eq(report.scenarios, cases.length())
  assert_true(report.successful_evaluations > 0)
}
