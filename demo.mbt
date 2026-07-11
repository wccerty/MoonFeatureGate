///|
pub fn demo_output() -> String {
  let json_config =
    #|{
    #|  "flags": {
    #|    "enable_new_ui": {
    #|      "value": true,
    #|      "enabled": true,
    #|      "rollout_percentage": 10000
    #|    },
    #|    "theme_color": {
    #|      "value": "ocean-blue",
    #|      "enabled": true
    #|    },
    #|    "max_connections": {
    #|      "value": 128,
    #|      "enabled": true,
    #|      "target_attr": "env",
    #|      "target_value": "prod"
    #|    }
    #|  }
    #|}

  match parse_json_provider(json_config) {
    None => "Failed to parse JSON configuration"
    Some(provider) => {
      let ctx = context("user-101")
        .with_attr("env", string_value("prod"))
        .with_attr("plan", string_value("enterprise"))

      let eval_bool = evaluate_bool(
        provider,
        "enable_new_ui",
        ctx,
        default=false,
      )
      let eval_str = evaluate_string(
        provider,
        "theme_color",
        ctx,
        default="default-grey",
      )
      let eval_int = evaluate_int(provider, "max_connections", ctx, default=10)

      let bench_result = run_benchmark()

      let output =
        $|========================================
        $|MoonFeatureGate Premium CLI Demo
        $|========================================
        $|[JSON Config Loaded successfully]
        $|
        $|1. Boolean Flag (enable_new_ui):
        $|   Value:  \{eval_bool.value}
        $|   Reason: \{eval_bool.reason}
        $|
        $|2. String Flag (theme_color):
        $|   Value:  \{eval_str.value}
        $|   Reason: \{eval_str.reason}
        $|
        $|3. Integer Flag (max_connections):
        $|   Value:  \{eval_int.value}
        $|   Reason: \{eval_int.reason}
        $|
        $|========================================
        $|Performance Benchmark Status
        $|========================================
        $|\{bench_result}
        $|========================================
      output
    }
  }
}
