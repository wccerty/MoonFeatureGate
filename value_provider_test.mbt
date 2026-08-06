///|
test "missing bool flag returns default with explanation" {
  let provider = @moonfeaturegate.empty_provider()
  let ctx = @moonfeaturegate.context("user-42")
  let detail = @moonfeaturegate.evaluate_bool(
    provider,
    "new_checkout",
    ctx,
    default=true,
  )
  assert_true(detail.value)
  inspect(detail.reason, content="default")
  inspect(detail.flag_key, content="new_checkout")
}

///|
test "flag values render stable text for CLI and docs" {
  inspect(@moonfeaturegate.bool_value(true).to_text(), content="true")
  inspect(
    @moonfeaturegate.string_value("checkout-b").to_text(),
    content="checkout-b",
  )
  inspect(@moonfeaturegate.int_value(42).to_text(), content="42")
}

///|
test "disabled flags return the caller default" {
  let provider = @moonfeaturegate.empty_provider().with_bool(
    "kill_switch",
    true,
    enabled=false,
  )
  let detail = @moonfeaturegate.evaluate_bool(
    provider,
    "kill_switch",
    @moonfeaturegate.context("user-1"),
    default=false,
  )
  assert_false(detail.value)
  inspect(detail.reason, content="disabled")
}

///|
test "typed evaluation explains a type mismatch" {
  let provider = @moonfeaturegate.empty_provider().with_string("theme", "ocean")
  let detail = @moonfeaturegate.evaluate_bool(
    provider,
    "theme",
    @moonfeaturegate.context("user-1"),
    default=true,
  )
  assert_true(detail.value)
  inspect(detail.reason, content="type_mismatch")
}
