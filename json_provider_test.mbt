///|
test "JSON provider parsing and multi-type evaluation" {
  let json =
    #|{
    #|  "flags": {
    #|    "bool_flag": {
    #|      "value": true,
    #|      "enabled": true
    #|    },
    #|    "string_flag": {
    #|      "value": "hello_moonbit",
    #|      "enabled": true
    #|    },
    #|    "int_flag": {
    #|      "value": 42,
    #|      "enabled": true
    #|    },
    #|    "double_flag": {
    #|      "value": 3.14,
    #|      "enabled": true
    #|    }
    #|  }
    #|}
  let provider = parse_json_provider(json).unwrap()
  let ctx = context("user-1")
  let eval_bool = evaluate_bool(provider, "bool_flag", ctx, default=false)
  assert_true(eval_bool.value)
  inspect(eval_bool.reason, content="static")
  let eval_str = evaluate_string(provider, "string_flag", ctx, default="")
  inspect(eval_str.value, content="hello_moonbit")
  inspect(eval_str.reason, content="static")
  let eval_int = evaluate_int(provider, "int_flag", ctx, default=0)
  inspect(eval_int.value, content="42")
  inspect(eval_int.reason, content="static")
  let eval_double = evaluate_double(provider, "double_flag", ctx, default=0.0)
  inspect(eval_double.value, content="3.14")
  inspect(eval_double.reason, content="static")
}
