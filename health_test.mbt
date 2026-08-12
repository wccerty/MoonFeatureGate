///|
test "provider health combines audit policy and inventory" {
  let provider = empty_provider().with_bool("release.ui", true)
  let health = provider.health_check(ProviderPolicy::production())
  assert_true(health.is_ready())
  inspect(health.status_text(), content="healthy")
  assert_true(health.summary().contains("flags=1"))
  assert_true(health.render().contains("provider is ready"))
}
