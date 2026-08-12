///|
test "registry activates only audited provider snapshots" {
  let first = snapshot(
    "baseline",
    "2026-08-12",
    empty_provider().with_bool("a", true),
  )
  let registry = new_registry().register(first)
  assert_true(registry.contains("baseline"))
  let active = registry.activate("baseline").unwrap()
  assert_true(active.active() is Some(_))
  assert_eq(active.names().length(), 1)
  let removed = active.remove("baseline")
  assert_true(removed.active() is None)
}

///|
test "rollout distribution exposes reproducible boundary data" {
  let keys = ["u-0", "u-1", "u-2", "u-3", "u-4", "u-5", "u-6", "u-7"]
  let distribution = measure_rollout("checkout.new_ui", keys, 5000)
  assert_eq(distribution.samples, 8)
  assert_true(distribution.min_bucket <= distribution.max_bucket)
  assert_true(distribution.summary().contains("requested=5000"))
  assert_true(rollout_matches("flag", "user", 10000))
  assert_false(rollout_matches("flag", "user", 0))
}
