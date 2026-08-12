///|
/// A production-shaped fixture set used by the benchmark and acceptance
/// report. These cases represent the kinds of flags a service commonly owns:
/// release gates, experiments, regional policy, safety switches, and capacity
/// controls. They are deterministic and contain no customer data.
pub(all) struct BenchmarkCase {
  name : String
  key : String
  value : FlagValue
  default_value : FlagValue
  rollout_percentage : Int?
  target_attr : String?
  target_value : FlagValue?
} derive(Debug)

///|
pub fn benchmark_cases() -> Array[BenchmarkCase] {
  [
    {
      name: "checkout-ui",
      key: "checkout.new_ui",
      value: BoolValue(true),
      default_value: BoolValue(false),
      rollout_percentage: Some(10000),
      target_attr: None,
      target_value: None,
    },
    {
      name: "recommendation-experiment",
      key: "recommendation.algorithm_v2",
      value: StringValue("ranking-v2"),
      default_value: StringValue("ranking-v1"),
      rollout_percentage: Some(5000),
      target_attr: None,
      target_value: None,
    },
    {
      name: "production-capacity",
      key: "service.max_connections",
      value: IntValue(512),
      default_value: IntValue(128),
      rollout_percentage: None,
      target_attr: Some("environment"),
      target_value: Some(StringValue("production")),
    },
    {
      name: "regional-tax",
      key: "billing.tax_rate",
      value: DoubleValue(0.13),
      default_value: DoubleValue(0.06),
      rollout_percentage: None,
      target_attr: Some("region"),
      target_value: Some(StringValue("cn-east")),
    },
    {
      name: "fraud-protection",
      key: "risk.strict_checks",
      value: BoolValue(true),
      default_value: BoolValue(false),
      rollout_percentage: Some(7500),
      target_attr: None,
      target_value: None,
    },
    {
      name: "cache-ttl",
      key: "cache.ttl_seconds",
      value: IntValue(300),
      default_value: IntValue(60),
      rollout_percentage: None,
      target_attr: Some("plan"),
      target_value: Some(StringValue("pro")),
    },
    {
      name: "search-autocomplete",
      key: "search.autocomplete",
      value: BoolValue(true),
      default_value: BoolValue(false),
      rollout_percentage: Some(2500),
      target_attr: None,
      target_value: None,
    },
    {
      name: "mobile-theme",
      key: "mobile.theme",
      value: StringValue("dark"),
      default_value: StringValue("light"),
      rollout_percentage: None,
      target_attr: Some("platform"),
      target_value: Some(StringValue("mobile")),
    },
    {
      name: "queue-batch-size",
      key: "worker.batch_size",
      value: IntValue(64),
      default_value: IntValue(16),
      rollout_percentage: Some(10000),
      target_attr: None,
      target_value: None,
    },
    {
      name: "observability-level",
      key: "observability.level",
      value: StringValue("detailed"),
      default_value: StringValue("standard"),
      rollout_percentage: None,
      target_attr: Some("environment"),
      target_value: Some(StringValue("staging")),
    },
    {
      name: "image-quality",
      key: "media.image_quality",
      value: IntValue(85),
      default_value: IntValue(70),
      rollout_percentage: Some(6000),
      target_attr: None,
      target_value: None,
    },
    {
      name: "maintenance-mode",
      key: "system.maintenance",
      value: BoolValue(false),
      default_value: BoolValue(false),
      rollout_percentage: None,
      target_attr: None,
      target_value: None,
    },
  ]
}

///|
fn benchmark_provider() -> Provider {
  let mut provider = empty_provider()
  for item in benchmark_cases() {
    match (item.rollout_percentage, item.target_attr, item.target_value) {
      (Some(percentage), _, _) =>
        provider = provider.with_value_rollout(
          item.key,
          item.value,
          percentage~,
        )
      (_, Some(attr), Some(expected)) =>
        provider = provider.with_value_target(
          item.key,
          item.value,
          attr~,
          equals=expected,
        )
      _ => provider = provider.with_value(item.key, item.value)
    }
  }
  provider
}

///|
pub(all) struct BenchmarkReport {
  scenarios : Int
  rounds : Int
  total_requests : Int
  successful_evaluations : Int
  defaulted_evaluations : Int
  type_mismatches : Int
  successful_ratio : Double
} derive(Debug, Eq)

///|
pub fn run_scenario_benchmark() -> BenchmarkReport {
  let cases = benchmark_cases()
  let provider = benchmark_provider()
  let requests = cases.map(item => request(item.key, item.default_value))
  let rounds = 100
  let mut total_requests = 0
  let mut successful_evaluations = 0
  let mut defaulted_evaluations = 0
  let mut type_mismatches = 0
  for round in 0..<rounds {
    let ctx = context("benchmark-user-")
      .with_targeting_key("benchmark-user-" + round.to_string())
      .with_attrs([
        (
          "environment",
          string_value(if round % 2 == 0 { "production" } else { "staging" }),
        ),
        (
          "region",
          string_value(if round % 3 == 0 { "cn-east" } else { "cn-north" }),
        ),
        ("plan", string_value(if round % 4 == 0 { "pro" } else { "free" })),
        (
          "platform",
          string_value(if round % 2 == 0 { "mobile" } else { "web" }),
        ),
      ])
    let result = evaluate_batch(provider, requests, ctx)
    total_requests += result.stats.total
    successful_evaluations += result.stats.successes
    defaulted_evaluations += result.stats.defaults
    type_mismatches += result.stats.type_mismatches
  }
  {
    scenarios: cases.length(),
    rounds,
    total_requests,
    successful_evaluations,
    defaulted_evaluations,
    type_mismatches,
    successful_ratio: successful_evaluations.to_double() /
    total_requests.to_double(),
  }
}
