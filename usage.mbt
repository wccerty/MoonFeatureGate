///|
/// A compact inventory row for documentation, support tooling, and CLI
/// inspection. It deliberately exposes rule shape instead of the flag value.
pub(all) struct FlagUsage {
  key : String
  kind : String
  rule : String
  enabled : Bool
  rollout_percentage : Int?
  target_attribute : String?
} derive(Debug, Eq)

///|
pub fn FlagDefinition::usage(self : FlagDefinition) -> FlagUsage {
  let rule = if self.is_rollout() && self.has_target() {
    "target+rollout"
  } else if self.is_rollout() {
    "rollout"
  } else if self.has_target() {
    "target"
  } else {
    "static"
  }
  {
    key: self.key,
    kind: self.value_kind(),
    rule,
    enabled: self.enabled,
    rollout_percentage: self.rollout_percentage,
    target_attribute: self.target_attr,
  }
}

///|
pub fn Provider::usage(self : Provider) -> Array[FlagUsage] {
  let result = []
  let keys = self.flag_keys()
  keys.sort()
  for key in keys {
    result.push(self.get_flag_definition(key).unwrap().usage())
  }
  result
}

///|
pub fn FlagUsage::label(self : FlagUsage) -> String {
  let state = if self.enabled { "enabled" } else { "disabled" }
  self.key + " [" + self.kind + ", " + self.rule + ", " + state + "]"
}

///|
pub fn Provider::render_usage(self : Provider) -> String {
  let lines = ["Flag usage inventory"]
  for item in self.usage() {
    lines.push("- " + item.label())
  }
  lines.join("\n")
}

///|
pub fn FlagUsage::is_operational(self : FlagUsage) -> Bool {
  self.enabled && self.rule != "static"
}

///|
pub fn Provider::operational_flag_count(self : Provider) -> Int {
  self.usage().count_if(item => item.is_operational())
}
