///|
/// A request is the smallest unit of an exposure report. Keeping the default
/// value with the request makes reports useful for detecting accidental fallbacks
/// instead of only counting successful flag reads.
pub(all) struct ExposureRequest {
  key : String
  default_value : FlagValue
} derive(Debug, Eq)

///|
pub fn exposure_request(
  key : String,
  default_value : FlagValue,
) -> ExposureRequest {
  { key, default_value }
}

///|
pub fn ExposureRequest::key(self : ExposureRequest) -> String {
  self.key
}

///|
pub fn ExposureRequest::default_kind(self : ExposureRequest) -> String {
  match self.default_value {
    BoolValue(_) => "bool"
    StringValue(_) => "string"
    IntValue(_) => "int"
    DoubleValue(_) => "double"
  }
}

///|
/// Aggregated observations for one flag over a stable set of request contexts.
/// The counters are mutually informative: `matches + defaults` equals the
/// number of samples, while the reason counters explain the default path.
pub(all) struct ExposureRow {
  key : String
  kind : String
  samples : Int
  matches : Int
  defaults : Int
  target_misses : Int
  rollout_matches : Int
  rollout_misses : Int
  type_mismatches : Int
  disabled : Int
  static_matches : Int
} derive(Debug, Eq)

///|
fn new_exposure_row(request : ExposureRequest) -> ExposureRow {
  {
    key: request.key,
    kind: request.default_kind(),
    samples: 0,
    matches: 0,
    defaults: 0,
    target_misses: 0,
    rollout_matches: 0,
    rollout_misses: 0,
    type_mismatches: 0,
    disabled: 0,
    static_matches: 0,
  }
}

///|
pub fn ExposureRow::matched_ratio(self : ExposureRow) -> Double {
  if self.samples == 0 {
    0.0
  } else {
    self.matches.to_double() / self.samples.to_double()
  }
}

///|
pub fn ExposureRow::default_ratio(self : ExposureRow) -> Double {
  if self.samples == 0 {
    0.0
  } else {
    self.defaults.to_double() / self.samples.to_double()
  }
}

///|
pub fn ExposureRow::reason_count(self : ExposureRow, reason : String) -> Int {
  match reason {
    "target_miss" => self.target_misses
    "rollout_match" => self.rollout_matches
    "rollout_miss" => self.rollout_misses
    "type_mismatch" => self.type_mismatches
    "disabled" => self.disabled
    "static" => self.static_matches
    _ => 0
  }
}

///|
pub fn ExposureRow::is_consistent(self : ExposureRow) -> Bool {
  self.samples == self.matches + self.defaults &&
  self.samples ==
  self.target_misses +
  self.rollout_matches +
  self.rollout_misses +
  self.type_mismatches +
  self.disabled +
  self.static_matches
}

///|
pub fn ExposureRow::has_default_path(self : ExposureRow) -> Bool {
  self.defaults > 0
}

///|
pub fn ExposureRow::has_target_misses(self : ExposureRow) -> Bool {
  self.target_misses > 0
}

///|
pub fn ExposureRow::summary(self : ExposureRow) -> String {
  self.key +
  " [" +
  self.kind +
  "] samples=" +
  self.samples.to_string() +
  ", matches=" +
  self.matches.to_string() +
  ", defaults=" +
  self.defaults.to_string() +
  ", target_miss=" +
  self.target_misses.to_string() +
  ", rollout=" +
  self.rollout_matches.to_string() +
  "/" +
  self.rollout_misses.to_string()
}

///|
pub(all) struct ExposureReport {
  rows : Map[String, ExposureRow]
  samples : Int
  requests : Int
} derive(Debug)

///|
fn exposure_record_reason(row : ExposureRow, reason : String) -> ExposureRow {
  match reason {
    "target_miss" => { ..row, target_misses: row.target_misses + 1 }
    "rollout_match" =>
      {
        ..row,
        matches: row.matches + 1,
        rollout_matches: row.rollout_matches + 1,
      }
    "rollout_miss" =>
      {
        ..row,
        defaults: row.defaults + 1,
        rollout_misses: row.rollout_misses + 1,
      }
    "type_mismatch" =>
      {
        ..row,
        defaults: row.defaults + 1,
        type_mismatches: row.type_mismatches + 1,
      }
    "disabled" =>
      { ..row, defaults: row.defaults + 1, disabled: row.disabled + 1 }
    "static" | "target_match" =>
      {
        ..row,
        matches: row.matches + 1,
        static_matches: row.static_matches + 1,
      }
    _ => { ..row, defaults: row.defaults + 1 }
  }
}

