///|
struct FlagDefinition {
  key : String
  value : FlagValue
  enabled : Bool
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
  next[key] = { key, value: BoolValue(value), enabled: enabled }
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
          BoolValue(value) => { flag_key, value, reason: "static" }
          _ => { flag_key, value: default, reason: "type_mismatch" }
        }
      }
    None => { flag_key, value: default, reason: "default" }
  }
}
