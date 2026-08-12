///|
/// Returns the provider as the documented, line-oriented DSL. This is useful
/// for review diffs, fixtures, migration scripts, and small command-line
/// tools. The output is deterministic because flag keys are sorted.
pub fn Provider::to_dsl(self : Provider) -> String {
  let lines = []
  let keys = self.flag_keys()
  keys.sort()
  for key in keys {
    let flag = self.get_flag_definition(key).unwrap()
    let kind = flag.value_kind()
    let mut line = "flag " + flag.key + " " + kind + " " + flag.value.to_text()
    match (flag.target_attr, flag.target_value) {
      (Some(attr), Some(expected)) =>
        line = line + " target " + attr + " " + expected.to_text()
      _ =>
        match flag.rollout_percentage {
          Some(percentage) => line = line + " rollout " + percentage.to_string()
          None => ()
        }
    }
    if !flag.enabled {
      line = line + " disabled"
    }
    lines.push(line)
  }
  lines.join("\n")
}

///|
pub fn Provider::enabled_keys(self : Provider) -> Array[String] {
  let keys = []
  for key, flag in self.flags {
    if flag.enabled {
      keys.push(key)
    }
  }
  keys.sort()
  keys
}

///|
pub fn Provider::disabled_keys(self : Provider) -> Array[String] {
  let keys = []
  for key, flag in self.flags {
    if !flag.enabled {
      keys.push(key)
    }
  }
  keys.sort()
  keys
}

///|
pub fn Provider::keys_with_prefix(
  self : Provider,
  prefix : String,
) -> Array[String] {
  let keys = []
  for key in self.flags.keys() {
    if key.has_prefix(prefix) {
      keys.push(key)
    }
  }
  keys.sort()
  keys
}

///|
pub fn Provider::select(self : Provider, keys : Array[String]) -> Provider {
  let next : Map[String, FlagDefinition] = Map([])
  for key in keys {
    match self.flags.get(key) {
      Some(flag) => next[key] = flag
      None => ()
    }
  }
  { flags: next }
}

///|
pub fn Provider::without_disabled(self : Provider) -> Provider {
  self.select(self.enabled_keys())
}

///|
pub fn Provider::count_value_kind(self : Provider, kind : String) -> Int {
  let mut count = 0
  for _, flag in self.flags {
    if flag.value_kind() == kind {
      count += 1
    }
  }
  count
}

///|
pub(all) struct ProviderDiff {
  added : Array[String]
  removed : Array[String]
  changed : Array[String]
  unchanged : Array[String]
} derive(Debug, Eq)

///|
pub fn diff_providers(left : Provider, right : Provider) -> ProviderDiff {
  let added = []
  let removed = []
  let changed = []
  let unchanged = []
  for key in left.flag_keys() {
    match right.flags.get(key) {
      None => removed.push(key)
      Some(flag) =>
        match left.flags.get(key) {
          Some(previous) =>
            if flag_equal(previous, flag) {
              unchanged.push(key)
            } else {
              changed.push(key)
            }
          None => changed.push(key)
        }
    }
  }
  for key in right.flag_keys() {
    if !left.contains(key) {
      added.push(key)
    }
  }
  added.sort()
  removed.sort()
  changed.sort()
  unchanged.sort()
  { added, removed, changed, unchanged }
}

///|
fn flag_equal(left : FlagDefinition, right : FlagDefinition) -> Bool {
  left.key == right.key &&
  left.value == right.value &&
  left.enabled == right.enabled &&
  left.rollout_percentage == right.rollout_percentage &&
  left.target_attr == right.target_attr &&
  left.target_value == right.target_value
}

///|
pub fn ProviderDiff::is_compatible(self : ProviderDiff) -> Bool {
  self.removed.length() == 0
}

///|
pub fn ProviderDiff::summary(self : ProviderDiff) -> String {
  "added=" +
  self.added.length().to_string() +
  ", removed=" +
  self.removed.length().to_string() +
  ", changed=" +
  self.changed.length().to_string() +
  ", unchanged=" +
  self.unchanged.length().to_string()
}
