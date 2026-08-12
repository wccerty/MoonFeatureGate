///|
/// An in-memory registry for safely switching between named configurations.
/// Applications can load providers from JSON or a custom source, audit them,
/// and activate a known-good snapshot without changing evaluator call sites.
pub(all) struct ProviderSnapshot {
  name : String
  version : String
  provider : Provider
  fingerprint : String
  audited : Bool
} derive(Debug)

///|
pub fn snapshot(
  name : String,
  version : String,
  provider : Provider,
) -> ProviderSnapshot {
  {
    name,
    version,
    provider,
    fingerprint: provider.fingerprint(),
    audited: provider.is_safe(),
  }
}

///|
pub(all) struct ProviderRegistry {
  snapshots : Map[String, ProviderSnapshot]
  active_name : String?
} derive(Debug)

///|
pub fn new_registry() -> ProviderRegistry {
  { snapshots: Map([]), active_name: None }
}

///|
pub fn ProviderRegistry::register(
  self : ProviderRegistry,
  item : ProviderSnapshot,
) -> ProviderRegistry {
  let next = self.snapshots.copy()
  next[item.name] = item
  { ..self, snapshots: next }
}

///|
pub fn ProviderRegistry::contains(
  self : ProviderRegistry,
  name : String,
) -> Bool {
  self.snapshots.contains(name)
}

///|
pub fn ProviderRegistry::get(
  self : ProviderRegistry,
  name : String,
) -> ProviderSnapshot? {
  self.snapshots.get(name)
}

///|
pub fn ProviderRegistry::activate(
  self : ProviderRegistry,
  name : String,
) -> ProviderRegistry? {
  match self.snapshots.get(name) {
    Some(item) if item.audited => Some({ ..self, active_name: Some(name) })
    _ => None
  }
}

///|
pub fn ProviderRegistry::active(self : ProviderRegistry) -> ProviderSnapshot? {
  match self.active_name {
    Some(name) => self.snapshots.get(name)
    None => None
  }
}

///|
pub fn ProviderRegistry::active_provider(self : ProviderRegistry) -> Provider? {
  self.active().map(item => item.provider)
}

///|
pub fn ProviderRegistry::names(self : ProviderRegistry) -> Array[String] {
  let names = []
  for name in self.snapshots.keys() {
    names.push(name)
  }
  names.sort()
  names
}

///|
pub fn ProviderRegistry::remove(
  self : ProviderRegistry,
  name : String,
) -> ProviderRegistry {
  let next = self.snapshots.copy()
  next.remove(name)
  let active_name = match self.active_name {
    Some(active) if active == name => None
    other => other
  }
  { snapshots: next, active_name }
}

///|
pub fn ProviderRegistry::summary(self : ProviderRegistry) -> String {
  let active = match self.active_name {
    Some(name) => name
    None => "none"
  }
  "snapshots=" + self.snapshots.length().to_string() + ", active=" + active
}
