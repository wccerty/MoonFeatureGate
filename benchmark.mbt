///|
pub fn run_benchmark() -> String {
  let provider = empty_provider()
    .with_bool("test_bool", true)
    .with_string("test_string", "hello")
    .with_int("test_int", 42)
  let ctx = context("user-123")
  let iterations = 100000
  for _ in 0..<iterations {
    let _ = evaluate_bool(provider, "test_bool", ctx, default=false)
    let _ = evaluate_string(provider, "test_string", ctx, default="default")
    let _ = evaluate_int(provider, "test_int", ctx, default=0)
  }
  "Completed \{iterations} iterations of multi-type evaluation successfully."
}
