# core src

Suggested layout:

```text
lib/src/
  project/
  session/
  workflow/
  agents/
  llm/
  tools/
  settings/
  ports/
```

Guideline:

- keep domain and use case code here
- do not place concrete file/network/process code here

Current migrated pure-logic domains:

- `context`
- `llm/catalog`
- `llm/capabilities`
- `llm/profile`
- `project`
- `records`
- `review`
- `session`
- `tools`
- `workflow`
