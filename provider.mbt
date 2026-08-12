///|
pub(all) struct FlagDefinition {
  key : String
  value : FlagValue
  enabled : Bool
  rollout_percentage : Int?
  target_attr : String?
  target_value : FlagValue?
} derive(Debug)

///|
pub fn FlagDefinition::has_target(self : FlagDefinition) -> Bool {
  match (self.target_attr, self.target_value) {
    (Some(_), Some(_)) => true
    _ => false
  }
}

///|
pub fn FlagDefinition::is_rollout(self : FlagDefinition) -> Bool {
  self.rollout_percentage is Some(_)
}

///|
pub fn FlagDefinition::value_kind(self : FlagDefinition) -> String {
  match self.value {
    BoolValue(_) => "bool"
    StringValue(_) => "string"
    IntValue(_) => "int"
    DoubleValue(_) => "double"
  }
}

///|
/// Returns configuration defects without changing the provider. The JSON
/// parser performs the same checks while the builder API clamps rollout values;
/// this method is useful for provider inspection and diagnostics.
pub fn FlagDefinition::validation_errors(
  self : FlagDefinition,
) -> Array[String] {
  let errors = []
  if self.key == "" {
    errors.push("empty_key")
  }
  match self.rollout_percentage {
    Some(value) =>
      if value < 0 || value > 10000 {
        errors.push("rollout_out_of_range")
      }
    None => ()
  }
  match (self.target_attr, self.target_value) {
    (None, None) => ()
    (Some(attr), Some(_)) =>
      if attr == "" {
        errors.push("empty_target_attribute")
      }
    (Some(_), None) => errors.push("missing_target_value")
    (None, Some(_)) => errors.push("missing_target_attribute")
  }
  errors
}

///|
pub struct Provider {
  flags : Map[String, FlagDefinition]
} derive(Debug)

///|
pub(all) struct ProviderStats {
  mut total : Int
  mut enabled : Int
  mut disabled : Int
  mut rollout : Int
  mut targeted : Int
  mut bool_count : Int
  mut string_count : Int
  mut int_count : Int
  mut double_count : Int
} derive(Debug, Eq)

///|
pub impl FeatureProvider for Provider with fn get_flag_definition(
  self : Provider,
  key : String,
) -> FlagDefinition? {
  self.flags.get(key)
}

///|
pub(all) struct BoolEvaluation {
  flag_key : String
  value : Bool
  reason : String
} derive(Debug, Eq)

///|
pub fn empty_provider() -> Provider {
  { flags: Map([]) }
}

///|
/// Inserts a fully described definition for adapters and migration tools.
/// Builder helpers remain the preferred safe path for ordinary applications.
pub fn Provider::with_definition(
  self : Provider,
  definition : FlagDefinition,
) -> Provider {
  let next = self.flags.copy()
  next[definition.key] = definition
  { flags: next }
}

///|
pub fn Provider::contains(self : Provider, key : String) -> Bool {
  self.flags.contains(key)
}

///|
pub fn Provider::flag_keys(self : Provider) -> Array[String] {
  let keys = []
  for key in self.flags.keys() {
    keys.push(key)
  }
  keys
}

///|
pub fn Provider::remove(self : Provider, key : String) -> Provider {
  let next = self.flags.copy()
  next.remove(key)
  { flags: next }
}

///|
pub fn Provider::merge(self : Provider, overlay : Provider) -> Provider {
  let next = self.flags.copy()
  next.merge_in_place(overlay.flags)
  { flags: next }
}

///|
pub fn Provider::stats(self : Provider) -> ProviderStats {
  let stats = {
    total: 0,
    enabled: 0,
    disabled: 0,
    rollout: 0,
    targeted: 0,
    bool_count: 0,
    string_count: 0,
    int_count: 0,
    double_count: 0,
  }
  for _, flag in self.flags {
    stats.total += 1
    if flag.enabled {
      stats.enabled += 1
    } else {
      stats.disabled += 1
    }
    if flag.is_rollout() {
      stats.rollout += 1
    }
    if flag.has_target() {
      stats.targeted += 1
    }
    match flag.value {
      BoolValue(_) => stats.bool_count += 1
      StringValue(_) => stats.string_count += 1
      IntValue(_) => stats.int_count += 1
      DoubleValue(_) => stats.double_count += 1
    }
  }
  stats
}

