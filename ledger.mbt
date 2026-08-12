///|
/// A small in-process decision ledger for tests, demos, and service health
/// dashboards. It stores aggregate counters only; no user identifiers are
/// retained, which keeps the default implementation privacy-friendly.
pub(all) struct DecisionLedger {
  mut total : Int
  mut matches : Int
  mut defaults : Int
  mut disabled : Int
  mut target_misses : Int
  mut rollout_misses : Int
  mut type_mismatches : Int
  mut reason_counts : Map[String, Int]
} derive(Debug)

///|
pub fn new_ledger() -> DecisionLedger {
  {
    total: 0,
    matches: 0,
    defaults: 0,
    disabled: 0,
    target_misses: 0,
    rollout_misses: 0,
    type_mismatches: 0,
    reason_counts: Map([]),
  }
}

///|
pub fn DecisionLedger::record(
  self : DecisionLedger,
  evaluation : ValueEvaluation,
) -> Unit {
  self.total += 1
  if evaluation.is_match() {
    self.matches += 1
  }
  match evaluation.reason {
    "default" => self.defaults += 1
    "disabled" => self.disabled += 1
    "target_miss" => self.target_misses += 1
    "rollout_miss" => self.rollout_misses += 1
    "type_mismatch" => self.type_mismatches += 1
    _ => ()
  }
  match self.reason_counts.get(evaluation.reason) {
    Some(count) => self.reason_counts[evaluation.reason] = count + 1
    None => self.reason_counts[evaluation.reason] = 1
  }
}

///|
pub fn DecisionLedger::record_batch(
  self : DecisionLedger,
  result : BatchResult,
) -> Unit {
  for evaluation in result.evaluations {
    self.record(evaluation)
  }
}

///|
pub fn DecisionLedger::merge(
  self : DecisionLedger,
  other : DecisionLedger,
) -> Unit {
  self.total += other.total
  self.matches += other.matches
  self.defaults += other.defaults
  self.disabled += other.disabled
  self.target_misses += other.target_misses
  self.rollout_misses += other.rollout_misses
  self.type_mismatches += other.type_mismatches
  for reason, count in other.reason_counts {
    match self.reason_counts.get(reason) {
      Some(previous) => self.reason_counts[reason] = previous + count
      None => self.reason_counts[reason] = count
    }
  }
}

///|
pub fn DecisionLedger::count(self : DecisionLedger, reason : String) -> Int {
  self.reason_counts.get_or_default(reason, 0)
}

///|
pub fn DecisionLedger::success_ratio(self : DecisionLedger) -> Double {
  if self.total == 0 {
    0.0
  } else {
    self.matches.to_double() / self.total.to_double()
  }
}

///|
pub fn DecisionLedger::reset(self : DecisionLedger) -> Unit {
  self.total = 0
  self.matches = 0
  self.defaults = 0
  self.disabled = 0
  self.target_misses = 0
  self.rollout_misses = 0
  self.type_mismatches = 0
  self.reason_counts.clear()
}

///|
pub fn DecisionLedger::summary(self : DecisionLedger) -> String {
  "decisions=" +
  self.total.to_string() +
  ", matches=" +
  self.matches.to_string() +
  ", defaults=" +
  self.defaults.to_string() +
  ", disabled=" +
  self.disabled.to_string() +
  ", target_miss=" +
  self.target_misses.to_string() +
  ", rollout_miss=" +
  self.rollout_misses.to_string() +
  ", type_mismatch=" +
  self.type_mismatches.to_string()
}

///|
pub fn DecisionLedger::reason_report(self : DecisionLedger) -> String {
  let keys = []
  for key in self.reason_counts.keys() {
    keys.push(key)
  }
  keys.sort()
  let lines = []
  for key in keys {
    lines.push(key + "=" + self.count(key).to_string())
  }
  lines.join(", ")
}

///|
pub fn[P : FeatureProvider] evaluate_with_ledger(
  provider : P,
  requests : Array[EvaluationRequest],
  ctx : EvalContext,
  ledger : DecisionLedger,
) -> BatchResult {
  let result = evaluate_batch(provider, requests, ctx)
  ledger.record_batch(result)
  result
}
