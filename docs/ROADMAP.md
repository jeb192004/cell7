# Cell 7: Uprising - roadmap

Cast key: Kesh = Ezra, Renn = Kanan, Brix = Zeb, Fuse = Sabine, Val = Hera, Gasket = Chopper. The Ghost = the **Vagabond-9**.

## Level list (on-screen name = file)
| Level | File | Who you play |
|---|---|---|
| 1-1 Salt Flats | level_1_1 | Kesh |
| 1-2 Highway Run | level_1_2 | Kesh |
| 1-3 Town Rooftops | level_1_3 | Kesh |
| 1-4 Highway Escape | level_1_4 | Kesh |
| 1-5 The Belt | level_1_5 | ship |
| 2-1 The Distraction | level_2_1 | Brix + Renn (swap) |
| 2-2 The Detonators | level_2_2 | Fuse |
| 2-3 The Data Run | level_2_3 | Kesh |
| 2-4 The Vents | level_2_4 | Kesh |
| 2-5 The Cinder Mines | level_2_5 | Kesh |
| 2-6 The Catwalk | level_2_6 | Kesh |
| 3-1 Cargo Bay 7 | level_3_1 | Kesh |
| 3-2 Hold the Gate | level_3_2 | Brix + Renn (swap) |
| 3-3 Loading Up | level_3_3 | Kesh (survive 45 s, Warden waves) |
| 3-4 The Sale | level_3_4 | Kesh |
| 3-5 Titan Strider | level_3_5 | Renn (boss) |
| 3-6 Strider Trap | level_3_6 | Fuse (boss) |
| 3-7 Corvane | level_3_7 | Brix (boss) |

The old single-level 2-1 (and stale copies of the old chapter 1 names) are in `_to_delete/`: safe to delete.

## To do
- **Chapter 3 (in progress, one level at a time):** 3-1 Cargo Bay 7 built. 3-2 to 3-5 built (walker art: tools/walker_sheet.jpg). Next:, 3-3 Loading Up (survive timer), 3-4 The Sale (cards), 3-5 Titan Strider (boss), 3-6 Corvane (Brix duel, ends in a cutscene where Kesh uses the Current to push Corvane; needs a Current sprite for Kesh).
  - Plan: 3-3 Loading Up (Kesh, crates aboard, survive timer), 3-4 The Sale (Lantern Rest, cards, Gasket's open comm brings the Wardens), 3-5 Titan Strider (Renn + Val boss), 3-6 Corvane (Brix duel, Kesh Current push cutscene). See STORY.md.
- **Fuse combat level (eventually):** her own fight in a later episode.
- **Pickups / cosmetic unlocks (on hold):** undecided. No power-ups that need balancing.
- **Weapon drops (idea, later chapter):** temporary pickups from Wardens or crates (rifle, scatter, grenades). Limited ammo, lost on death or level end, base weapon always the fallback. Same shoot pose, different shot. Renn needs new frames for any gun.
- **A level below the street (later):** set the level's `bottom` (for example 700) and build downward with stairs / decks / lift.
- **Test on devices:** run Chapter 2 on the Retroid Pocket 5 and the S25 (touch buttons, speed, camera).
- **Windows build** (when asked).

## Level building notes
- Multi-floor: `multi_floor = true`, `top` negative; use `stairs.gd`, `deck.gd`, `elevator.gd`. Optional `zoom` and `bottom` on the level.
- `barrier.gd`: solid crate you jump over; blocks Wardens' sight, shots and patrols. The hide-behind crates are still Cover.
- `hull.gd`: solid steel block for floors at any height, walls and pit sides (origin = middle of the top; `width`, `thick`). Set the level's `ground = false` and build the floor out of Hulls to get sunken floors and raised floors. Set `bottom` so the camera can see the low floors.
- Climbing a wall: stagger one-way Decks (ledges) about 38 px apart, ~80 wide, left and right of each other. Kesh jumps about 54 px; 44 or more is too tight.
- A fall of more than 150 px costs a pip. Down + Jump only drops through a Deck above y = 215.
- `tools/gen_level_31.py` builds 3-1 as an example; edit the lists and rerun, or just move things in Godot.
- Bomber (`bomber.tscn`): a drone that blinks red, dives at you and blows up (one pip, small blast). One shot brings it down; hiding behind a crate protects you. Place it where a drone would go (about 80 px above the floor). Its art is a recolour of the drone, so replace `assets/bomber.png` when you have better.
