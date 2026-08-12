///|
/// Combined preflight result used before a configuration snapshot is
/// activated. Keeping audit, policy, and inventory together makes acceptance
/// output useful to both reviewers and operators.
pub(all) enum HealthStatus {
  Healthy
  Warning
  Unhealthy
} derive(Debug, Eq)

///|
pub(all) struct ProviderHealth {
  status : HealthStatus
  audit : AuditReport
  policy : PolicyReport
  inventory : ProviderInventory
  message : String
} derive(Debug)

///|
pub fn Provider::health_check(
  self : Provider,
  policy : ProviderPolicy,
) -> ProviderHealth {
  let audit = self.audit()
  let policy_report = self.check_policy(policy)
  let inventory = self.inventory()
  let status = if !audit.is_clean() || !policy_report.is_compliant() {
    Unhealthy
  } else if audit.has_warnings() {
    Warning
  } else {
    Healthy
  }
  let message = match status {
    Healthy => "provider is ready for activation"
    Warning => "provider is usable but has review warnings"
    Unhealthy => "provider must be fixed before activation"
  }
  { status, audit, policy: policy_report, inventory, message }
}

///|
pub fn ProviderHealth::is_ready(self : ProviderHealth) -> Bool {
  self.status is (Healthy | Warning)
}

///|
pub fn ProviderHealth::summary(self : ProviderHealth) -> String {
  let status = match self.status {
    Healthy => "healthy"
    Warning => "warning"
    Unhealthy => "unhealthy"
  }
  status + ": " + self.message + "; " + self.inventory.summary()
}

///|
pub fn ProviderHealth::render(self : ProviderHealth) -> String {
  self.summary() + "\n" + self.audit.render() + "\n" + self.policy.render()
}

///|
pub fn ProviderHealth::status_text(self : ProviderHealth) -> String {
  match self.status {
    Healthy => "healthy"
    Warning => "warning"
    Unhealthy => "unhealthy"
  }
}
