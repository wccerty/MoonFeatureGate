///|
test "demo output explains a rollout decision" {
  inspect(
    @moonfeaturegate.demo_output(),
    content=(
      #|MoonFeatureGate demo
      #|flag=new_checkout
      #|user=user-42
      #|value=true
      #|reason=rollout_match
      #|
    ),
  )
}
