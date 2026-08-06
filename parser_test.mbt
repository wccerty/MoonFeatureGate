///|
test "text config parses static and rollout flags" {
  let config =
    #|# MoonFeatureGate example
    #|flag new_checkout bool true rollout 10000
    #|flag beta_banner bool true target plan beta
    #|
  let provider = @moonfeaturegate.parse_provider(config)
  let ctx = @moonfeaturegate.context("user-42").with_attr(
    "plan",
    @moonfeaturegate.string_value("beta"),
  )
  let checkout = @moonfeaturegate.evaluate_bool(
    provider,
    "new_checkout",
    ctx,
    default=false,
  )
  let banner = @moonfeaturegate.evaluate_bool(
    provider,
    "beta_banner",
    ctx,
    default=false,
  )
  assert_true(checkout.value)
  inspect(checkout.reason, content="rollout_match")
  assert_true(banner.value)
  inspect(banner.reason, content="target_match")
}

///|
test "text config reports invalid lines" {
  try @moonfeaturegate.parse_provider("flag broken") catch {
    InvalidLine(line=1, text="flag broken") =>
      inspect("line 1", content="line 1")
    _ => fail("unexpected parse error")
  } noraise {
    _ => fail("expected parse error")
  }
}

///|
test "text config clamps rollout percentages to documented boundaries" {
  let config =
    #|flag always_on bool true rollout 10001
    #|flag always_off bool true rollout 0
  let provider = @moonfeaturegate.parse_provider(config)
  let ctx = @moonfeaturegate.context("user-1")
  let on = @moonfeaturegate.evaluate_bool(
    provider,
    "always_on",
    ctx,
    default=false,
  )
  let off = @moonfeaturegate.evaluate_bool(
    provider,
    "always_off",
    ctx,
    default=false,
  )
  assert_true(on.value)
  inspect(on.reason, content="rollout_match")
  assert_false(off.value)
  inspect(off.reason, content="rollout_miss")
}
