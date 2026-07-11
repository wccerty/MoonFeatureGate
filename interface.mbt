///|
pub trait FeatureProvider {
  fn get_flag_definition(self : Self, key : String) -> FlagDefinition?
}
