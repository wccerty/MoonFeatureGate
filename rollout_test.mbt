///|
test "rollout bucket is stable and bounded" {
  let a = @moonfeaturegate.rollout_bucket("new_checkout", "user-42")
  let b = @moonfeaturegate.rollout_bucket("new_checkout", "user-42")
  assert_eq(a, b)
  assert_true(a >= 0)
  assert_true(a < 10000)
}

///|
test "percentage rollout respects closed boundaries" {
  let ctx = @moonfeaturegate.context("user-42")
  let off = @moonfeaturegate.empty_provider().with_bool_rollout(
    "new_checkout",
    true,
    percentage=0,
  )
  let on = @moonfeaturegate.empty_provider().with_bool_rollout(
    "new_checkout",
    true,
    percentage=10000,
  )
  let off_detail = @moonfeaturegate.evaluate_bool(
    off,
    "new_checkout",
    ctx,
    default=false,
  )
  let on_detail = @moonfeaturegate.evaluate_bool(
    on,
    "new_checkout",
    ctx,
    default=false,
  )
  assert_false(off_detail.value)
  inspect(off_detail.reason, content="rollout_miss")
  assert_true(on_detail.value)
  inspect(on_detail.reason, content="rollout_match")
}