///|
fn exposure_evaluate_request(
  provider : Provider,
  request : ExposureRequest,
  ctx : EvalContext,
) -> String {
  evaluate_value(provider, request.key, ctx, default=request.default_value).reason
}

///|
/// Analyzes every request/context pair. The evaluator remains the single source
/// of truth, so the report cannot silently diverge from normal application
/// behavior.
pub fn analyze_exposure(
  provider : Provider,
  requests : Array[ExposureRequest],
  contexts : Array[EvalContext],
) -> ExposureReport {
  let rows : Map[String, ExposureRow] = Map([])
  for request in requests {
    let mut row = new_exposure_row(request)
    for ctx in contexts {
      let reason = exposure_evaluate_request(provider, request, ctx)
      row = exposure_record_reason(row, reason)
    }
    rows[request.key] = row
  }
  { rows, samples: contexts.length(), requests: requests.length() }
}

///|
pub fn ExposureReport::row(self : ExposureReport, key : String) -> ExposureRow? {
  self.rows.get(key)
}

///|
pub fn ExposureReport::keys(self : ExposureReport) -> Array[String] {
  let keys = []
  for key in self.rows.keys() {
    keys.push(key)
  }
  keys.sort()
  keys
}

///|
pub fn ExposureReport::sample_count(self : ExposureReport) -> Int {
  self.samples
}

///|
pub fn ExposureReport::request_count(self : ExposureReport) -> Int {
  self.requests
}

///|
pub fn ExposureReport::evaluation_count(self : ExposureReport) -> Int {
  self.samples * self.requests
}

///|
pub fn ExposureReport::default_count(self : ExposureReport) -> Int {
  let mut count = 0
  for _, row in self.rows {
    count += row.defaults
  }
  count
}

///|
pub fn ExposureReport::match_count(self : ExposureReport) -> Int {
  let mut count = 0
  for _, row in self.rows {
    count += row.matches
  }
  count
}

///|
pub fn ExposureReport::default_ratio(self : ExposureReport) -> Double {
  let total = self.evaluation_count()
  if total == 0 {
    0.0
  } else {
    self.default_count().to_double() / total.to_double()
  }
}

///|
pub fn ExposureReport::has_anomalies(self : ExposureReport) -> Bool {
  for _, row in self.rows {
    if row.target_misses > 0 || row.type_mismatches > 0 || !row.is_consistent() {
      return true
    }
  }
  false
}

///|
pub fn ExposureReport::inconsistent_rows(
  self : ExposureReport,
) -> Array[String] {
  let result = []
  for key, row in self.rows {
    if !row.is_consistent() {
      result.push(key)
    }
  }
  result.sort()
  result
}

///|
pub fn ExposureReport::rows_with_defaults(
  self : ExposureReport,
) -> Array[String] {
  let result = []
  for key, row in self.rows {
    if row.has_default_path() {
      result.push(key)
    }
  }
  result.sort()
  result
}

///|
pub fn ExposureReport::render(self : ExposureReport) -> String {
  let lines = [
    "exposure samples=" +
    self.samples.to_string() +
    ", requests=" +
    self.requests.to_string() +
    ", evaluations=" +
    self.evaluation_count().to_string(),
    "matches=" +
    self.match_count().to_string() +
    ", defaults=" +
    self.default_count().to_string() +
    ", anomalies=" +
    self.has_anomalies().to_string(),
  ]
  for key in self.keys() {
    lines.push("- " + self.rows[key].summary())
  }
  lines.join("\n")
}

///|
pub fn ExposureReport::rows_for_prefix(
  self : ExposureReport,
  prefix : String,
) -> Array[ExposureRow] {
  let result = []
  for key in self.keys() {
    if key.has_prefix(prefix) {
      result.push(self.rows[key])
    }
  }
  result
}

///|
pub fn ExposureReport::coverage_percent(self : ExposureReport) -> Double {
  if self.requests == 0 {
    0.0
  } else {
    self.rows.length().to_double() * 100.0 / self.requests.to_double()
  }
}

///|
pub(all) struct ExposureAssessment {
  passed : Bool
  default_ratio : Double
  anomalous_rows : Array[String]
  inconsistent_rows : Array[String]
  message : String
} derive(Debug)

