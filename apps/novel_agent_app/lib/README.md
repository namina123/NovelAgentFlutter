# app lib

Suggested layout:

```text
lib/
  app/
    bootstrap/
    routing/
    theme/
  features/
    project/
    session/
    workflow/
    settings/
  shared/
    widgets/
    view_models/
```

Rules:

- feature UI may depend on `novel_agent_core`
- feature UI may call adapters only through app composition wiring
- cross-feature UI sharing goes to `shared/`, not to a giant controller
