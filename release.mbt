///|
/// Environments describe the operational blast radius of a configuration
/// change. They are deliberately independent from a deployment platform so
/// the same plan can be reviewed locally, in CI, or by a service launcher.
pub(all) enum ReleaseEnvironment {
  Development
  Staging
  Canary
  Production
} derive(Debug, Eq)

///|
pub fn ReleaseEnvironment::name(self : ReleaseEnvironment) -> String {
  match self {
    Development => "development"
    Staging => "staging"
    Canary => "canary"
    Production => "production"
  }
}

///|
pub fn ReleaseEnvironment::requires_approval(self : ReleaseEnvironment) -> Bool {
  self is (Canary | Production)
}

///|
pub fn ReleaseEnvironment::maximum_risk(
  self : ReleaseEnvironment,
) -> ReleaseRisk {
  match self {
    Development => Medium
    Staging => Medium
    Canary => High
    Production => Critical
  }
}

///|
pub(all) enum ReleaseRisk {
  Low
  Medium
  High
  Critical
} derive(Debug, Eq)

///|
pub fn ReleaseRisk::name(self : ReleaseRisk) -> String {
  match self {
    Low => "low"
    Medium => "medium"
    High => "high"
    Critical => "critical"
  }
}

///|
pub fn ReleaseRisk::rank(self : ReleaseRisk) -> Int {
  match self {
    Low => 0
    Medium => 1
    High => 2
    Critical => 3
  }
}

///|
pub fn ReleaseRisk::at_least(self : ReleaseRisk, other : ReleaseRisk) -> Bool {
  self.rank() >= other.rank()
}

///|
pub(all) enum ReleaseApproval {
  Pending
  Approved(reviewer~ : String)
  Rejected(reviewer~ : String, reason~ : String)
} derive(Debug, Eq)

///|
pub fn ReleaseApproval::is_approved(self : ReleaseApproval) -> Bool {
  self is Approved(_)
}

///|
pub fn ReleaseApproval::label(self : ReleaseApproval) -> String {
  match self {
    Pending => "pending"
    Approved(reviewer~) => "approved by " + reviewer
    Rejected(reviewer~, reason~) => "rejected by " + reviewer + ": " + reason
  }
}

///|
/// A small, deterministic record for explaining why a release was classified
/// as risky. The message is intentionally short enough for CI annotations.
pub(all) struct ReleaseChange {
  key : String
  kind : String
  risk : ReleaseRisk
  message : String
} derive(Debug, Eq)

///|
pub fn ReleaseChange::summary(self : ReleaseChange) -> String {
  self.risk.name() + " [" + self.kind + "] " + self.key + ": " + self.message
}

///|
pub(all) struct ReleaseMetadata {
  owner : String
  change_ticket : String
  environment : ReleaseEnvironment
} derive(Debug, Eq)

///|
pub fn release_metadata(
  owner : String,
  change_ticket : String,
  environment : ReleaseEnvironment,
) -> ReleaseMetadata {
  { owner, change_ticket, environment }
}

///|
pub fn ReleaseMetadata::errors(self : ReleaseMetadata) -> Array[String] {
  let errors = []
  if self.owner.trim() == "" {
    errors.push("owner_required")
  }
  if self.change_ticket.trim() == "" {
    errors.push("change_ticket_required")
  }
  errors
}

///|
pub(all) struct ReleasePlan {
  metadata : ReleaseMetadata
  next : Provider
  previous : Provider?
  health : ProviderHealth
  compatibility : CompatibilityReport?
  changes : Array[ReleaseChange]
  risk : ReleaseRisk
  approval : ReleaseApproval
  allowed : Bool
} derive(Debug)

///|
fn change_risk(environment : ReleaseEnvironment, kind : String) -> ReleaseRisk {
  let base = match kind {
    "added" => Low
    "changed" => High
    "removed" => Critical
    _ => Medium
  }
  if environment is Production && base is Low {
    Medium
  } else {
    base
  }
}

///|
fn changes_from_report(
  report : CompatibilityReport,
  environment : ReleaseEnvironment,
) -> Array[ReleaseChange] {
  let result = []
  for key in report.diff.added {
    result.push({
      key,
      kind: "added",
      risk: change_risk(environment, "added"),
      message: "new flag is introduced",
    })
  }
  for key in report.diff.changed {
    result.push({
      key,
      kind: "changed",
      risk: change_risk(environment, "changed"),
      message: "existing flag definition changes",
    })
  }
  for key in report.diff.removed {
    result.push({
      key,
      kind: "removed",
      risk: change_risk(environment, "removed"),
      message: "existing flag is removed",
    })
  }
  result
}

