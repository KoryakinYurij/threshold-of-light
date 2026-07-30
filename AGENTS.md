# AGENTS.md

## Agent skills

### Issue tracker

GitHub Issues in this repository. See `docs/agents/issue-tracker.md`.

### Triage labels

Five canonical roles: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context layout. `CONTEXT.md` + `docs/adr/` for ADRs. See `docs/agents/domain.md`.

### Development handbook

Comprehensive guide for game development with AI assistants. See `docs/research/game-dev-handbook.md`.

### Godot 4.7 + genre supplement

Godot 4.7 / GDScript specifics, roguelite run structure, and project-technical details. See `docs/research/godot-47-supplement.md`.

### Design & release supplement

Game-design and production companion: extraction risk/reward math, economy faucet/sink design, StS-style graph generation invariants, game feel, 2D lighting in Compatibility renderer, localization, playtesting, and Steam/itch.io release path. See `docs/research/design-and-release-supplement.md`.

### Production & AI-workflow supplement

Production pipeline (prototype vs vertical slice, phase mapping), solo tool stack with licenses, CI/CD reference (gdtoolkit + GUT + Godot CI + Butler), production-grade SaveManager reference, anti-patterns, and the project's AI prompt library. See `docs/research/production-and-ai-workflow-supplement.md`.

### Required MCP Server: godot-mcp
**CRITICAL FOR ALL AGENTS:** Working in this repository requires the **`godot-mcp`** server ([Coding-Solo/godot-mcp](https://github.com/Coding-Solo/godot-mcp)). It bridges the AI agent with Godot 4.7, allowing process execution, scene launching, and real-time debug log capture.
- Root configuration file: `.mcp.json`
- Command: `npx -y @coding-solo/godot-mcp`
- Skill reference: `.agents/skills/godot-mcp-setup/SKILL.md`

### Godot 4 Agentic Skills (thedivergentai/gd-agentic-skills)
Full collection of **97 audited Godot 4.5+ skills** located in `.agents/skills/`. Includes:
- **Core GDScript & Architecture:** `godot-gdscript-mastery`, `godot-autoload-architecture`, `godot-signal-architecture`, `godot-resource-data-patterns`, `godot-save-load-systems`, `godot-scene-management`.
- **2D Gameplay & Physics:** `godot-characterbody-2d`, `godot-2d-physics`, `godot-combat-system`, `godot-camera-systems`, `godot-input-handling`, `godot-tilemap-mastery`, `godot-2d-animation`.
- **Genre & Systems:** `godot-genre-roguelike`, `godot-procedural-generation`, `godot-inventory-system`, `godot-dialogue-system`, `godot-quest-system`, `godot-state-machine-advanced`, `godot-audio-systems`, `godot-shaders-basics`.
- **UI & Layouts:** `godot-ui-containers`, `godot-ui-theming`, `godot-ui-rich-text`.
- **Quality & Optimization:** `godot-testing-patterns`, `godot-performance-optimization`, `godot-export-builds`, `godot-debugging-profiling`.

### Engineering workflow skills (mattpocock/skills)

These skills are loaded from `.agents/skills/` and follow the Matt Pocock engineering workflow.

#### User-invoked orchestrators

- `/ask-matt` — router over all skills; use when unsure which skill fits.
- `/grill-me` — sharpen a plan/design with a relentless interview (no codebase).
- `/grill-with-docs` — same interview, but writes ADRs and glossary into `CONTEXT.md` and `docs/adr/`.
- `/handoff` — compact the current conversation into a handoff document for another agent.
- `/prototype` — throwaway prototype to answer a design question.
- `/research` — delegate reading legwork to a background agent, returns a cited Markdown file.
- `/teach` — teach the user a new skill or concept within this workspace.

#### Model-invoked discipline

- `/tdd` — test-driven development; red-green-refactor loop.
- `/diagnosing-bugs` — diagnosis loop for hard bugs and performance regressions.
- `/codebase-design` — deep-module vocabulary and seam design.
- `/domain-modeling` — sharpen project domain language and record ADRs.
- `/improve-codebase-architecture` — scan for deepening opportunities.
- `/implement` — implement a piece of work based on a spec or tickets.
- `/code-review` — review changes since a fixed point along Standards and Spec axes.
- `/resolving-merge-conflicts` — resolve in-progress git merge/rebase conflicts.
- `/triage` — move issues through triage roles and write agent-ready briefs.
- `/to-spec` — turn conversation into a spec and publish to issue tracker.
- `/to-tickets` — break a plan into tracer-bullet tickets with blocking edges.
- `/wayfinder` — plan huge chunks of work as a shared map of investigation tickets.
- `/setup-matt-pocock-skills` — scaffold per-repo configuration for the engineering skills.

#### Support skills

- `/writing-great-skills` — reference for writing and editing skills.

### Usage notes

- Run `/setup-matt-pocock-skills` once per repo to configure issue tracker, triage labels, and doc layout.
- Use `/ask-matt` when unsure which skill to use.
- Skills in `.agents/skills/` are taken from `mattpocock/skills` (MIT license).
