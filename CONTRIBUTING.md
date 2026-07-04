# Contributing

MoonFeatureGate is intentionally small. Keep changes easy to review:

- Add or update tests before changing behavior.
- Keep public API changes visible through `moon info`.
- Run `moon fmt --check`, `moon check --warn-list +73`, and `moon test`.
- Prefer local, deterministic evaluation over network-dependent behavior.
- Document new DSL forms in `README.md` and add examples under `examples/`.
