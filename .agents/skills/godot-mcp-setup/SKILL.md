---
name: godot-mcp-setup
description: Instructions for checking, connecting, and using the godot-mcp server to run, debug, and inspect Godot projects.
---

# Godot MCP Setup & Integration Skill

## Overview
This project uses **Coding-Solo/godot-mcp** (`@coding-solo/godot-mcp`) as a Model Context Protocol (MCP) server to allow AI agents to interface directly with the Godot engine.

## Agent Mandate
When starting work on this codebase, **every AI agent must ensure that `godot-mcp` is installed and active**.

## MCP Configuration
The repository contains a standard `.mcp.json` file in the root directory:
```json
{
  "mcpServers": {
    "godot": {
      "command": "npx",
      "args": ["-y", "@coding-solo/godot-mcp"],
      "env": {
        "GODOT_PATH": "godot"
      }
    }
  }
}
```

## How Agents Use `godot-mcp`
- **Run project / scene:** Use MCP tools to launch the Godot editor or run specific `.tscn` scenes in headless or windowed mode.
- **Capture console logs:** Intercept debug output, `push_error()`, and runtime stack traces directly from Godot.
- **Inspect node trees:** Query active scene nodes and resources without guess-work.
