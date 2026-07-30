# Domain docs

This repo uses a **single-context** layout.

- `CONTEXT.md` — project-wide domain terminology, ubiquitous language, and architectural decisions.
- `docs/adr/` — Architecture Decision Records.

## Consumer rules

- Read `CONTEXT.md` before editing engine-specific code or adding new systems.
- Add an ADR to `docs/adr/` when making a decision that changes engine architecture, module boundaries, or public interfaces.
- Keep `CONTEXT.md` current; stale context is worse than no context.
