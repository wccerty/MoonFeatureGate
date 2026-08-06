///|
pub struct JsonProvider {
  flags : Map[String, FlagDefinition]
} derive(Debug)

///|
pub impl FeatureProvider for JsonProvider with fn get_flag_definition(
  self : JsonProvider,
  key : String,
) -> FlagDefinition? {
  self.flags.get(key)
}

///|
fn json_to_flag_value(json : Json) -> FlagValue? {
  match json {
    True => Some(BoolValue(true))
    False => Some(BoolValue(false))
    String(s) => Some(StringValue(s))
    Number(d, ..) =>
      if d == d.to_int().to_double() {
        Some(IntValue(d.to_int()))
      } else {
        Some(DoubleValue(d))
      }
    _ => None
  }
}

///|
fn parse_flag_definition(
  key : String,
  obj : Map[String, Json],
) -> FlagDefinition? {
  let enabled = match obj.get("enabled") {
    None => Some(true)
    Some(True) => Some(true)
    Some(False) => Some(false)
    _ => None
  }
  let rollout_percentage = match obj.get("rollout_percentage") {
    None => Some(None)
    Some(Number(d, ..)) =>
      if d == d.to_int().to_double() && d >= 0.0 && d <= 10000.0 {
        Some(Some(d.to_int()))
      } else {
        None
      }
    _ => None
  }
  let target = match (obj.get("target_attr"), obj.get("target_value")) {
    (None, None) => Some((None, None))
    (Some(String(attr)), Some(target_json)) =>
      match json_to_flag_value(target_json) {
        Some(target_value) => Some((Some(attr), Some(target_value)))
        None => None
      }
    _ => None
  }
  match (obj.get("value"), enabled, rollout_percentage, target) {
    (
      Some(value_json),
      Some(enabled),
      Some(rollout_percentage),
      Some((target_attr, target_value)),
    ) =>
      match json_to_flag_value(value_json) {
        Some(value) =>
          Some({
            key,
            value,
            enabled,
            rollout_percentage,
            target_attr,
            target_value,
          })
        None => None
      }
    _ => None
  }
}

///|
pub fn parse_json_provider(text : String) -> JsonProvider? {
  try {
    let json = @json.parse(text)
    match json {
      Object(root_map) => {
        let flags_map : Map[String, FlagDefinition] = Map([])
        let flags_json = match root_map.get("flags") {
          Some(Object(m)) => Some(m)
          Some(_) => None
          _ => Some(root_map)
        }
        match flags_json {
          Some(m) => {
            let mut valid = true
            for k, v in m {
              match v {
                Object(obj) =>
                  match parse_flag_definition(k, obj) {
                    Some(def) => flags_map[k] = def
                    None => valid = false
                  }
                _ => valid = false
              }
            }
            if valid {
              Some({ flags: flags_map })
            } else {
              None
            }
          }
          None => None
        }
      }
      _ => None
    }
  } catch {
    _ => None
  }
}