///|
pub fn Provider::definitions(self : Provider) -> Array[FlagDefinition] {
  let definitions = []
  for _, flag in self.flags {
    definitions.push(flag)
  }
  definitions
}

///|
pub fn Provider::with_value(
  self : Provider,
  key : String,
  value : FlagValue,
  enabled? : Bool = true,
) -> Provider {
  let next = self.flags.copy()
  next[key] = {
    key,
    value,
    enabled,
    rollout_percentage: None,
    target_attr: None,
    target_value: None,
  }
  { flags: next }
}

///|
pub fn Provider::with_value_rollout(
  self : Provider,
  key : String,
  value : FlagValue,
  percentage~ : Int,
  enabled? : Bool = true,
) -> Provider {
  let next = self.flags.copy()
  next[key] = {
    key,
    value,
    enabled,
    rollout_percentage: Some(clamp_percentage(percentage)),
    target_attr: None,
    target_value: None,
  }
  { flags: next }
}

///|
pub fn Provider::with_value_target(
  self : Provider,
  key : String,
  value : FlagValue,
  attr~ : String,
  equals~ : FlagValue,
  enabled? : Bool = true,
) -> Provider {
  let next = self.flags.copy()
  next[key] = {
    key,
    value,
    enabled,
    rollout_percentage: None,
    target_attr: Some(attr),
    target_value: Some(equals),
  }
  { flags: next }
}

///|
pub fn Provider::with_bool(
  self : Provider,
  key : String,
  value : Bool,
  enabled? : Bool = true,
) -> Provider {
  let next = self.flags.copy()
  next[key] = {
    key,
    value: BoolValue(value),
    enabled,
    rollout_percentage: None,
    target_attr: None,
    target_value: None,
  }
  { flags: next }
}

///|
pub fn Provider::with_bool_rollout(
  self : Provider,
  key : String,
  value : Bool,
  percentage~ : Int,
  enabled? : Bool = true,
) -> Provider {
  let next = self.flags.copy()
  next[key] = {
    key,
    value: BoolValue(value),
    enabled,
    rollout_percentage: Some(clamp_percentage(percentage)),
    target_attr: None,
    target_value: None,
  }
  { flags: next }
}

///|
pub fn Provider::with_bool_target(
  self : Provider,
  key : String,
  value : Bool,
  attr~ : String,
  equals~ : FlagValue,
  enabled? : Bool = true,
) -> Provider {
  let next = self.flags.copy()
  next[key] = {
    key,
    value: BoolValue(value),
    enabled,
    rollout_percentage: None,
    target_attr: Some(attr),
    target_value: Some(equals),
  }
  { flags: next }
}

///|
pub fn Provider::with_string(
  self : Provider,
  key : String,
  value : String,
  enabled? : Bool = true,
) -> Provider {
  let next = self.flags.copy()
  next[key] = {
    key,
    value: StringValue(value),
    enabled,
    rollout_percentage: None,
    target_attr: None,
    target_value: None,
  }
  { flags: next }
}

///|
pub fn Provider::with_string_rollout(
  self : Provider,
  key : String,
  value : String,
  percentage~ : Int,
  enabled? : Bool = true,
) -> Provider {
  let next = self.flags.copy()
  next[key] = {
    key,
    value: StringValue(value),
    enabled,
    rollout_percentage: Some(clamp_percentage(percentage)),
    target_attr: None,
    target_value: None,
  }
  { flags: next }
}

///|
pub fn Provider::with_string_target(
  self : Provider,
  key : String,
  value : String,
  attr~ : String,
  equals~ : FlagValue,
  enabled? : Bool = true,
) -> Provider {
  let next = self.flags.copy()
  next[key] = {
    key,
    value: StringValue(value),
    enabled,
    rollout_percentage: None,
    target_attr: Some(attr),
    target_value: Some(equals),
  }
  { flags: next }
}

