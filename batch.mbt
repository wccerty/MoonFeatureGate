///|
/// A typed request used by the batch evaluator. The default value also acts as
/// the expected type, so a configuration mistake remains visible instead of
/// being silently converted.
pub(all) struct EvaluationRequest {
  key : String
  default_value : FlagValue
} derive(Debug, Eq)

///|
pub fn request(key : String, default_value : FlagValue) -> EvaluationRequest {
  { key, default_value }
}

///|
pub(all) struct BatchStats {
  mut total : Int
  mut successes : Int
  mut defaults : Int
  mut disabled : Int
  mut target_misses : Int
  mut rollout_misses : Int
  mut type_mismatches : Int
} derive(Debug, Eq)

///|
pub(all) struct BatchResult {
  evaluations : Array[ValueEvaluation]
  stats : BatchStats
  reason_counts : Map[String, Int]
} derive(Debug)

///|
fn same_value_kind(left : FlagValue, right : FlagValue) -> Bool {
  match (left, right) {
    (BoolValue(_), BoolValue(_)) => true
    (StringValue(_), StringValue(_)) => true
    (IntValue(_), IntValue(_)) => true
    (DoubleValue(_), DoubleValue(_)) => true
    _ => false
  }
}

///|
fn[P : FeatureProvider] evaluate_request(
  provider : P,
  item : EvaluationRequest,
  ctx : EvalContext,
) -> ValueEvaluation {
  match provider.get_flag_definition(item.key) {
    Some(flag) if !same_value_kind(flag.value, item.default_value) =>
      { flag_key: item.key, value: item.default_value, reason: "type_mismatch" }
    _ => evaluate_value(provider, item.key, ctx, default=item.default_value)
  }
}

///|
fn record_reason(stats : BatchStats, reason : String) -> Unit {
  stats.total += 1
  match reason {
    "default" => stats.defaults += 1
    "disabled" => stats.disabled += 1
    "target_miss" => stats.target_misses += 1
    "rollout_miss" => stats.rollout_misses += 1
    "type_mismatch" => stats.type_mismatches += 1
    _ => stats.successes += 1
  }
}

///|
pub fn[P : FeatureProvider] evaluate_batch(
  provider : P,
  requests : Array[EvaluationRequest],
  ctx : EvalContext,
) -> BatchResult {
  let evaluations = []
  let stats = {
    total: 0,
    successes: 0,
    defaults: 0,
    disabled: 0,
    target_misses: 0,
    rollout_misses: 0,
    type_mismatches: 0,
  }
  let reasons : Map[String, Int] = Map([])
  for item in requests {
    let evaluation = evaluate_request(provider, item, ctx)
    evaluations.push(evaluation)
    record_reason(stats, evaluation.reason)
    match reasons.get(evaluation.reason) {
      Some(count) => reasons[evaluation.reason] = count + 1
      None => reasons[evaluation.reason] = 1
    }
  }
  { evaluations, stats, reason_counts: reasons }
}

///|
pub fn BatchResult::reason_count(self : BatchResult, reason : String) -> Int {
  self.reason_counts.get_or_default(reason, 0)
}

///|
pub fn BatchResult::summary(self : BatchResult) -> String {
  let parts = []
  for reason, count in self.reason_counts {
    parts.push(reason + "=" + count.to_string())
  }
  self.stats.total.to_string() + " evaluations (" + parts.join(", ") + ")"
}

///|
pub fn BatchResult::has_failures(self : BatchResult) -> Bool {
  self.stats.defaults > 0 || self.stats.type_mismatches > 0
}

///|
pub fn BatchResult::successful_ratio(self : BatchResult) -> Double {
  if self.stats.total == 0 {
    0.0
  } else {
    self.stats.successes.to_double() / self.stats.total.to_double()
  }
}

///|
pub fn ValueEvaluation::is_match(self : ValueEvaluation) -> Bool {
  self.reason == "static" ||
  self.reason == "target_match" ||
  self.reason == "rollout_match"
}

///|
pub fn ValueEvaluation::uses_default(self : ValueEvaluation) -> Bool {
  !self.is_match()
}
