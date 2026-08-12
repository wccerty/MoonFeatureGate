///|
/// A scenario is a deterministic set of contexts and typed requests. It makes
/// it possible to replay release decisions in CI, compare two configurations,
/// and publish benchmark evidence without connecting to a remote service.
pub(all) struct EvaluationScenario {
  name : String
  requests : Array[EvaluationRequest]
  contexts : Array[EvalContext]
} derive(Debug)

///|
pub fn scenario(
  name : String,
  requests : Array[EvaluationRequest],
  contexts : Array[EvalContext],
) -> EvaluationScenario {
  { name, requests, contexts }
}

///|
pub(all) struct ScenarioReport {
  name : String
  contexts : Int
  requests_per_context : Int
  total : Int
  matches : Int
  defaults : Int
  disabled : Int
  target_misses : Int
  rollout_misses : Int
  type_mismatches : Int
  ledger : DecisionLedger
} derive(Debug)

///|
pub fn[P : FeatureProvider] EvaluationScenario::run(
  self : EvaluationScenario,
  provider : P,
) -> ScenarioReport {
  let ledger = new_ledger()
  for ctx in self.contexts {
    let _ = evaluate_with_ledger(provider, self.requests, ctx, ledger)
  }
  {
    name: self.name,
    contexts: self.contexts.length(),
    requests_per_context: self.requests.length(),
    total: ledger.total,
    matches: ledger.matches,
    defaults: ledger.defaults,
    disabled: ledger.disabled,
    target_misses: ledger.target_misses,
    rollout_misses: ledger.rollout_misses,
    type_mismatches: ledger.type_mismatches,
    ledger,
  }
}

///|
pub fn ScenarioReport::success_ratio(self : ScenarioReport) -> Double {
  self.ledger.success_ratio()
}

///|
pub fn ScenarioReport::summary(self : ScenarioReport) -> String {
  self.name +
  ": contexts=" +
  self.contexts.to_string() +
  ", requests=" +
  self.total.to_string() +
  ", matches=" +
  self.matches.to_string() +
  ", defaults=" +
  self.defaults.to_string() +
  ", ratio=" +
  self.success_ratio().to_string()
}

///|
pub fn ScenarioReport::is_reproducible(self : ScenarioReport) -> Bool {
  self.total == self.contexts * self.requests_per_context
}

///|
pub fn acceptance_scenario() -> EvaluationScenario {
  let cases = benchmark_cases()
  let requests = cases.map(item => request(item.key, item.default_value))
  let contexts = [
    context("acceptance-prod-pro").with_attrs([
      ("environment", string_value("production")),
      ("region", string_value("cn-east")),
      ("plan", string_value("pro")),
      ("platform", string_value("mobile")),
    ]),
    context("acceptance-staging-free").with_attrs([
      ("environment", string_value("staging")),
      ("region", string_value("cn-north")),
      ("plan", string_value("free")),
      ("platform", string_value("web")),
    ]),
    context("acceptance-prod-free").with_attrs([
      ("environment", string_value("production")),
      ("region", string_value("cn-east")),
      ("plan", string_value("free")),
      ("platform", string_value("web")),
    ]),
    context("acceptance-staging-pro").with_attrs([
      ("environment", string_value("staging")),
      ("region", string_value("cn-north")),
      ("plan", string_value("pro")),
      ("platform", string_value("mobile")),
    ]),
  ]
  scenario("OSC2026 acceptance matrix", requests, contexts)
}

///|
pub fn run_acceptance_scenario() -> ScenarioReport {
  acceptance_scenario().run(
    benchmark_cases().fold(init=empty_provider(), (provider, item) => {
      match (item.rollout_percentage, item.target_attr, item.target_value) {
        (Some(percentage), _, _) =>
          provider.with_value_rollout(item.key, item.value, percentage~)
        (_, Some(attr), Some(expected)) =>
          provider.with_value_target(
            item.key,
            item.value,
            attr~,
            equals=expected,
          )
        _ => provider.with_value(item.key, item.value)
      }
    }),
  )
}