///|
fn highest_risk(
  environment : ReleaseEnvironment,
  health : ProviderHealth,
  changes : Array[ReleaseChange],
  metadata_errors : Array[String],
) -> ReleaseRisk {
  let mut risk = Low
  if health.status_text() == "warning" {
    risk = Medium
  }
  if !health.is_ready() {
    risk = Critical
  }
  for change in changes {
    if change.risk.at_least(risk) {
      risk = change.risk
    }
  }
  if metadata_errors.length() > 0 {
    risk = Critical
  }
  if environment is Production && risk is Low {
    Medium
  } else {
    risk
  }
}

///|
/// Builds a reviewable release plan. The function does not activate anything;
/// callers must explicitly approve the returned plan and perform activation.
pub fn plan_release(
  previous : Provider?,
  next : Provider,
  environment~ : ReleaseEnvironment,
  policy~ : ProviderPolicy,
  owner~ : String,
  change_ticket~ : String,
) -> ReleasePlan {
  let metadata = release_metadata(owner, change_ticket, environment)
  let health = next.health_check(policy)
  let compatibility = previous.map(old => compare_providers(old, next))
  let changes = match compatibility {
    Some(report) => changes_from_report(report, environment)
    None =>
      next
      .definitions()
      .map(flag => {
        key: flag.key,
        kind: "initial",
        risk: change_risk(environment, "changed"),
        message: "initial provider configuration",
      })
  }
  let risk = highest_risk(environment, health, changes, metadata.errors())
  let blocked_by_compatibility = match compatibility {
    Some(report) => report.requires_replay()
    None => false
  }
  let allowed = health.is_ready() &&
    health.policy.is_compliant() &&
    !blocked_by_compatibility &&
    metadata.errors().length() == 0
  let approval = if allowed && !environment.requires_approval() && risk is Low {
    Approved(reviewer="automatic")
  } else {
    Pending
  }
  {
    metadata,
    next,
    previous,
    health,
    compatibility,
    changes,
    risk,
    approval,
    allowed,
  }
}

///|
pub fn ReleasePlan::metadata_errors(self : ReleasePlan) -> Array[String] {
  self.metadata.errors()
}

///|
pub fn ReleasePlan::risk(self : ReleasePlan) -> ReleaseRisk {
  self.risk
}

///|
pub fn ReleasePlan::environment(self : ReleasePlan) -> ReleaseEnvironment {
  self.metadata.environment
}

///|
pub fn ReleasePlan::changes(self : ReleasePlan) -> Array[ReleaseChange] {
  self.changes
}

///|
pub fn ReleasePlan::is_approved(self : ReleasePlan) -> Bool {
  self.approval.is_approved()
}

///|
pub fn ReleasePlan::requires_manual_approval(self : ReleasePlan) -> Bool {
  !self.allowed ||
  self.risk.at_least(self.metadata.environment.maximum_risk()) ||
  !self.approval.is_approved()
}

///|
pub fn ReleasePlan::approve(
  self : ReleasePlan,
  reviewer : String,
) -> ReleasePlan {
  if reviewer.trim() == "" || !self.allowed {
    self
  } else {
    { ..self, approval: Approved(reviewer~) }
  }
}

///|
pub fn ReleasePlan::reject(
  self : ReleasePlan,
  reviewer : String,
  reason : String,
) -> ReleasePlan {
  { ..self, approval: Rejected(reviewer~, reason~), allowed: false }
}

///|
pub fn ReleasePlan::is_release_ready(self : ReleasePlan) -> Bool {
  self.allowed &&
  self.approval.is_approved() &&
  self.metadata_errors().length() == 0
}

///|
pub fn ReleasePlan::rollback(self : ReleasePlan) -> Array[String] {
  match self.previous {
    Some(old) =>
      [
        "restore provider fingerprint " + old.fingerprint(),
        "replay acceptance scenarios before reactivation",
        "record rollback ticket " + self.metadata.change_ticket,
      ]
    None =>
      [
        "disable newly introduced flags",
        "keep the current provider available for incident review",
        "record rollback ticket " + self.metadata.change_ticket,
      ]
  }
}

///|
pub fn ReleasePlan::summary(self : ReleasePlan) -> String {
  let state = if self.is_release_ready() { "ready" } else { "blocked" }
  state +
  " " +
  self.metadata.environment.name() +
  " release; risk=" +
  self.risk.name() +
  ", changes=" +
  self.changes.length().to_string() +
  ", approval=" +
  self.approval.label()
}

///|
pub fn ReleasePlan::render(self : ReleasePlan) -> String {
  let lines = [
    self.summary(),
    "owner=" + self.metadata.owner + ", ticket=" + self.metadata.change_ticket,
    "health=" + self.health.status_text(),
  ]
  match self.compatibility {
    Some(report) => lines.push("compatibility=" + report.summary())
    None => lines.push("compatibility=initial release")
  }
  for change in self.changes {
    lines.push("- " + change.summary())
  }
  lines.push("rollback:")
  for step in self.rollback() {
    lines.push("  - " + step)
  }
  lines.join("\n")
}

