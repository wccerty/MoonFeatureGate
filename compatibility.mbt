///|
/// Compatibility classification for configuration deployments. It provides a
/// reviewable answer to the common question: can this provider replace the
/// previous one without making existing flag lookups disappear?
pub(all) enum CompatibilityLevel {
  Identical
  Additive
  Changed
  Breaking
} derive(Debug, Eq)

///|
pub(all) struct CompatibilityReport {
  level : CompatibilityLevel
  diff : ProviderDiff
  message : String
} derive(Debug)

///|
pub fn compare_providers(
  previous : Provider,
  next : Provider,
) -> CompatibilityReport {
  let diff = diff_providers(previous, next)
  let level = if diff.added.length() == 0 &&
    diff.removed.length() == 0 &&
    diff.changed.length() == 0 {
    Identical
  } else if diff.removed.length() > 0 {
    Breaking
  } else if diff.changed.length() > 0 {
    Changed
  } else {
    Additive
  }
  let message = match level {
    Identical => "provider has no configuration changes"
    Additive => "provider only adds new flag keys"
    Changed =>
      "provider changes existing flag definitions; replay tests required"
    Breaking =>
      "provider removes existing flag keys; compatibility review required"
  }
  { level, diff, message }
}

///|
pub fn CompatibilityReport::is_safe(self : CompatibilityReport) -> Bool {
  self.level is (Identical | Additive)
}

///|
pub fn CompatibilityReport::requires_replay(self : CompatibilityReport) -> Bool {
  self.level is (Changed | Breaking)
}

///|
pub fn CompatibilityReport::summary(self : CompatibilityReport) -> String {
  let level = match self.level {
    Identical => "identical"
    Additive => "additive"
    Changed => "changed"
    Breaking => "breaking"
  }
  level + ": " + self.message + " (" + self.diff.summary() + ")"
}

///|
pub fn Provider::same_configuration(self : Provider, other : Provider) -> Bool {
  compare_providers(self, other).level is Identical
}

///|
pub fn Provider::has_only_additions(self : Provider, other : Provider) -> Bool {
  compare_providers(self, other).level is Additive
}

///|
pub fn Provider::overlay_if_safe(
  self : Provider,
  overlay : Provider,
) -> Provider? {
  let report = compare_providers(self, overlay)
  if report.level is (Identical | Additive) {
    Some(self.merge(overlay))
  } else {
    None
  }
}

///|
pub(all) struct ProviderInventory {
  total : Int
  bool_flags : Int
  string_flags : Int
  int_flags : Int
  double_flags : Int
  static_flags : Int
  rollout_flags : Int
  targeted_flags : Int
  enabled_flags : Int
  disabled_flags : Int
} derive(Debug, Eq)

///|
pub fn Provider::inventory(self : Provider) -> ProviderInventory {
  let stats = self.stats()
  {
    total: stats.total,
    bool_flags: stats.bool_count,
    string_flags: stats.string_count,
    int_flags: stats.int_count,
    double_flags: stats.double_count,
    static_flags: stats.total - stats.rollout - stats.targeted,
    rollout_flags: stats.rollout,
    targeted_flags: stats.targeted,
    enabled_flags: stats.enabled,
    disabled_flags: stats.disabled,
  }
}

///|
pub fn ProviderInventory::summary(self : ProviderInventory) -> String {
  "flags=" +
  self.total.to_string() +
  ", typed=(bool=" +
  self.bool_flags.to_string() +
  ", string=" +
  self.string_flags.to_string() +
  ", int=" +
  self.int_flags.to_string() +
  ", double=" +
  self.double_flags.to_string() +
  "), rules=(static=" +
  self.static_flags.to_string() +
  ", rollout=" +
  self.rollout_flags.to_string() +
  ", target=" +
  self.targeted_flags.to_string() +
  ")"
}

///|
pub fn Provider::rollout_keys(self : Provider) -> Array[String] {
  let keys = []
  for key, flag in self.flags {
    if flag.is_rollout() {
      keys.push(key)
    }
  }
  keys.sort()
  keys
}

///|
pub fn Provider::targeted_keys(self : Provider) -> Array[String] {
  let keys = []
  for key, flag in self.flags {
    if flag.has_target() {
      keys.push(key)
    }
  }
  keys.sort()
  keys
}

///|
pub fn Provider::static_keys(self : Provider) -> Array[String] {
  let keys = []
  for key, flag in self.flags {
    if !flag.is_rollout() && !flag.has_target() {
      keys.push(key)
    }
  }
  keys.sort()
  keys
}

///|
pub fn ProviderInventory::is_balanced(self : ProviderInventory) -> Bool {
  self.total ==
  self.bool_flags + self.string_flags + self.int_flags + self.double_flags
}
