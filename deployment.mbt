///|
/// Deployment decision that combines provider health with compatibility. This
/// is intentionally pure so release automation can use it in CI without
/// network access or process-global state.
pub(all) struct DeploymentDecision {
  allowed : Bool
  health : ProviderHealth
  compatibility : CompatibilityReport?
  reason : String
} derive(Debug)

///|
pub fn deployment_check(
  previous : Provider?,
  next : Provider,
  policy : ProviderPolicy,
) -> DeploymentDecision {
  let health = next.health_check(policy)
  let compatibility = previous.map(old => compare_providers(old, next))
  let compatibility_ok = match compatibility {
    Some(report) => report.is_safe()
    None => true
  }
  let allowed = health.is_ready() &&
    health.policy.is_compliant() &&
    compatibility_ok
  let reason = if !health.is_ready() {
    "provider health check failed"
  } else if !health.policy.is_compliant() {
    "provider deployment policy failed"
  } else if !compatibility_ok {
    "provider compatibility review failed"
  } else {
    "provider is safe to deploy"
  }
  { allowed, health, compatibility, reason }
}

///|
pub fn DeploymentDecision::summary(self : DeploymentDecision) -> String {
  (if self.allowed { "allowed" } else { "blocked" }) + ": " + self.reason
}

///|
pub fn DeploymentDecision::is_release_ready(self : DeploymentDecision) -> Bool {
  self.allowed && !self.requires_manual_review()
}

///|
pub fn DeploymentDecision::health_status(self : DeploymentDecision) -> String {
  self.health.status_text()
}

///|
pub fn DeploymentDecision::requires_manual_review(
  self : DeploymentDecision,
) -> Bool {
  match self.compatibility {
    Some(report) => report.requires_replay() || self.health.has_warnings()
    None => self.health.has_warnings()
  }
}

///|
pub fn ProviderHealth::has_warnings(self : ProviderHealth) -> Bool {
  self.audit.has_warnings() || self.policy.violation_count() > 0
}
