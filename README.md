# Cell 7: Uprising

An original 2D pixel-art side-scroller about Cell 7, a small rebel crew resisting an occupying empire. Built in Godot 4.4 (GDScript) for the Retroid Pocket 5 handheld; it also plays on PC/Mac with a keyboard.

Status: work in progress (working title). Chapter 1 is playable (on foot, a speeder-bike chase and a space battle); chapter 2 is playable with placeholder art. The story is in [docs/STORY.md](docs/STORY.md).

## Run it
1. Install [Godot 4.4.x](https://godotengine.org/download).
2. Open `project.godot` in the editor and press F5 (F6 plays just the open scene).
3. Display: 480x270 internal resolution, integer-scaled to 1920x1080.

## Controls
| Action | Retroid Pocket 5 | Keyboard |
|---|---|---|
| Move | stick / d-pad | arrows / WASD |
| Jump | B | Space / K |
| Shoot | Y or R1 | J / X |
| Sprint | hold L1 or L2 | Shift |
| Crouch | hold Down | hold Down |
| Hide at a crate | Up at a crate | Up at a crate |
| Pause | Start | P / Esc |

Bindings live in `scripts/controls.gd`.

**Touch:** on phones/tablets an on-screen pad (d-pad, RUN on/off toggle above it, JUMP, FIRE, pause) appears automatically and hides when a gamepad is used. The pad hides on the title and on any paused screen (pause menu, story cards, tips); taps work there instead, and card prompts change to NEXT / TAP TO CONTINUE. Title > Settings > TOUCH PAD cycles AUTO / ON / OFF (F2 toggles it on PC for testing).

## Project layout
- `scenes/` and `scenes/levels/`: scenes and levels (chapter 1: `level_01`-`level_05`, chapter 2: `level_2_1`-`level_2_4`).
- `scripts/`: game code. `data/`: data-driven event lists for the bike and space levels.
- `assets/`: art and audio. `docs/`: story and art briefs.
- `tools/`: Python scripts that build sprites and levels from source sheets (`tools/src/`). Some of them regenerate scenes, so don't re-run a level generator after you've edited its scene by hand.
- `tests/`: headless test scripts.

## Tests
```
godot --headless --path . -s tests/smoke.gd
```
Other scripts in `tests/` cover individual levels and systems (stealth, shields, bike, space, chapter 2).

## Art
The art is AI-assisted pixel art (generated sprite sheets, then cleaned up, recolored and assembled by the scripts in `tools/`), plus code-drawn pieces. Some poses are still placeholders.

## License
No license yet. All rights reserved by Serpent Scripts until one is chosen.

---

## Dev notes
Godot 4.4, 480x270 internal, integer-scaled to 1920x1080 (Retroid Pocket 5).
RP5 (Retroid labels): stick/d-pad move, B jump, Y or R1 shoot, hold L1 or L2 sprint, Start pause.
  Hold Down to crouch (duck high shots), jump low shots. Hold Up while shooting to tilt the shot.
Keyboard: arrows/WASD move, Space/K jump, J/X shoot, Shift sprint, P/Esc pause.
Bindings: scripts/controls.gd
Test: godot --headless --path . -s tests/smoke.gd
Art is generated (see assets/); jump/hit poses are rough placeholders.
Stealth: crates sit in the back lane. Press Up at a crate to step behind it, walk off the end or jump to come back out front.
  Behind a 2-high stack you can stand; behind a single crate crouch (Down). You can't shoot from behind a crate, and
  slugs can't hit you there. Wardens patrol and see in a cone (shown on screen); it takes ~0.3s of seeing you before
  he reacts. Lose him for ~2.5s and he goes back to patrolling.
Crate tops: jump onto a single crate (a 2-high stack is too tall from the ground, but you can climb a crate first).
  On top, hold Down to drop behind the crate into the back lane, or Down + jump to drop off the front.

### Building levels (in the Godot editor)
- Open `scenes/levels/level_01.tscn`. Press F6 to play just that scene, F5 to play the main scene.
- Drag `scenes/warden.tscn`, `scenes/drone.tscn`, `scenes/crate.tscn` into the scene (put them under Enemies / Props to keep it tidy) and move them with the mouse.
  - Crate: set `Stack` in the Inspector (1 = crouch to hide, 2-3 = can stand). The editor shows the stack as you change it.
  - Warden: `Patrol Range` (how far he walks each side) and `Start Facing`. Drone: just place it in the air.
- `PlayerStart`, `Exit` (crossing it clears the level) and the `Checkpoint` markers are Marker2D nodes. A new checkpoint is any Marker2D put in the group `checkpoint` (Node tab > Groups).
- On the Level01 root node: `Length` (how far the world runs) and `Next Level` (scene to load after Exit).
- Ground is at y = 222. Place feet/bottom of things there (crates at y = 223).
- To make level 2: Scene > Save As `level_02.tscn`, edit, then point level 1's `Next Level` at it.
- `tools/gen_level01.py` only regenerates the starter layout. Don't run it after you've edited the scene, it would overwrite your work.

### Level 2 / Shield Warden
- `scenes/levels/level_02.tscn` (made by `tools/gen_level02.py`); level 1's `Next Level` now points to it, so the clear card shows NEXT LEVEL.
- `scenes/warden_shield.tscn`: riot shield blocks bolts from the front and he turns slowly (0.8s). Shoot his back (jump over him, or lure him past a crate).
