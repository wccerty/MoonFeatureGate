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

- Public GitHub repository: `https://github.com/wccerty/MoonFeatureGate`
- GitLink repository: `https://gitlink.org.cn/Wccerty/MoonFeatureGate`
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

GitHub and GitLink remotes should both point to the Wccerty/wccerty-owned
submission repositories before final upload.

## Mooncakes Dry Run

`moon publish --dry-run` completed local package validation and checked the
extracted package successfully. The final server step returned:

```text
403 Forbidden: User mismatch between the module owner and the authenticated Mooncakes account.
```

Resolution: publish with Mooncakes credentials for `Wccerty`, or change
`moon.mod` only if the competition account and repository owner are intentionally
different.
