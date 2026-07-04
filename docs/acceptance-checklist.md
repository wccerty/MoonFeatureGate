# Acceptance Checklist

## Local Verification

Run from the repository root:

```powershell
moon info
moon fmt --check
moon check --warn-list +73
moon test
moon run cmd/moonfeaturegate
```

## Repository Requirements

- Public GitHub repository: `https://github.com/Lyhdsba/MoonFeatureGate`
- GitLink repository: create the same project name and keep it synchronized.
- License: Apache-2.0.
- README is a regular file, not a symlink.
- Commit history should contain 10-20 meaningful commits before submission.
- Do not use empty commits or artificial split-only commits.

## Mooncakes Overlap Check

Checked keywords before implementation:

- `moongate`
- `featuregate`
- `feature flag`
- `openfeature`
- `rollout`

No directly overlapping Mooncakes package was found for a MoonBit feature flag
and rollout toolkit. Adjacent packages exist for OpenTelemetry, tracing,
logging, config parsing, and policy engines, so this project focuses on feature
management rather than those areas.

## Current Remote Prerequisites

GitHub CLI authentication was invalid before implementation. Refresh locally
with:

```powershell
gh auth refresh -h github.com
```

GitLink push should be done after the user provides credentials or an access
token for the target account.
