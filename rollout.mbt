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
    acc = (acc * 33 + char.to_int()) % 10000
  }
  acc
}

///|
pub fn rollout_matches(
  flag_key : String,
  targeting_key : String,
  percentage : Int,
) -> Bool {
  rollout_bucket(flag_key, targeting_key) < clamp_percentage(percentage)
}

///|
pub fn rollout_percentage_for(flag_key : String, targeting_key : String) -> Int {
  rollout_bucket(flag_key, targeting_key)
}

///|
pub fn rollout_buckets(
  flag_key : String,
  targeting_keys : Array[String],
) -> Array[Int] {
  targeting_keys.map(targeting_key => rollout_bucket(flag_key, targeting_key))
}

///|
pub(all) struct RolloutDistribution {
  samples : Int
  matched : Int
  requested_percentage : Int
  observed_percentage : Double
  min_bucket : Int
  max_bucket : Int
} derive(Debug, Eq)

///|
pub fn measure_rollout(
  flag_key : String,
  targeting_keys : Array[String],
  percentage : Int,
) -> RolloutDistribution {
  let requested_percentage = clamp_percentage(percentage)
  let mut matched = 0
  let mut min_bucket = 10000
  let mut max_bucket = 0
  for targeting_key in targeting_keys {
    let bucket = rollout_bucket(flag_key, targeting_key)
    if bucket < requested_percentage {
      matched += 1
    }
    if bucket < min_bucket {
      min_bucket = bucket
    }
    if bucket > max_bucket {
      max_bucket = bucket
    }
  }
  let samples = targeting_keys.length()
  {
    samples,
    matched,
    requested_percentage,
    observed_percentage: if samples == 0 {
      0.0
    } else {
      matched.to_double() * 10000.0 / samples.to_double()
    },
    min_bucket: if samples == 0 {
      0
    } else {
      min_bucket
    },
    max_bucket: if samples == 0 {
      0
    } else {
      max_bucket
    },
  }
}

///|
pub fn RolloutDistribution::within_tolerance(
  self : RolloutDistribution,
  tolerance_basis_points : Double,
) -> Bool {
  let requested = self.requested_percentage.to_double()
  (self.observed_percentage - requested).abs() <= tolerance_basis_points
}

///|
pub fn RolloutDistribution::summary(self : RolloutDistribution) -> String {
  self.matched.to_string() +
  "/" +
  self.samples.to_string() +
  " matched; requested=" +
  self.requested_percentage.to_string() +
  ", observed=" +
  self.observed_percentage.to_string()
}
