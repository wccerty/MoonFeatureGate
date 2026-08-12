///|
test "text DSL supports all public value types" {
  let config =
    #|flag bool_flag bool true
    #|flag string_flag string ocean-blue
    #|flag int_flag int -42
    #|flag double_flag double 3.125
    #|flag rollout_flag int 10 rollout 7500
    #|flag target_flag string beta target plan pro
    #|
  let provider = parse_provider(config)
  let ctx = context("user-4").with_attr("plan", string_value("pro"))
  assert_true(evaluate_bool(provider, "bool_flag", ctx, default=false).value)
  inspect(
    evaluate_string(provider, "string_flag", ctx, default="").value,
    content="ocean-blue",
  )
  inspect(
    evaluate_int(provider, "int_flag", ctx, default=0).value,
    content="-42",
  )
  inspect(
    evaluate_double(provider, "double_flag", ctx, default=0.0).value,
    content="3.125",
  )
  inspect(
    evaluate_int(provider, "rollout_flag", ctx, default=0).reason,
    content="rollout_match",
  )
  inspect(
    evaluate_string(provider, "target_flag", ctx, default="").reason,
    content="target_match",
  )
}

///|
test "text DSL rejects invalid numeric and key tokens" {
  try parse_provider("flag bad int nope") catch {
    InvalidLine(line=1, text="flag bad int nope") => ()
    _ => fail("unexpected parse error")
  } noraise {
    _ => fail("expected numeric parse error")
  }
  try parse_provider("flag bad bool true rollout -1") catch {
    InvalidLine(line=1, text="flag bad bool true rollout -1") => ()
    _ => fail("unexpected parse error")
  } noraise {
    _ => fail("expected negative rollout error")
  }
}
