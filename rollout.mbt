///|
fn clamp_percentage(value : Int) -> Int {
  if value < 0 {
    0
  } else if value > 10000 {
    10000
  } else {
    value
  }
}

///|
pub fn rollout_bucket(flag_key : String, targeting_key : String) -> Int {
  let source = flag_key + ":" + targeting_key
  let mut acc = 5381
  for char in source {
    acc = ((acc * 33) + char.to_int()) % 10000
  }
  acc
}