///|
pub fn ExposureReport::assess(
  self : ExposureReport,
  threshold : ExposureThreshold,
) -> ExposureAssessment {
  let anomalous = self.rows_with_target_misses()
  let type_errors = self.rows_with_type_mismatches()
  for key in type_errors {
    if !anomalous.contains(key) {
      anomalous.push(key)
    }
  }
  anomalous.sort()
  let inconsistent = self.inconsistent_rows()
  let passed = self.passes(threshold)
  let message = if passed {
    "exposure report passes configured threshold"
  } else if inconsistent.length() > 0 {
    "exposure report contains inconsistent counters"
  } else if anomalous.length() > 0 {
    "exposure report contains fallback or targeting anomalies"
  } else {
    "default exposure ratio exceeds threshold"
  }
  {
    passed,
    default_ratio: self.default_ratio(),
    anomalous_rows: anomalous,
    inconsistent_rows: inconsistent,
    message,
  }
}

///|
pub fn ExposureAssessment::summary(self : ExposureAssessment) -> String {
  (if self.passed { "passed" } else { "failed" }) +
  ": default_ratio=" +
  self.default_ratio.to_string() +
  ", anomalies=" +
  self.anomalous_rows.length().to_string() +
  ", inconsistent=" +
  self.inconsistent_rows.length().to_string() +
  "; " +
  self.message
}

///|
pub fn ExposureAssessment::is_actionable(self : ExposureAssessment) -> Bool {
  !self.passed &&
  (self.anomalous_rows.length() > 0 || self.inconsistent_rows.length() > 0)
}

///|
pub fn ExposureReport::empty() -> ExposureReport {
  { rows: Map([]), samples: 0, requests: 0 }
}

///|
/// Produces a human-actionable next step instead of exposing raw counters to
/// an operator who has to interpret them during a release window.
pub fn ExposureReport::recommendation(self : ExposureReport) -> String {
  if self.samples == 0 || self.requests == 0 {
    "collect a representative sample before release"
  } else if self.inconsistent_rows().length() > 0 {
    "fix inconsistent exposure counters before review"
  } else if self.rows_with_type_mismatches().length() > 0 {
    "review flag types and caller defaults before release"
  } else if self.rows_with_target_misses().length() > 0 {
    "review targeting attributes and fallback behavior"
  } else if self.default_ratio() > 0.0 {
    "review default exposure and confirm the intended rollout"
  } else {
    "exposure sample is healthy for the configured checks"
  }
}

///|
pub fn ExposureReport::reason_totals(self : ExposureReport) -> Map[String, Int] {
  let totals : Map[String, Int] = Map([])
  for _, row in self.rows {
    for
      reason in [
        "target_miss", "rollout_match", "rollout_miss", "type_mismatch", "disabled",
        "static",
      ] {
      let count = row.reason_count(reason)
      if count > 0 {
        totals[reason] = totals.get(reason).unwrap_or(0) + count
      }
    }
  }
  totals
}

///|
pub fn ExposureReport::is_representative(
  self : ExposureReport,
  minimum~ : Int,
) -> Bool {
  minimum >= 0 && self.samples >= minimum && self.requests > 0
}

///|
pub fn ExposureReport::healthy_for_release(self : ExposureReport) -> Bool {
  self.samples > 0 &&
  self.requests > 0 &&
  !self.has_anomalies() &&
  self.default_ratio() == 0.0
}

///|
pub fn ExposureReport::rollout_rows(
  self : ExposureReport,
) -> Array[ExposureRow] {
  let result = []
  for _, row in self.rows {
    if row.rollout_matches > 0 || row.rollout_misses > 0 {
      result.push(row)
    }
  }
  result
}

///|
pub fn ExposureReport::rollout_match_ratio(self : ExposureReport) -> Double {
  let mut rollout = 0
  let mut matched = 0
  for row in self.rollout_rows() {
    rollout += row.rollout_matches + row.rollout_misses
    matched += row.rollout_matches
  }
  if rollout == 0 {
    0.0
  } else {
    matched.to_double() / rollout.to_double()
  }
}

///|
/// A stable, compact signature is useful for comparing two canary samples in
/// logs without serializing every context or flag value.
pub fn ExposureReport::compact_signature(self : ExposureReport) -> String {
  let parts = [
    "samples=" + self.samples.to_string(),
    "requests=" + self.requests.to_string(),
    "defaults=" + self.default_count().to_string(),
  ]
  for key in self.keys() {
    let row = self.rows[key]
    parts.push(
      key + ":" + row.matches.to_string() + "/" + row.samples.to_string(),
    )
  }
  parts.join("|")
}

///|
pub fn ExposureReport::same_shape(
  self : ExposureReport,
  other : ExposureReport,
) -> Bool {
  self.keys() == other.keys() && self.requests == other.requests
}

