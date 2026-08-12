///|
pub(all) suberror ParseError {
  InvalidLine(line~ : Int, text~ : String)
} derive(Debug, Eq)

///|
fn token(parts : Array[StringView], index : Int) -> String? {
  match parts.get(index) {
    Some(part) => Some(part.to_owned())
    None => None
  }
}

///|
fn parse_bool_token(text : String) -> Bool? {
  match text {
    "true" => Some(true)
    "false" => Some(false)
    _ => None
  }
}

///|
fn[T] raise_invalid(line : Int, text : String) -> T raise ParseError {
  raise InvalidLine(line~, text~)
}

///|
fn parse_non_negative_int(text : String) -> Int? {
  if text == "" {
    None
  } else {
    let mut value = 0
    let mut ok = true
    for char in text {
      if char >= '0' && char <= '9' {
        value = value * 10 + char.to_int() - '0'.to_int()
      } else {
        ok = false
      }
    }
    if ok {
      Some(value)
    } else {
      None
    }
  }
}

///|
fn parse_int_token(text : String) -> Int? {
  if text == "" {
    None
  } else {
    let negative = text.has_prefix("-")
    let digits = if negative { text[1:] } else { text[:] }
    match parse_non_negative_int(digits.to_owned()) {
      Some(value) => Some(if negative { -value } else { value })
      None => None
    }
  }
}

///|
fn parse_double_token(text : String) -> Double? {
  try {
    match @json.parse(text) {
      Number(value, ..) => Some(value)
      _ => None
    }
  } catch {
    _ => None
  }
}

///|
fn parse_flag_value(kind : String, text : String) -> FlagValue? {
  match kind {
    "bool" => parse_bool_token(text).map(value => BoolValue(value))
    "string" => if text == "" { None } else { Some(StringValue(text)) }
    "int" => parse_int_token(text).map(value => IntValue(value))
    "double" => parse_double_token(text).map(value => DoubleValue(value))
    _ => None
  }
}

///|
fn parse_modifier(
  provider : Provider,
  key : String,
  value : FlagValue,
  parts : Array[StringView],
  line_no : Int,
  text : String,
) -> Provider raise ParseError {
  let disabled = token(parts, parts.length() - 1) is Some("disabled")
  let length = if disabled { parts.length() - 1 } else { parts.length() }
  match length {
    4 => provider.with_value(key, value, enabled=!disabled)
    6 =>
      if token(parts, 4) is Some("rollout") {
        match token(parts, 5).bind(parse_non_negative_int) {
          Some(pct) =>
            provider.with_value_rollout(
              key,
              value,
              percentage=pct,
              enabled=!disabled,
            )
          None => raise_invalid(line_no, text)
        }
      } else {
        raise_invalid(line_no, text)
      }
    7 =>
      if token(parts, 4) is Some("target") {
        let attr = token(parts, 5).unwrap()
        let expected = token(parts, 6).unwrap()
        if attr == "" || expected == "" {
          raise_invalid(line_no, text)
        } else {
          provider.with_value_target(
            key,
            value,
            attr~,
            equals=StringValue(expected),
            enabled=!disabled,
          )
        }
      } else {
        raise_invalid(line_no, text)
      }
    _ => raise_invalid(line_no, text)
  }
}

///|
fn parse_line(
  provider : Provider,
  line_no : Int,
  text : String,
) -> Provider raise ParseError {
  let parts = text.split(" ").to_array()
  guard token(parts, 0) is Some("flag") else { raise_invalid(line_no, text) }
  let key = match token(parts, 1) {
    Some(value) if value != "" => value
    None => raise_invalid(line_no, text)
    _ => raise_invalid(line_no, text)
  }
  let kind = match token(parts, 2) {
    Some(value) => value
    None => raise_invalid(line_no, text)
  }
  let raw_value = match token(parts, 3) {
    Some(value) => value
    None => raise_invalid(line_no, text)
  }
  let value = match parse_flag_value(kind, raw_value) {
    Some(value) => value
    None => raise_invalid(line_no, text)
  }
  parse_modifier(provider, key, value, parts, line_no, text)
}

///|
pub fn parse_provider(text : String) -> Provider raise ParseError {
  let mut provider = empty_provider()
  let mut line_no = 0
  for raw in text.split("\n") {
    line_no += 1
    let line = raw.trim().to_owned()
    if line == "" || line.has_prefix("#") {
      ()
    } else {
      provider = parse_line(provider, line_no, line)
    }
  }
  provider
}
