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
fn parse_line(
  provider : Provider,
  line_no : Int,
  text : String,
) -> Provider raise ParseError {
  let parts = text.split(" ").to_array()
  guard token(parts, 0) is Some("flag") else { raise_invalid(line_no, text) }
  guard token(parts, 2) is Some("bool") else { raise_invalid(line_no, text) }
  let key = match token(parts, 1) {
    Some(value) => value
    None => raise_invalid(line_no, text)
  }
  let bool_value = match token(parts, 3).bind(parse_bool_token) {
    Some(value) => value
    None => raise_invalid(line_no, text)
  }
  match parts.length() {
    4 => provider.with_bool(key, bool_value)
    6 =>
      if token(parts, 4) is Some("rollout") {
        match token(parts, 5).bind(parse_non_negative_int) {
          Some(pct) =>
            provider.with_bool_rollout(key, bool_value, percentage=pct)
          None => raise_invalid(line_no, text)
        }
      } else {
        raise_invalid(line_no, text)
      }
    7 =>
      if token(parts, 4) is Some("target") {
        let attr = token(parts, 5).unwrap()
        let expected = token(parts, 6).unwrap()
        provider.with_bool_target(
          key,
          bool_value,
          attr~,
          equals=StringValue(expected),
        )
      } else {
        raise_invalid(line_no, text)
      }
    _ => raise_invalid(line_no, text)
  }
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