///|
pub fn ReleasePlan::decision(self : ReleasePlan) -> DeploymentDecision {
  deployment_check(self.previous, self.next, default_policy())
}

///|
pub fn ReleasePlan::approval_label(self : ReleasePlan) -> String {
  self.approval.label()
}

///|
pub fn ReleasePlan::change_count(self : ReleasePlan) -> Int {
  self.changes.length()
}

///|
pub fn ReleasePlan::risk_explanation(self : ReleasePlan) -> String {
  if self.changes.length() == 0 {
    "no flag changes; risk comes from the release environment"
  } else {
    let reasons = []
    for change in self.changes {
      reasons.push(change.kind + " " + change.key)
    }
    "risk is driven by " + reasons.join(", ")
  }
}

///|
/// Returns operator-facing steps without performing them. This is suitable for
/// a change ticket or a deployment bot's dry-run output.
pub fn ReleasePlan::approval_steps(self : ReleasePlan) -> Array[String] {
  let steps = [
    "review provider health and policy report", "review compatibility changes and acceptance replay",
  ]
  if self.environment().requires_approval() {
    steps.push("obtain explicit approval for " + self.environment().name())
  }
  if self.risk.at_least(High) {
    steps.push("confirm rollback owner and rollback ticket")
  }
  steps
}

///|
pub fn ReleasePlan::has_breaking_change(self : ReleasePlan) -> Bool {
  for change in self.changes {
    if change.kind == "removed" {
      return true
    }
  }
  false
}

///|
pub fn ReleasePlan::changed_keys(self : ReleasePlan) -> Array[String] {
  let keys = []
  for change in self.changes {
    keys.push(change.key)
  }
  keys.sort()
  keys
}

///|
pub fn ReleasePlan::audit_ready(self : ReleasePlan) -> Bool {
  self.metadata_errors().length() == 0 &&
  self.health.is_ready() &&
  self.changes.length() >= 0
}

///|
pub fn ReleasePlan::risk_score(self : ReleasePlan) -> Int {
  10 +
  self.risk.rank() * 25 +
  (if self.has_breaking_change() { 25 } else { 0 }) +
  (if self.metadata_errors().length() > 0 { 50 } else { 0 })
}

///|
pub fn ReleasePlan::guardrails(self : ReleasePlan) -> Array[String] {
  let guards = [
    "run moon check and moon test before activation", "record provider fingerprint in the deployment log",
  ]
  if self.has_breaking_change() {
    guards.push("require compatibility replay before approval")
  }
  if self.environment() is Production {
    guards.push("start with a canary observation window")
  }
  guards
}

///|
pub fn ReleasePlan::replay_required(self : ReleasePlan) -> Bool {
  match self.compatibility {
    Some(report) => report.requires_replay()
    None => false
  }
}

///|
pub fn ReleasePlan::stage(self : ReleasePlan) -> String {
  if self.metadata_errors().length() > 0 {
    "metadata-invalid"
  } else if !self.health.is_ready() {
    "health-blocked"
  } else if self.replay_required() {
    "replay-required"
  } else if !self.is_approved() {
    self.environment().name() + "-pending-approval"
  } else {
    self.environment().name() + "-ready"
  }
}

///|
pub fn ReleasePlan::change_summary(self : ReleasePlan) -> String {
  if self.changes.length() == 0 {
    "no changes"
  } else {
    let mut added = 0
    let mut changed = 0
    let mut removed = 0
    for item in self.changes {
      match item.kind {
        "added" => added += 1
        "changed" => changed += 1
        "removed" => removed += 1
        _ => ()
      }
    }
    "added=" +
    added.to_string() +
    ", changed=" +
    changed.to_string() +
    ", removed=" +
    removed.to_string()
  }
}

///|
pub fn ReleasePlan::provider_fingerprint(self : ReleasePlan) -> String {
  self.next.fingerprint()
}

///|
pub fn ReleasePlan::rollback_fingerprint(self : ReleasePlan) -> String? {
  self.previous.map(provider => provider.fingerprint())
}

///|
pub fn ReleasePlan::reviewer_required(self : ReleasePlan) -> Bool {
  self.environment().requires_approval() ||
  self.risk.at_least(High) ||
  self.replay_required()
}

///|
pub fn ReleasePlan::operator_notes(self : ReleasePlan) -> Array[String] {
  let notes = []
  notes.push("stage: " + self.stage())
  notes.push("provider: " + self.provider_fingerprint())
  notes.push("changes: " + self.change_summary())
  if self.reviewer_required() {
    notes.push("operator review is required before activation")
  }
  if self.rollback_fingerprint() is Some(fingerprint) {
    notes.push("rollback provider: " + fingerprint)
  }
  notes
}
