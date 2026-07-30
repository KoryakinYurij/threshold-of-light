# CONTEXT.md

## Project

Godot 4.x game project. Target platforms: PC first, potential mobile/console later.

## Language

Primary: GDScript (Godot 4.x syntax, static typing preferred).
Secondary: C# (.NET 8) if performance-critical systems require it.

## Architecture

- Scene-based composition: each game system lives in its own scene.
- Signals for decoupled communication between nodes.
- Autoloads for global managers (game state, audio, input).
- Resources for data-driven design (items, stats, dialogue).

## Naming

- Scenes: PascalCase (e.g., `PlayerController.tscn`)
- Scripts: PascalCase matching attached node (e.g., `player_controller.gd`)
- Groups: snake_case (e.g., `enemies`, `interactables`)

## Version

Godot 4.7.x stable.
