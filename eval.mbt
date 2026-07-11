///|
pub(all) struct StringEvaluation {
  flag_key : String
  value : String
  reason : String
} derive(Debug, Eq)

///|
pub(all) struct IntEvaluation {
  flag_key : String
  value : Int
  reason : String
} derive(Debug, Eq)

///|
pub(all) struct DoubleEvaluation {
  flag_key : String
  value : Double
  reason : String
} derive(Debug, Eq)

///|
pub(all) struct ValueEvaluation {
  flag_key : String
  value : FlagValue
  reason : String
} derive(Debug, Eq)

///|
pub fn[P : FeatureProvider] evaluate_string(
  provider : P,
  flag_key : String,
  ctx : EvalContext,
  default~ : String,
) -> StringEvaluation {
  ignore(ctx)
  match provider.get_flag_definition(flag_key) {
    Some(flag) =>
      if !flag.enabled {
        { flag_key, value: default, reason: "disabled" }
      } else if !target_matches(flag, ctx) {
        { flag_key, value: default, reason: "target_miss" }
      } else {
        match flag.value {
          StringValue(value) =>
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

///|
pub fn[P : FeatureProvider] evaluate_int(
  provider : P,
  flag_key : String,
  ctx : EvalContext,
  default~ : Int,
) -> IntEvaluation {
  ignore(ctx)
  match provider.get_flag_definition(flag_key) {
    Some(flag) =>
      if !flag.enabled {
        { flag_key, value: default, reason: "disabled" }
      } else if !target_matches(flag, ctx) {
        { flag_key, value: default, reason: "target_miss" }
      } else {
        match flag.value {
          IntValue(value) =>
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

///|
pub fn[P : FeatureProvider] evaluate_double(
  provider : P,
  flag_key : String,
  ctx : EvalContext,
  default~ : Double,
) -> DoubleEvaluation {
  ignore(ctx)
  match provider.get_flag_definition(flag_key) {
    Some(flag) =>
      if !flag.enabled {
        { flag_key, value: default, reason: "disabled" }
      } else if !target_matches(flag, ctx) {
        { flag_key, value: default, reason: "target_miss" }
      } else {
        match flag.value {
          DoubleValue(value) =>
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

///|
pub fn[P : FeatureProvider] evaluate_value(
  provider : P,
  flag_key : String,
  ctx : EvalContext,
  default~ : FlagValue,
) -> ValueEvaluation {
  ignore(ctx)
  match provider.get_flag_definition(flag_key) {
    Some(flag) =>
      if !flag.enabled {
        { flag_key, value: default, reason: "disabled" }
      } else if !target_matches(flag, ctx) {
        { flag_key, value: default, reason: "target_miss" }
      } else {
        match flag.rollout_percentage {
          Some(percentage) =>
            if rollout_bucket(flag_key, ctx.targeting_key) < percentage {
              { flag_key, value: flag.value, reason: "rollout_match" }
            } else {
              { flag_key, value: default, reason: "rollout_miss" }
            }
          None =>
            match (flag.target_attr, flag.target_value) {
              (Some(_), Some(_)) =>
                { flag_key, value: flag.value, reason: "target_match" }
              _ => { flag_key, value: flag.value, reason: "static" }
            }
        }
      }
    None => { flag_key, value: default, reason: "default" }
  }
}
