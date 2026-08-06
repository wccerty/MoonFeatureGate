# MoonFeatureGate Design Notes

MoonFeatureGate keeps evaluation local and deterministic. A caller supplies a
provider, a flag key, an evaluation context, and a default value. The evaluator
returns both the value and a reason string so command-line demos, tests, and
future telemetry can explain the decision.

## Evaluation Order

1. Missing flag returns the caller default with reason `default`.
2. Disabled flag returns the caller default with reason `disabled`.
3. Attribute targeting is checked before rollout.
4. Percentage rollout uses a stable 0..9999 bucket from `flag_key:targeting_key`.
5. A matching static bool flag returns reason `static`.

## Configuration Validation

The JSON provider accepts either a top-level `flags` object or a direct map of
flag definitions. An explicitly empty `flags` object is valid. The parser
rejects malformed JSON, non-object `flags`, non-object flag definitions,
non-primitive values, non-boolean `enabled`, non-integral or out-of-range
`rollout_percentage`, and incomplete target pairs instead of silently dropping
invalid entries.

## Scope

The first version deliberately avoids a hosted control plane. This keeps the
runtime useful for MoonBit examples, tests, local services, and WASM demos.
The extension point is the `Provider`: later providers can load JSON, TOML,
Mooncakes-hosted examples, or remote configuration without changing the public
evaluation API.

## Difference From Existing Mooncakes Packages

Mooncakes already contains logging, tracing, OpenTelemetry, config parsers, and
policy engines. MoonFeatureGate fills a different slot: feature rollout and
auditable local flag evaluation. It can later integrate with those packages
instead of competing with them.
