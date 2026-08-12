///|
test "batch evaluation returns decisions and reason counts" {
  let provider = empty_provider()
    .with_bool("new_ui", true)
    .with_string("theme", "ocean")
    .with_int_rollout("limit", 128, percentage=10000)
  let requests = [
    request("new_ui", bool_value(false)),
    request("theme", string_value("default")),
    request("limit", int_value(0)),
    request("missing", bool_value(true)),
  ]
  let result = evaluate_batch(provider, requests, context("user-1"))
  assert_eq(result.evaluations.length(), 4)
  assert_eq(result.stats.total, 4)
  assert_eq(result.stats.successes, 3)
  assert_eq(result.stats.defaults, 1)
  assert_eq(result.reason_count("static"), 2)
  assert_eq(result.reason_count("rollout_match"), 1)
  assert_eq(result.reason_count("default"), 1)
}

///|
test "batch evaluation keeps type mismatches visible" {
  let provider = empty_provider().with_string("theme", "ocean")
  let result = evaluate_batch(
    provider,
    [request("theme", bool_value(true))],
    context("user-2"),
  )
  let item = result.evaluations[0]
  assert_true(item.value is BoolValue(true))
  inspect(item.reason, content="type_mismatch")
  assert_eq(result.stats.type_mismatches, 1)
}

///|
test "batch report supports stable human-readable summaries" {
  let provider = empty_provider().with_bool("a", true).with_bool("b", false)
  let result = evaluate_batch(
    provider,
    [request("a", bool_value(false)), request("b", bool_value(true))],
    context("user-3"),
  )
  let summary = result.summary()
  assert_true(summary.has_prefix("2 evaluations"))
  assert_true(summary.contains("static=2"))
}
