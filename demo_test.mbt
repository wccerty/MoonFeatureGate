///|
test "demo output explains a rollout decision" {
  inspect(
    @moonfeaturegate.demo_output(),
    content=(
      #|========================================
      #|MoonFeatureGate Premium CLI Demo
      #|========================================
      #|[JSON Config Loaded successfully]
      #|
      #|1. Boolean Flag (enable_new_ui):
      #|   Value:  true
      #|   Reason: rollout_match
      #|
      #|2. String Flag (theme_color):
      #|   Value:  ocean-blue
      #|   Reason: static
      #|
      #|3. Integer Flag (max_connections):
      #|   Value:  128
      #|   Reason: target_match
      #|
      #|========================================
      #|Performance Benchmark Status
      #|========================================
      #|Completed 100000 iterations of multi-type evaluation successfully.
      #|========================================
    ),
  )
}
