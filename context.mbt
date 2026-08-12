///|
pub(all) struct EvalContext {
  targeting_key : String
  attributes : Map[String, FlagValue]
} derive(Debug)

///|
pub fn context(targeting_key : String) -> EvalContext {
  { targeting_key, attributes: Map([]) }
}

///|
/// Creates a context without a stable user key. This is useful for
/// application-wide flags that do not use percentage rollout.
pub fn empty_context() -> EvalContext {
  context("")
}

///|
pub fn EvalContext::with_attr(
  self : EvalContext,
  key : String,
  value : FlagValue,
) -> EvalContext {
  let next = self.attributes.copy()
  next[key] = value
  { ..self, attributes: next }
}

///|
/// Adds or replaces a batch of attributes while keeping the original context
/// immutable for callers that need to reuse it across requests.
pub fn EvalContext::with_attrs(
  self : EvalContext,
  attributes : Array[(String, FlagValue)],
) -> EvalContext {
  let next = self.attributes.copy()
  for _, pair in attributes {
    let (key, value) = pair
    next[key] = value
  }
  { ..self, attributes: next }
}

///|
pub fn EvalContext::with_targeting_key(
  self : EvalContext,
  targeting_key : String,
) -> EvalContext {
  { ..self, targeting_key, }
}

///|
pub fn EvalContext::get_attr(self : EvalContext, key : String) -> FlagValue? {
  self.attributes.get(key)
}

///|
pub fn EvalContext::has_attr(self : EvalContext, key : String) -> Bool {
  self.attributes.contains(key)
}

///|
pub fn EvalContext::attribute_count(self : EvalContext) -> Int {
  self.attributes.length()
}

///|
pub fn EvalContext::merge(
  self : EvalContext,
  overlay : EvalContext,
) -> EvalContext {
  let next = self.attributes.copy()
  for key, value in overlay.attributes {
    next[key] = value
  }
  let targeting_key = if overlay.targeting_key == "" {
    self.targeting_key
  } else {
    overlay.targeting_key
  }
  { targeting_key, attributes: next }
}
