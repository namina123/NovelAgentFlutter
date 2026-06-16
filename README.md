# NovelAgentFlutter

NovelAgentFlutter is a local-first AI novel workspace built with Flutter and Dart. It is trying to turn long-form writing into a real project workflow instead of a single prompt box: projects, agents, skills, constraints, references, deconstruction assets, sessions, and long-running generation all live in one workspace.

> **Status: active unfinished project**
>
> This repository is not a finished product yet.
> The GUI is partially usable for testing and internal iteration.
> The CLI is present but still incomplete.
> Autonomous long-task generation is under active stabilization and should not be treated as fully reliable production behavior.

## What This Project Is Trying To Build

This project is aimed at people who want more than "generate one chapter from one prompt".

The long-term goal is a writing system where we can:

- create and manage novel projects as durable workspaces;
- run different agent groups for writing, review, extraction, and follow-up work;
- let agents use structured tools instead of only raw text prompting;
- preserve project knowledge instead of repeatedly rebuilding context from scratch;
- support ordinary writing, long-task writing, book deconstruction, and future information-driven workflows on top of shared core contracts.

In short: a novel project should behave more like a living engineering workspace than a disposable chat.

## Current State

The current tagged application line is around `v0.1.3`.

What is true today:

- Windows and Android builds can be produced.
- The GUI shell, project workflow surface, settings surface, and editor surface exist.
- Shared core and adapter layers are real and already support both GUI and CLI directions.
- Ordinary project workflows are much closer to usable than they were in earlier iterations.
- Long-task architecture exists, but real long autonomous runs still need more stabilization.

What is not true today:

- This is not a polished end-user release.
- Long unattended generation is not trustworthy enough yet.
- CLI is not feature-complete.
- Information extraction and reusable knowledge workflows are not fully closed.
- Some advanced writing modes are still design-stage or partially landed only.

## What Is Implemented

### GUI Application

The Flutter app already includes:

- project creation and project opening;
- a workbench-style app shell;
- session/chat style interaction for writing workflows;
- project assets and constraint surfaces;
- agent ecosystem configuration surfaces;
- long-task station and related runtime views;
- Markdown-oriented editing and reading surfaces;
- packaging for Windows and Android.

This area has improved a lot, but it still needs continued polish in naturalness, consistency, and edge-case handling.

### Shared Architecture

The repository already has a real shared architecture instead of separate one-off apps:

- `packages/novel_agent_core`: domain contracts, workflow logic, agents, tools, sessions, project models;
- `packages/novel_agent_adapters`: storage, provider integration, runtime bridging, host-side adapters;
- `apps/novel_agent_app`: Flutter GUI shell;
- `apps/novel_agent_cli`: CLI shell in progress.

That shared-core direction is one of the most important things already achieved in this repository.

### Ordinary Writing Workflow

There is already a usable base for ordinary project writing:

- session-driven writing flow;
- project-level context consumption;
- chapter artifact delivery;
- draft and chapter persistence;
- basic constraint hookup such as expression constraints and chapter-length related controls;
- tool-mediated file and project interaction instead of pure freeform chat only.

This path is the closest thing to "usable for real testing", though still not finished.

### Agent / Skill / Group Model

The project already has the backbone for:

- agents;
- agent groups;
- skills;
- skill groups / loadouts;
- project-level bindings and defaults;
- different runtime roles between agents.

This is important because writing, review, extraction, and information tasks should not all collapse into one generic agent forever.

### Long-Task Runtime Foundation

The long-task side already includes significant groundwork:

- run records and runtime identity;
- queue / pause / resume / checkpoint related contracts;
- supervisor and control-plane style design;
- review / repair / diagnosis directions;
- GUI and CLI consumption paths for parts of runtime state;
- probe and regression infrastructure around long-task behavior.

This is one of the repo's strongest architectural areas conceptually, but also one of the biggest remaining stability risks in real use.

### Book Deconstruction Foundation

The repo already contains a real deconstruction direction instead of treating follow-up writing as a manual side process:

- book deconstruction project flow;
- follow-up route planning;
- derived-project creation groundwork;
- deconstruction output persistence;
- continuity-oriented follow-up documents and assets.

This is not complete yet, but it is no longer just an idea.

### Project Information Layer

The project has started building a shared information substrate for:

- project assets;
- style and expression constraints;
- reference extraction outputs;
- research-oriented notes and reusable knowledge directions;
- future knowledge-card and structured reference workflows.

This matters because the system should remember and reuse information instead of repeatedly improvising from partial context.

## What Is Only Partial, Experimental, Or Still Missing

These areas should **not** be mistaken for finished capabilities.

### Long Autonomous Writing Stability

This is still the biggest unresolved product issue.

Architecture exists, but we still need more confidence in:

- stable multi-chapter continuation;
- reliable retry / pause / recovery behavior;
- stronger unattended scheduling behavior;
- better review and constraint enforcement during long runs;
- fewer cases where a workflow looks started but does not advance correctly.