///|
pub fn ExposureReport::difference(
  self : ExposureReport,
  other : ExposureReport,
) -> Array[String] {
  let differences = []
  for key in self.keys() {
    match other.row(key) {
      Some(right) => {
        let left = self.rows[key]
        if left.matches != right.matches || left.defaults != right.defaults {
          differences.push(key)
        }
      }
      None => differences.push(key)
    }
  }
  for key in other.keys() {
    if !self.rows.contains(key) {
      differences.push(key)
    }
  }
  differences.sort()
  differences
}

///|
pub fn ExposureReport::kind_summary(self : ExposureReport) -> String {
  let kinds : Map[String, Int] = Map([])
  for _, row in self.rows {
    kinds[row.kind] = kinds.get(row.kind).unwrap_or(0) + 1
  }
  let names = []
  for kind in kinds.keys() {
    names.push(kind + "=" + kinds[kind].to_string())
  }
  names.sort()
  names.join(", ")
}

///|
pub fn ExposureReport::targeting_miss_rate(self : ExposureReport) -> Double {
  let mut misses = 0
  for _, row in self.rows {
    misses += row.target_misses
  }
  let total = self.evaluation_count()
  if total == 0 {
    0.0
  } else {
    misses.to_double() / total.to_double()
  }
}

///|
pub fn ExposureReport::has_requested_key(
  self : ExposureReport,
  key : String,
) -> Bool {
  self.rows.contains(key)
}

///|
pub fn ExposureReport::empty_rows(self : ExposureReport) -> Array[String] {
  let result = []
  for key, row in self.rows {
    if row.samples == 0 {
      result.push(key)
    }
  }
  result.sort()
  result
}

///|
pub fn ExposureReport::quality_score(self : ExposureReport) -> Int {
  if self.evaluation_count() == 0 {
    0
  } else {
    let score = 100
    let score = if self.targeting_miss_rate() > 0.0 {
      score - 20
    } else {
      score
    }
    let score = if self.default_ratio() > 0.0 { score - 20 } else { score }
    if self.inconsistent_rows().length() > 0 {
      score - 60
    } else {
      score
    }
  }
}

///|
pub fn ExposureReport::merge(
  self : ExposureReport,
  other : ExposureReport,
) -> ExposureReport {
  let merged = self.rows.copy()
  for key, right in other.rows {
    match merged.get(key) {
      Some(left) =>
        merged[key] = {
          ..left,
          samples: left.samples + right.samples,
          matches: left.matches + right.matches,
          defaults: left.defaults + right.defaults,
          target_misses: left.target_misses + right.target_misses,
          rollout_matches: left.rollout_matches + right.rollout_matches,
          rollout_misses: left.rollout_misses + right.rollout_misses,
          type_mismatches: left.type_mismatches + right.type_mismatches,
          disabled: left.disabled + right.disabled,
          static_matches: left.static_matches + right.static_matches,
        }
      None => merged[key] = right
    }
  }
  {
    rows: merged,
    samples: self.samples + other.samples,
    requests: self.requests + other.requests,
  }
}

///|
/// A threshold turns raw exposure data into a deployable gate. It is useful in
/// CI and can also be applied to a canary sample before a production switch.
pub(all) struct ExposureThreshold {
  max_default_ratio : Double
  reject_target_misses : Bool
  reject_type_mismatches : Bool
} derive(Debug, Eq)

///|
pub fn safe_exposure_threshold() -> ExposureThreshold {
  {
    max_default_ratio: 0.0,
    reject_target_misses: true,
    reject_type_mismatches: true,
  }
}

///|
pub fn permissive_exposure_threshold() -> ExposureThreshold {
  {
    max_default_ratio: 1.0,
    reject_target_misses: false,
    reject_type_mismatches: false,
  }
}

///|
pub fn ExposureReport::passes(
  self : ExposureReport,
  threshold : ExposureThreshold,
) -> Bool {
  self.default_ratio() <= threshold.max_default_ratio &&
  (
    !threshold.reject_target_misses ||
    self.rows_with_target_misses().length() == 0
  ) &&
  (
    !threshold.reject_type_mismatches ||
    self.rows_with_type_mismatches().length() == 0
  ) &&
  self.inconsistent_rows().length() == 0
}

///|
pub fn ExposureReport::rows_with_target_misses(
  self : ExposureReport,
) -> Array[String] {
  let result = []
  for key, row in self.rows {
    if row.target_misses > 0 {
      result.push(key)
    }
  }
  result.sort()
  result
}

///|
pub fn ExposureReport::rows_with_type_mismatches(
  self : ExposureReport,
) -> Array[String] {
  let result = []
  for key, row in self.rows {
    if row.type_mismatches > 0 {
      result.push(key)
    }
  }
  result.sort()
  result
}
