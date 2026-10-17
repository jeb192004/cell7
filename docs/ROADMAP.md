# Cell 7: Uprising - roadmap

Cast key: Kesh = Ezra, Renn = Kanan, Brix = Zeb, Fuse = Sabine, Val = Hera, Gasket = Chopper. The Ghost = the **Vagabond-9**.

## Level list (on-screen name = file)
| Level | File | Who you play |
|---|---|---|
| 1-1 Salt Flats | level_01 | Kesh |
| 1-2 Highway Run | level_02 | Kesh |
| 1-3 Town Rooftops | level_03 | Kesh |
| 1-4 Highway Escape | level_04 | Kesh |
| 1-5 The Belt | level_05 | ship |
| 2-1 The Distraction | level_2_1a | Brix + Renn (swap) |
| 2-2 The Detonators | level_2_1c | Fuse |
| 2-3 The Data Run | level_2_1b | Kesh |
| 2-4 The Vents | level_2_2 | Kesh |
| 2-5 The Cinder Mines | level_2_3 | Kesh |
| 2-6 The Catwalk | level_2_4 | Kesh |

`level_2_1.tscn` is the old single-level 2-1: not in the select or the story flow; safe to delete.

## To do
- **Crew page back button:** make it clickable; it does not work on touch.
- **Fuse combat level (eventually):** her own fight in a later episode.
- **Pickups / cosmetic unlocks (on hold):** undecided. No power-ups that need balancing.
- **A level below the street (later):** set the level's `bottom` (for example 700) and build downward with stairs / decks / lift.
- **Test on devices:** run Chapter 2 on the Retroid Pocket 5 and the S25 (touch buttons, speed, camera).
- **Windows build** (when asked).

## Level building notes
- Multi-floor: `multi_floor = true`, `top` negative; use `stairs.gd`, `deck.gd`, `elevator.gd`. Optional `zoom` and `bottom` on the level.
- `barrier.gd`: solid crate you jump over; blocks Wardens' sight, shots and patrols. The hide-behind crates are still Cover.