### CLI

The CLI is no longer just a placeholder, but it is still incomplete.

What remains:

- fuller command coverage;
- better operator ergonomics;
- a more complete parity story with shared runtime capabilities;
- clearer workflows for automation and diagnostics.

### TUI

Not started yet.

The likely order remains:

1. continue stabilizing GUI and shared core,
2. finish the CLI baseline,
3. only then evaluate whether a TUI is worth building.

### Docker

Docker support is planned, especially for long-running and extraction-oriented workflows, but it is not finished.

### Information Extraction / Reusable Knowledge

This is a major active direction, not a finished subsystem.

Still incomplete:

- robust reference extraction from imported works;
- reusable structured knowledge outputs for future projects;
- stronger source retention and traceability;
- better balance between project-local knowledge and reusable shared knowledge;
- broader information workflows for research-heavy writing.

### Advanced Novel-Specific Modes

Some directions have been analyzed heavily but are not fully implemented:

- alternate lines / IF branches;
- side-route or supporting-character viewpoint branches;
- stronger style extraction and reusable style knowledge;
- deeper fanfiction / derivative-work information workflows;
- richer element embedding and extraction, such as mythology, astrology, symbolic systems, naming systems, and cultural structures;
- explanation / summary / commentary style workflows for existing text.

## Project Innovations And Design Bets

These are the most important ideas this repository is already exploring.

### 1. Project-As-Workspace Instead Of Prompt-As-Unit

The core unit is not "one prompt", but a project with files, assets, constraints, references, runtime state, and reusable knowledge.

### 2. Shared Core Across GUI And CLI

The GUI and CLI are not meant to become two separate logic stacks. The project is explicitly organized so that both shells consume shared core contracts.

### 3. Constraint Layer As First-Class Infrastructure

Constraints are not treated as random prompt fragments only. The project is trying to make project constitution, mode guidance, style guidance, and expression constraints into stable reusable layers.

### 4. Long-Task Runtime As A Real Runtime Problem

Long generation is not being treated as "just call the model many times". The design already moves toward explicit runtime identity, supervision, checkpoints, pause/resume, diagnosis, and recovery.

### 5. Deconstruction And Follow-Up As Part Of The Same System

Book deconstruction, follow-up continuation, and derivative writing are being shaped as first-class workflows connected to the same project and information model.

### 6. Information Reuse Over Context Repetition

The direction is to persist useful information into project assets and future structured stores, rather than asking the model to remember everything from raw chat history every time.

## Roadmap

The most important next steps are roughly:

### Near-Term

- continue stabilizing long-task behavior;
- continue fixing real user-flow issues in the GUI;
- improve approval / permission continuity;
- strengthen session continuity and context handling;
- keep reducing leftover development artifacts that leak into user experience.

### Mid-Term

- finish the CLI baseline;
- complete more of the reference extraction and reusable knowledge pipeline;
- improve multi-agent role separation in real workflows;
- harden deconstruction -> derived project -> continuation flow;
- make information collection and research invocation more reliable.

### Later

- Docker-oriented long-running runtime shape;
- broader structured knowledge workflows;
- better import / ingestion coverage;
- optional TUI exploration;
- more specialized project types and transformation paths.

## Repository Layout

```text
apps/
  novel_agent_app/       Flutter GUI application
  novel_agent_cli/       CLI application in progress

packages/
  novel_agent_core/      shared domain contracts and workflow logic
  novel_agent_adapters/  storage, provider, runtime, and host adapters

docs/                    architecture, analysis, task-order, audit, and handoff docs
tools/                   repo utilities, probes, scanners, and helper scripts
local/                   local private files, ignored from git
dist/                    local packaging outputs, ignored from git
```

## Build And Run

Install Flutter first, then:

```powershell
cd apps/novel_agent_app
flutter pub get
flutter analyze
flutter run
```

Release builds:

```powershell
flutter build windows --release
flutter build apk --release
```

Current release-signing behavior is explicit. Android release packaging depends on local signing configuration being provided by the environment.

## Security And Local Secrets

Do not commit:

- API keys;
- provider credentials;
- `.env`-style local secret files;
- local probe configs with real credentials;
- ad-hoc experimental files that contain private data.

Sensitive local material should stay under ignored local paths such as `local/`.

## About The Docs

This repository currently contains a large amount of design, audit, task-order, and handoff documentation because the project has been evolving quickly and many subsystems were stabilized through structured multi-session work.

That documentation is useful for development, but it also means the repo is still more "active workshop" than "minimal polished OSS package".

## License

Apache License 2.0. See [LICENSE](LICENSE).

## Contribution Notes

Useful contributions right now are the boring but valuable kind:

- stability fixes;
- better runtime verification;
- cleaner responsibility boundaries;
- GUI usability improvements;
- better information persistence and reuse;
- stronger tests around real workflow behavior;
- cleanup of leftover development rough edges.

The best contributions for this stage are the ones that make the system more truthful, more stable, and less magical.
