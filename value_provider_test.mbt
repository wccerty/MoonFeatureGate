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
