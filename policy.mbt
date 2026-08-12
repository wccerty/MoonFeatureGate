///|
/// Deployment policy used by preflight checks. It lets a service enforce
/// conventions before activating a provider without changing evaluation rules.
pub(all) struct ProviderPolicy {
  require_non_empty_keys : Bool
  allow_disabled_flags : Bool
  allow_zero_rollout : Bool
  require_rollout_key_prefix : String?
  max_rollout_percentage : Int
} derive(Debug, Eq)

///|
pub fn default_policy() -> ProviderPolicy {
  {
    require_non_empty_keys: true,
    allow_disabled_flags: true,
    allow_zero_rollout: true,
    require_rollout_key_prefix: None,
    max_rollout_percentage: 10000,
  }
}

///|
pub(all) struct PolicyViolation {
  key : String
  code : String
  message : String
} derive(Debug, Eq)

///|
pub(all) struct PolicyReport {
  provider_fingerprint : String
  violations : Array[PolicyViolation]
} derive(Debug)

///|
fn violates_policy(
  policy : ProviderPolicy,
  flag : FlagDefinition,
  violations : Array[PolicyViolation],
) -> Unit {
  if policy.require_non_empty_keys && flag.key == "" {
    violations.push({
      key: flag.key,
      code: "empty_key",
      message: "flag keys must not be empty",
    })
  }
  if !policy.allow_disabled_flags && !flag.enabled {
    violations.push({
      key: flag.key,
      code: "disabled_not_allowed",
      message: "disabled flags are not allowed by deployment policy",
    })
  }
  match flag.rollout_percentage {
    Some(percentage) => {
      if percentage == 0 && !policy.allow_zero_rollout {
        violations.push({
          key: flag.key,
          code: "zero_rollout_not_allowed",
          message: "zero percent rollout is not allowed",
        })
      }
      if percentage > policy.max_rollout_percentage {
        violations.push({
          key: flag.key,
          code: "rollout_limit",
          message: "rollout percentage exceeds deployment policy",
        })
      }
      match policy.require_rollout_key_prefix {
        Some(prefix) if !flag.key.has_prefix(prefix) =>
          violations.push({
            key: flag.key,
            code: "rollout_key_prefix",
            message: "rollout flag key does not use the required prefix",
          })
        _ => ()
      }
    }
    None => ()
  }
}

///|
pub fn Provider::check_policy(
  self : Provider,
  policy : ProviderPolicy,
) -> PolicyReport {
  let violations = []
  for _, flag in self.flags {
    violates_policy(policy, flag, violations)
  }
  { provider_fingerprint: self.fingerprint(), violations }
}

///|
pub fn PolicyReport::is_compliant(self : PolicyReport) -> Bool {
  self.violations.length() == 0
}

///|
pub fn PolicyReport::violation_count(self : PolicyReport) -> Int {
  self.violations.length()
}

///|
pub fn PolicyReport::summary(self : PolicyReport) -> String {
  "provider=" +
  self.provider_fingerprint +
  ", violations=" +
  self.violations.length().to_string()
}

///|
pub fn PolicyReport::render(self : PolicyReport) -> String {
  let lines = [self.summary()]
  for violation in self.violations {
    lines.push(
      "[" + violation.key + "] " + violation.code + ": " + violation.message,
    )
  }
  lines.join("\n")
}

///|
pub fn Provider::activate_if_compliant(
  self : Provider,
  policy : ProviderPolicy,
) -> Provider? {
  if self.check_policy(policy).is_compliant() {
    Some(self)
  } else {
    None
  }
}

///|
pub fn ProviderPolicy::production() -> ProviderPolicy {
  {
    require_non_empty_keys: true,
    allow_disabled_flags: false,
    allow_zero_rollout: false,
    require_rollout_key_prefix: Some("release."),
    max_rollout_percentage: 10000,
  }
}

///|
pub fn ProviderPolicy::for_tests() -> ProviderPolicy {
  {
    require_non_empty_keys: true,
    allow_disabled_flags: true,
    allow_zero_rollout: true,
    require_rollout_key_prefix: None,
    max_rollout_percentage: 10000,
  }
}
