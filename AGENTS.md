# AGENTS.md

## Agent skills

### Issue tracker

GitHub Issues in this repository. See `docs/agents/issue-tracker.md`.

### Triage labels

Five canonical roles: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context layout. `CONTEXT.md` + `docs/adr/` for ADRs. See `docs/agents/domain.md`.

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
- `/wrap-up` — end-of-session cleanup, optional debrief, self-improve, commit, push.

### Usage notes

- Run `/setup-matt-pocock-skills` once per repo to configure issue tracker, triage labels, and doc layout.
- Use `/ask-matt` when unsure which skill to use.
- Skills in `.agents/skills/` are taken from `mattpocock/skills` (MIT license).
