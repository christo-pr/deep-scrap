---
name: gamedev
description: >-
  Cross-engine game-development router and catalog from awesome-gamedev-agent-skills
  (73 skills: engines, disciplines, genres, workflows). Use when designing gameplay,
  game feel, cameras, AI, save systems, procedural generation, art direction, UI/UX,
  level design, performance, publishing, or when the user mentions platformer,
  roguelike, RPG, FPS, tower defense, card game, visual novel, survival, or puzzle.
  Detect the engine, pick the minimal skills, then read only those SKILL.md files
  before acting.
---

# Game Dev — Router + Skill Catalog

Project-local copy of [gamedev-skills/awesome-gamedev-agent-skills](https://github.com/gamedev-skills/awesome-gamedev-agent-skills). Apache-2.0; see [LICENSE](LICENSE) and [NOTICE](NOTICE).

This file is the **entry router**. Nested skills are **not** auto-loaded. Full algorithm: [router/SKILL.md](router/SKILL.md). Fingerprints: [router/references/engine-detection.md](router/references/engine-detection.md). Trigger table: [router/references/routing-table.md](router/references/routing-table.md).

## When to use

- Start of a game-development request: player, level, enemy, shader, UI, save, multiplayer, input, audio, AI, dialogue, procgen, assets, shipping
- When the user names a genre or asks which skill to use

**When not to use:** once the right nested skill is loaded and the task stays inside it, work from that skill. Re-route only on a pivot.

**Overlap with `gdscript`:** this project is Godot (`project.godot`). For Godot API / `.gd` implementation, prefer the `gdscript` skill library. This skill owns portable design (feel, cameras, AI models, art direction, shipping) and non-Godot engines. Genre glue here is fine; then hand Godot code to `gdscript`.

## Routing algorithm

1. **Detect engine** — at most one engine. This repo has `project.godot` → **Godot**.
2. **Classify task** — additive disciplines + at most one genre + workflows.
3. **Resolve** — minimal set: engine skill(s) + discipline(s) + genre + workflow.
4. **Read** — only those `SKILL.md` bodies. `references/` on demand.
5. **Compose** — engine fundamentals → discipline → genre glue → workflow.
6. **Fallback** — unknown engine: ask once, else default Godot. State gaps; never invent a skill name.

Announce what you load, e.g. *"Detected Godot (`project.godot`). Loading `game-feel` + `camera-systems`; Godot jump code via `gdscript` / `godot-characterbody-2d`."*

## Engine skills (exactly one set)

| Engine | Root | When |
|--------|------|------|
| Godot 4.7 | `skills/godot/` | `project.godot` — prefer `gdscript` for implementation |
| Unity 6.3 | `skills/unity/` | `Assets/` + `ProjectSettings/ProjectVersion.txt` |
| Unreal 5.8 | `skills/unreal/` | `*.uproject` |
| Phaser / PixiJS / three.js | `skills/web-engines/` | matching `package.json` dep |
| Bevy / pygame / LÖVE / Roblox | `skills/other-engines/` | see router fingerprints |

**Godot sub-skills** (only if not using `gdscript`): `godot-gdscript`, `godot-csharp`, `godot-nodes-scenes`, `godot-signals-groups`, `godot-2d-movement`, `godot-tilemap`, `godot-physics`, `godot-ui-control`, `godot-animation`, `godot-shaders`, `godot-3d-essentials`, `godot-resources`, `godot-audio`, `godot-multiplayer`, `godot-export`

## Disciplines — `skills/disciplines/<name>/SKILL.md`

| Skill | Use when |
|-------|----------|
| `create-game-assets` | art direction, sprites, tiles, textures, UI art, 3D props |
| `game-ai` | NPC FSM, steering, pathfinding |
| `ai-behavior-trees-utility-ai` | BT runtime, blackboard, utility AI |
| `procedural-gen` | noise, seeds, dungeon/terrain |
| `dialogue-systems` | branching dialogue, Yarn/Ink |
| `save-systems` | slots, versioning, autosave |
| `audio-design` | buses, adaptive music, ducking |
| `shader-programming` | cross-engine shader concepts |
| `physics-tuning` | timestep, mass/drag, CCD, layers |
| `level-design` | whitebox, pacing, grid layout |
| `input-systems` | actions, rebind, buffering, devices |
| `game-feel` | shake, hit-stop, juice, squash |
| `game-ui-ux` | HUD, menus, safe area, focus |
| `camera-systems` | follow, deadzone, orbit, FPS cam |
| `performance-optimization` | frame budget, pooling, draw calls |

## Genres — `skills/genres/<name>/SKILL.md`

`platformer`, `roguelike`, `rpg`, `fps-shooter`, `tower-defense`, `card-game`, `visual-novel`, `survival-crafting`, `puzzle`

These orchestrate; they do not re-teach engine primitives.

## Workflows — `skills/workflows/<name>/SKILL.md`

`game-jam`, `prototype-fast`, `steam-publish`, `itch-publish`

## Read protocol

1. Do **not** pre-read skill bodies. Decide from this catalog + the request.
2. Read **only** chosen files: `skills/<category>/<name>/SKILL.md`.
3. Never bulk-load a category (do not open all of `skills/godot/`).
4. Open a skill's `references/` only when its body says to.

## Examples

| Request | Load |
|---------|------|
| "make hits feel punchy" | `game-feel` (+ `camera-systems` for shake); Godot code via `gdscript` |
| "camera should follow the player" | `camera-systems` |
| "how should save slots work?" | `save-systems` |
| "procedural dungeon roguelike" | `procedural-gen` + `roguelike`; Godot tilemap via `gdscript` |
| "publish on itch with butler" | `itch-publish` |
| "cohesive pixel-art player and enemies" | `create-game-assets` |
