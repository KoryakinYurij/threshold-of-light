# Windows Godot Development

## Verified Setup

Last verified: July 31, 2026.

- Godot `4.7.1.stable` (standard GDScript build) is installed in `D:\Tools\Godot\4.7.1`.
- Its folder is in the Windows user `PATH`; a `godot.cmd` launcher there resolves the portable executable. Open a new terminal or restart the coding agent after this setup.
- The project MCP configuration intentionally uses `GODOT_PATH=godot` rather than a machine-specific absolute path. It therefore works on a Windows machine whose `PATH` contains the selected Godot version.
- Node.js and `npx` are present. A Windows-local coding agent can start `godot-mcp` from the project configuration; its first use may download the configured npm package.

## First Open and Run

From PowerShell:

```powershell
Set-Location 'D:\Code AI\Games\Godot v1'
godot --editor --path .
```

You can also double-click `project.godot`. On the first open, Godot imports assets and creates `.godot/`; that cache is intentionally ignored by Git.

- `F5` runs the configured main scene (the whole project).
- `F6` runs the currently open scene.
- `F8` stops a running game.
- Use the bottom `Output` and `Debugger` panels to inspect errors.

## Canonical Development Environment

After T-02, **all Godot execution is Windows-only**: Godot launches, manual
playtesting, visual debugging, tests, and exports. The previous VPS/headless runs
are historical T-02 verification only. The VPS is still used as a **file mirror**
for the remote coding agent: `~/projects/godot/work/` synced via `godot-sync`
(rclone), see `~/projects/godot/AGENTS.md`. No Godot runs on the VPS.

Project root:

```text
D:\Code AI\Games\Godot v1
```

## Agent Workflow

The coding agent may run on the **VPS** working in the synced mirror
`~/projects/godot/work/` (see `~/projects/godot/AGENTS.md`) — but all Godot
commands (editor, tests, builds, exports) must run **on Windows**, from this
project root, so the project-level MCP server can start Windows Godot directly.
Never run Godot from the VPS: it has none and is too weak.

Before implementation, ask the agent to read the project instructions, the current Phase 1 scope, context, and accepted ADRs. Keep each task limited to its ticket, add tests with a pinned test addon when the first testable core system is introduced, and verify changes with Windows Godot commands plus the manual/visual check appropriate to the ticket.

## Smoke Test Result

On July 31, 2026 the following completed successfully on this Windows machine with exit code `0` and no engine warnings or errors:

```powershell
godot --headless --path . --import
godot --headless --path . --quit-after 5
```

The first import generated `assets/icon/icon.svg.import` and `scenes/main/main_menu.gd.uid`. These are project metadata, not the `.godot/` cache, so keep them in version control with their source assets/scripts.