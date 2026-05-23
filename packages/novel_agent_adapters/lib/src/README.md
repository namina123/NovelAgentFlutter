# adapters src

Suggested layout:

```text
lib/src/
  storage/
  providers/
  host/
  config/
  bootstrap/
```

Guideline:

- implement ports from `novel_agent_core`
- keep desktop-only adapters clearly separated under `host/`
