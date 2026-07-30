# ADR-001: Engine and toolchain choice

## Status

Accepted

## Context

Нужно выбрать движок и стек для 2D игры с hub-builder и action-roguelite экспедициями. Критерии: zero licensing risk, AI-assisted development friendly, typed scripting, data-driven architecture, small binary size, text-based serialization.

## Decision

- Engine: Godot 4.7.x stable
- Language: GDScript 2.0 with static typing
- Save format: JSON via ConfigFile for MVP
- No external dependencies for core loop
- Compatibility renderer for Windows-first export

## Consequences

### Positive

- MIT license, zero royalties, zero subscription risk.
- Текстовая архитектура (`.tscn`, `.gd`, `.tres`) читаема AI-агентами и инструментами.
- GDScript Python-подобный, LLM пишет его точнее, чем C# или C++.
- Небольшой размер движка (~164 MB), быстрый старт редактора.
- Scene/Node/Signal архитектура хорошо маппится на data-driven подход.
- Custom Resources дают Inspector-редактируемые определения для модулей, врагов, модификаторов.

### Negative

- Экосистема ассетов меньше, чем у Unity.
- Консольные порты требуют third-party инструментов.
- Нет встроенного AI-ассистента в редакторе (используем внешние MCP/plugins).
- Для сложного AAA-3D Godot 4.x пока не на парах с Unreal, но это не цель проекта.

## Alternatives considered

- Unity 6 — отличная экосистема, но subscription pricing после $200K дохода, Runtime Fee trust deficit, бинарная сериализация сцен усложняет AI-assisted разработку.
- Unreal Engine 5 — лучшая 3D-визуализация, но steep learning curve, C++, большой бинарник (>100 GB), избыточен для 2D MVP.
