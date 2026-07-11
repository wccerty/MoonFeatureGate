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
pub struct Provider {
  flags : Map[String, FlagDefinition]
} derive(Debug)

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
  { flags: {} }
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
