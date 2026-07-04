///|
struct FlagDefinition {
  key : String
  value : FlagValue
  enabled : Bool
  rollout_percentage : Int?
} derive(Debug)

///|
pub struct Provider {
  flags : Map[String, FlagDefinition]
} derive(Debug)

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
  enabled? : Bool = true
) -> Provider {
  let next = self.flags.copy()
  next[key] = {
    key,
    value: BoolValue(value),
    enabled: enabled,
    rollout_percentage: None,
  }
  { flags: next }
}

///|
pub fn Provider::with_bool_rollout(
  self : Provider,
  key : String,
  value : Bool,
  percentage~ : Int,
  enabled? : Bool = true
) -> Provider {
  let next = self.flags.copy()
  next[key] = {
    key,
    value: BoolValue(value),
    enabled: enabled,
    rollout_percentage: Some(clamp_percentage(percentage)),
  }
  { flags: next }
}

///|
pub fn evaluate_bool(
  provider : Provider,
  flag_key : String,
  ctx : EvalContext,
  default~ : Bool
) -> BoolEvaluation {
  ignore(ctx)
  match provider.flags.get(flag_key) {
    Some(flag) =>
      if !flag.enabled {
        { flag_key, value: default, reason: "disabled" }
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
              None => { flag_key, value, reason: "static" }
            }
          _ => { flag_key, value: default, reason: "type_mismatch" }
        }
      }
    None => { flag_key, value: default, reason: "default" }
  }
}
