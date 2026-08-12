///|
pub(all) enum AuditSeverity {
  Info
  Warning
  Error
} derive(Debug, Eq)

///|
pub(all) struct AuditIssue {
  key : String
  code : String
  severity : AuditSeverity
  message : String
} derive(Debug, Eq)

///|
pub(all) struct AuditReport {
  total_flags : Int
  errors : Int
  warnings : Int
  infos : Int
  issues : Array[AuditIssue]
} derive(Debug)

///|
fn issue(
  issues : Array[AuditIssue],
  key : String,
  code : String,
  severity : AuditSeverity,
  message : String,
) -> Unit {
  issues.push({ key, code, severity, message })
}

///|
fn add_validation_issues(
  issues : Array[AuditIssue],
  flag : FlagDefinition,
) -> Unit {
  for code in flag.validation_errors() {
    issue(issues, flag.key, code, Error, "flag definition is invalid: " + code)
  }
  match flag.rollout_percentage {
    Some(0) =>
      issue(
        issues,
        flag.key,
        "zero_rollout",
        Info,
        "rollout is intentionally disabled at 0%",
      )
    Some(10000) =>
      issue(
        issues,
        flag.key,
        "full_rollout",
        Info,
        "rollout is configured for all targeting keys",
      )
    Some(_) => ()
    None => ()
  }
  if flag.has_target() && flag.is_rollout() {
    issue(
      issues,
      flag.key,
      "target_before_rollout",
      Warning,
      "target matching is evaluated before percentage rollout",
    )
  }
  if !flag.enabled {
    issue(
      issues,
      flag.key,
      "disabled_flag",
      Info,
      "flag is disabled and returns the caller default",
    )
  }
}

///|
pub fn Provider::audit(self : Provider) -> AuditReport {
  let issues = []
  for _, flag in self.flags {
    add_validation_issues(issues, flag)
  }
  let mut errors = 0
  let mut warnings = 0
  let mut infos = 0
  for item in issues {
    match item.severity {
      Error => errors += 1
      Warning => warnings += 1
      Info => infos += 1
    }
  }
  { total_flags: self.flags.length(), errors, warnings, infos, issues }
}

///|
pub fn AuditReport::is_clean(self : AuditReport) -> Bool {
  self.errors == 0
}

///|
pub fn AuditReport::has_warnings(self : AuditReport) -> Bool {
  self.warnings > 0
}

///|
pub fn AuditReport::issue_count(
  self : AuditReport,
  severity : AuditSeverity,
) -> Int {
  match severity {
    Error => self.errors
    Warning => self.warnings
    Info => self.infos
  }
}

///|
pub fn AuditReport::summary(self : AuditReport) -> String {
  self.total_flags.to_string() +
  " flags audited; errors=" +
  self.errors.to_string() +
  ", warnings=" +
  self.warnings.to_string() +
  ", infos=" +
  self.infos.to_string()
}

///|
pub fn AuditReport::render(self : AuditReport) -> String {
  let lines = [self.summary()]
  for item in self.issues {
    let severity = match item.severity {
      Error => "error"
      Warning => "warning"
      Info => "info"
    }
    lines.push(
      severity + " [" + item.key + "] " + item.code + ": " + item.message,
    )
  }
  lines.join("\n")
}

///|
pub fn Provider::is_safe(self : Provider) -> Bool {
  self.audit().is_clean()
}

///|
pub fn Provider::fingerprint(self : Provider) -> String {
  let mut acc = 216613626
  let keys = self.flag_keys()
  keys.sort()
  for key in keys {
    let flag = self.get_flag_definition(key).unwrap()
    let line = flag.key +
      "=" +
      flag.value.to_text() +
      ":" +
      flag.value_kind() +
      ":" +
      flag.enabled.to_string()
    for char in line {
      acc = (acc * 16777619 + char.to_int()) % 2147483647
    }
  }
  acc.to_string()
}

///|
pub fn Provider::describe(self : Provider) -> String {
  let lines = ["MoonFeatureGate provider " + self.fingerprint()]
  let keys = self.flag_keys()
  keys.sort()
  for key in keys {
    let flag = self.get_flag_definition(key).unwrap()
    let mut rule = flag.value_kind()
    if flag.is_rollout() {
      rule = rule + ":rollout"
    }
    if flag.has_target() {
      rule = rule + ":target"
    }
    if !flag.enabled {
      rule = rule + ":disabled"
    }
    lines.push("- " + flag.key + " -> " + rule)
  }
  lines.join("\n")
}
