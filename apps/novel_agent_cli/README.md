# novel_agent_cli

Desktop CLI application shell.

Targets:

- Windows
- Linux
- macOS

Responsibilities:

- command parsing
- terminal output
- exit codes
- automation entrypoints

Non-responsibilities:

- Flutter UI state
- shared business rules duplication

This app should depend on:

- `packages/novel_agent_core`
- `packages/novel_agent_adapters`
