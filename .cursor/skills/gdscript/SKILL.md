---
name: gdscript
description: >-
  Godot 4.7+ GDScript implementation from the GD Agentic Skills library (99
  domain skills and 27 genre blueprints). Use when writing or editing .gd files,
  scenes, nodes, signals, CharacterBody2D, TileMap, resources, autoloads, UI,
  physics, animation, shaders, save/load, or any Godot API. Follow DIA: look up
  skills_index.json, then read only the matching skills/<name>/SKILL.md before
  coding. Do not implement Godot patterns from training data alone.
---

# GDScript — Godot 4.7+ Skill Hub

Project-local copy of [thedivergentai/gd-agentic-skills](https://github.com/thedivergentai/gd-agentic-skills) (`skills/`). Licensed LGPLv3; see [LICENSE](LICENSE).

This file is the **orchestrator**. Nested `skills/*/SKILL.md` files are **not** auto-loaded. Read only the ones the task needs.

## When to use

- Writing, reviewing, or refactoring GDScript (`.gd`) or Godot scenes
- Choosing Godot architecture (signals, autoloads, resources, composition)
- Implementing a Godot API (movement, physics, UI, animation, networking, export)

**When not to use:** portable game-design questions (feel, cameras, genre glue, shipping) belong to the `gamedev` skill. If both apply: this skill owns **Godot API and GDScript**; `gamedev` owns **design/discipline/genre**. Prefer this library over `gamedev/skills/godot/` for Godot code.

## DIA loop (required)

Do **not** implement from training data alone. Godot 4 APIs and landmines live in the nested skills.

1. **Discovery** — Match the request to a skill name. Grep [skills_index.json](skills_index.json) for keywords, or use the catalog below.
2. **Ingestion** — Read `skills/<name>/SKILL.md` with the file tool. Follow its "Do NOT Load" rules. Open `references/` or `scripts/` only when that skill says they are mandatory.
3. **Application** — Follow the skill chain in the header (deepest dependency first). Copy patterns from bundled `.gd` scripts; keep static typing.

Load **at most 2–3 domain skills** per task. Never bulk-read the library.

### godot-master vs domain skills

| Situation | Read |
|-----------|------|
| New project, architecture, audit, multiplayer, performance budget | `skills/godot-master/SKILL.md` (then only the references it names) |
| One feature (player move, inventory, tilemap, save) | That domain skill only |
| Engine version upgrade | `skills/godot-version-migration/SKILL.md` |

## Default GDScript rules

Always, even before a domain skill is opened:

- Target **Godot 4.7+**. Static typing: `func move(vec: Vector2) -> void:`
- Signals travel **up**; calls travel **down**. Presentation never mutates data directly.
- `Signal` / `Callable` / `Tween` (Godot 4). Use `StringName` for hot dictionary keys.
- Composition over deep `Node` inheritance. Data in `Resource` / `.tres`.
- Cache nodes (`@onready` or ready-time). Never `$Path` / `get_node()` in `_process`.

**Never:**

- `@onready` and `@export` on the same variable
- `connect("signal_name", ...)` strings — use `button.pressed.connect(...)`
- `is` then a hard cast — use `as` and null-check
- Mutate a Dictionary while iterating it
- `load()` inside `_process` / `_physics_process`
- `get_tree().root.get_node(...)` for gameplay coupling

## Catalog (pick, then read)

Paths are `skills/<name>/SKILL.md`.

**Architecture:** `godot-master`, `godot-gdscript-mastery`, `godot-project-foundations`, `godot-project-templates`, `godot-autoload-architecture`, `godot-composition`, `godot-composition-apps`, `godot-signal-architecture`, `godot-resource-data-patterns`, `godot-state-machine-advanced`, `godot-debugging-profiling`, `godot-version-migration`

**Personas / build:** `godot-analyst`, `godot-auditor`, `godot-builder`

**2D:** `godot-characterbody-2d`, `godot-2d-physics`, `godot-2d-animation`, `godot-tilemap-mastery`, `godot-camera-systems`, `godot-tweening`, `godot-particles`, `godot-shaders-basics`, `godot-animation-player`, `godot-animation-tree-mastery`

**3D:** `godot-physics-3d`, `godot-3d-lighting`, `godot-3d-materials`, `godot-3d-world-building`, `godot-navigation-pathfinding`, `godot-ai-navigation`, `godot-raycasting-queries`, `godot-procedural-generation`

**Gameplay:** `godot-combat-system`, `godot-ability-system`, `godot-inventory-system`, `godot-rpg-stats`, `godot-quest-system`, `godot-dialogue-system`, `godot-economy-system`, `godot-save-load-systems`, `godot-scene-management`, `godot-turn-system`, `godot-input-handling`, `godot-game-loop-collection`, `godot-game-loop-harvest`, `godot-game-loop-time-trial`, `godot-game-loop-waves`, `godot-mechanic-revival`, `godot-mechanic-secrets`, `godot-monte-carlo-balancer`

**UI:** `godot-ui-containers`, `godot-ui-theming`, `godot-ui-rich-text`, `godot-theme-easter`, `godot-agent-vision`

**Platforms:** `godot-audio-systems`, `godot-export-builds`, `godot-multiplayer-networking`, `godot-server-architecture`, `godot-performance-optimization`, `godot-testing-patterns`, `godot-platform-desktop`, `godot-platform-mobile`, `godot-platform-web`, `godot-platform-console`, `godot-platform-vr`

**Adapt:** `godot-adapt-2d-to-3d`, `godot-adapt-3d-to-2d`, `godot-adapt-desktop-to-mobile`, `godot-adapt-mobile-to-desktop`, `godot-adapt-single-to-multiplayer`

**Genres:** `godot-genre-platformer`, `godot-genre-action-rpg`, `godot-genre-shooter`, `godot-genre-shooter-fps`, `godot-genre-fighting`, `godot-genre-metroidvania`, `godot-genre-roguelike`, `godot-genre-survival`, `godot-genre-horror`, `godot-genre-stealth`, `godot-genre-puzzle`, `godot-genre-card-game`, `godot-genre-visual-novel`, `godot-genre-romance`, `godot-genre-tower-defense`, `godot-genre-rts`, `godot-genre-moba`, `godot-genre-open-world`, `godot-genre-racing`, `godot-genre-rhythm`, `godot-genre-sandbox`, `godot-genre-simulation`, `godot-genre-sports`, `godot-genre-idle-clicker`, `godot-genre-party`, `godot-genre-battle-royale`, `godot-genre-educational`

## Example

User: "smooth 2D player jump with coyote time"

1. Grep index → `godot-characterbody-2d`, `godot-genre-platformer`
2. Read those two `SKILL.md` files (and only those)
3. If they list dependencies (`godot-composition`, `godot-state-machine-advanced`), read those next
4. Implement typed GDScript from the bundled scripts
