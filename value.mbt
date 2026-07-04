///|
pub(all) enum FlagValue {
  BoolValue(Bool)
  StringValue(String)
  IntValue(Int)
  DoubleValue(Double)
} derive(Debug, Eq)

///|
pub fn bool_value(value : Bool) -> FlagValue {
  BoolValue(value)
}

///|
pub fn string_value(value : String) -> FlagValue {
  StringValue(value)
}

///|
pub fn int_value(value : Int) -> FlagValue {
  IntValue(value)
}

///|
pub fn double_value(value : Double) -> FlagValue {
  DoubleValue(value)
}

///|
pub fn FlagValue::to_text(self : FlagValue) -> String {
  match self {
    BoolValue(true) => "true"
    BoolValue(false) => "false"
    StringValue(value) => value
    IntValue(value) => value.to_string()
    DoubleValue(value) => value.to_string()
  }
}
