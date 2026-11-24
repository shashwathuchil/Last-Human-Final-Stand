# Last Human: Final Stand

A 3D squad-shooter runner for Android (portrait), built in **Godot 4.5** with **GL Compatibility** rendering. Clone-style game in the spirit of crowd/runner shooters: a squad of runners marches up an elevated city bridge while a heavy minigunner on a side pedestal mows down the oncoming horde.

## Gameplay

- The squad auto-advances along the bridge; **drag left/right** to steer it across lanes.
- Every runner auto-fires at enemies ahead; the pedestal hero streams heavy tracer fire at the nearest threat.
- **Gates** modify the squad on the fly: `+N` adds runners, `-N` removes runners, `GOLD` turns the hero golden (big damage boost).
- Enemy crowds converge on the squad — any enemy that reaches a runner kills it. Lose all runners and the level fails.
- A **giant boss** with a numeric HP counter guards the end of each level. Kill it to win and unlock the next level.
- 10+ levels (data-driven; extend in `scripts/data.gd`), score tracking, persistent unlocks.

## Controls

| Input | Action |
|---|---|
| Drag (touch/mouse) | Move squad left/right |
| A / D or arrows (dev) | Move squad left/right |
| `-- --autoplay [level]` | Launch straight into a level (dev) |
| `-- --gamelog` | Print periodic state to stdout (dev) |

## Project layout

- `assets/models/*.glb` — all 3D models, generated procedurally in Blender 4.2
- `tools/make_assets.py` — the Blender script that generates every model (`blender -b -P tools/make_assets.py`)
- `scripts/` — game code (all GDScript, no external deps):
  - `main.gd` — app shell: menu, level select, win/lose screens
  - `game.gd` — world assembly, spawning, pooled bullets, collisions, camera
  - `squad.gd` / `runner.gd` — formation, march, firing
  - `hero.gd` — pedestal minigunner (blue → golden upgrade)
  - `enemy.gd` / `boss.gd` — horde and boss logic
  - `gate.gd` — modifier gates
  - `data.gd` — level/difficulty tables, `save.gd` — persistence, `hud.gd` — HUD
- `scenes/main.tscn` — single root scene; everything else is assembled in code

## Build / run

1. Install Godot 4.5.x.
2. Open `project.godot` and press Play — or headless: `godot --headless --path . --quit-after 300 -- --autoplay 1`.
3. Android: add an Android export preset (GL Compatibility renderer is already set), target portrait, arm64.

## Roadmap

Rigged skeletal animations (currently procedural squash/bob), SFX/music, AdMob interstitials, more environments, more gate/weapon types, AAB release build.
