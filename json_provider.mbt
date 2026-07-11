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
  match obj.get("value") {
    None => None
    Some(value_json) =>
      match json_to_flag_value(value_json) {
        None => None
        Some(value) => {
          let enabled = match obj.get("enabled") {
            Some(True) => true
            Some(False) => false
            _ => true
          }
          let rollout_percentage = match obj.get("rollout_percentage") {
            Some(Number(d, ..)) => Some(clamp_percentage(d.to_int()))
            _ => None
          }
          let target_attr = match obj.get("target_attr") {
            Some(String(s)) => Some(s)
            _ => None
          }
          let target_value = match obj.get("target_value") {
            Some(v) => json_to_flag_value(v)
            _ => None
          }
          Some({
            key,
            value,
            enabled,
            rollout_percentage,
            target_attr,
            target_value,
          })
        }
      }
  }
}

///|
pub fn parse_json_provider(text : String) -> JsonProvider? {
  try {
    let json = @json.parse(text)
    match json {
      Object(root_map) => {
        let flags_map : Map[String, FlagDefinition] = {}
        let flags_json = match root_map.get("flags") {
          Some(Object(m)) => Some(m)
          _ => Some(root_map)
        }
        match flags_json {
          Some(m) =>
            for k, v in m {
              match v {
                Object(obj) =>
                  match parse_flag_definition(k, obj) {
                    Some(def) => flags_map[k] = def
                    None => ()
                  }
                _ => ()
              }
            }
          None => ()
        }
        Some({ flags: flags_map })
      }
      _ => None
    }
  } catch {
    _ => None
  }
}