///|
pub fn Provider::with_int(
  self : Provider,
  key : String,
  value : Int,
  enabled? : Bool = true,
) -> Provider {
  let next = self.flags.copy()
  next[key] = {
    key,
    value: IntValue(value),
    enabled,
    rollout_percentage: None,
    target_attr: None,
    target_value: None,
  }
  { flags: next }
}

///|
pub fn Provider::with_int_rollout(
  self : Provider,
  key : String,
  value : Int,
  percentage~ : Int,
  enabled? : Bool = true,
) -> Provider {
  let next = self.flags.copy()
  next[key] = {
    key,
    value: IntValue(value),
    enabled,
    rollout_percentage: Some(clamp_percentage(percentage)),
    target_attr: None,
    target_value: None,
  }
  { flags: next }
}

///|
pub fn Provider::with_int_target(
  self : Provider,
  key : String,
  value : Int,
  attr~ : String,
  equals~ : FlagValue,
  enabled? : Bool = true,
) -> Provider {
  let next = self.flags.copy()
  next[key] = {
    key,
    value: IntValue(value),
    enabled,
    rollout_percentage: None,
    target_attr: Some(attr),
    target_value: Some(equals),
  }
  { flags: next }
}

///|
pub fn Provider::with_double(
  self : Provider,
  key : String,
  value : Double,
  enabled? : Bool = true,
) -> Provider {
  let next = self.flags.copy()
  next[key] = {
    key,
    value: DoubleValue(value),
    enabled,
    rollout_percentage: None,
    target_attr: None,
    target_value: None,
  }
  { flags: next }
}

///|
pub fn Provider::with_double_rollout(
  self : Provider,
  key : String,
  value : Double,
  percentage~ : Int,
  enabled? : Bool = true,
) -> Provider {
  let next = self.flags.copy()
  next[key] = {
    key,
    value: DoubleValue(value),
    enabled,
    rollout_percentage: Some(clamp_percentage(percentage)),
    target_attr: None,
    target_value: None,
  }
  { flags: next }
}

///|
pub fn Provider::with_double_target(
  self : Provider,
  key : String,
  value : Double,
  attr~ : String,
  equals~ : FlagValue,
  enabled? : Bool = true,
) -> Provider {
  let next = self.flags.copy()
  next[key] = {
    key,
    value: DoubleValue(value),
    enabled,
    rollout_percentage: None,
    target_attr: Some(attr),
    target_value: Some(equals),
  }
  { flags: next }
}

///|
fn target_matches(flag : FlagDefinition, ctx : EvalContext) -> Bool {
  match (flag.target_attr, flag.target_value) {
    (Some(attr), Some(expected)) =>
      match ctx.attributes.get(attr) {
        Some(actual) => actual == expected
        None => false
      }
    _ => true
  }
}

///|
pub fn[P : FeatureProvider] evaluate_bool(
  provider : P,
  flag_key : String,
  ctx : EvalContext,
  default~ : Bool,
) -> BoolEvaluation {
  ignore(ctx)
  match provider.get_flag_definition(flag_key) {
    Some(flag) =>
      if !flag.enabled {
        { flag_key, value: default, reason: "disabled" }
      } else if !target_matches(flag, ctx) {
        { flag_key, value: default, reason: "target_miss" }
      } else {
        match flag.value {
          BoolValue(value) =>
            match flag.rollout_percentage {
              Some(percentage) =>
                if rollout_bucket(flag_key, ctx.targeting_key) < percentage {
                  { flag_key, value, reason: "rollout_match" }
                } else {
                  { flag_key, value: default, reason: "rollout_miss" }
                }
              None =>
                match (flag.target_attr, flag.target_value) {
                  (Some(_), Some(_)) =>
                    { flag_key, value, reason: "target_match" }
                  _ => { flag_key, value, reason: "static" }
                }
            }
          _ => { flag_key, value: default, reason: "type_mismatch" }
        }
      }
    None => { flag_key, value: default, reason: "default" }
  }
}
