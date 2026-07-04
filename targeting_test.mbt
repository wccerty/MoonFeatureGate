///|
test "attribute targeting can match a selected audience" {
  let ctx = @moonfeaturegate.context("user-42").with_attr(
    "plan",
    @moonfeaturegate.string_value("beta"),
  )
  let provider = @moonfeaturegate.empty_provider().with_bool_target(
    "beta_banner",
    true,
    attr="plan",
    equals=@moonfeaturegate.string_value("beta"),
  )
  let detail = @moonfeaturegate.evaluate_bool(
    provider,
    "beta_banner",
    ctx,
    default=false,
  )
  assert_true(detail.value)
  inspect(detail.reason, content="target_match")
}

///|
test "attribute targeting falls back when the audience does not match" {
  let ctx = @moonfeaturegate.context("user-99").with_attr(
    "plan",
    @moonfeaturegate.string_value("stable"),
  )
  let provider = @moonfeaturegate.empty_provider().with_bool_target(
    "beta_banner",
    true,
    attr="plan",
    equals=@moonfeaturegate.string_value("beta"),
  )
  let detail = @moonfeaturegate.evaluate_bool(
    provider,
    "beta_banner",
    ctx,
    default=false,
  )
  assert_false(detail.value)
  inspect(detail.reason, content="target_miss")
}
