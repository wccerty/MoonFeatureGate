///|
pub(all) struct EvalContext {
  targeting_key : String
  attributes : Map[String, FlagValue]
} derive(Debug)

///|
pub fn context(targeting_key : String) -> EvalContext {
  { targeting_key, attributes: {} }
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
