# Cell 7: Uprising - story bible

All names are original. The arc follows the show's early episodes loosely; the skin is our own.

## Cast
- **Kesh** - scavenger kid from the salt flats of Calder. Lives in an old radio tower. Slingshot. Quick, cheeky, can talk his way out of things.
- **Renn Fox** - leader of Cell 7. A Keeper in hiding. Calm, dry humor. Can use the Current.
- **Val** - captain and ace pilot of the Vagabond-9. The crew's conscience and its planner.
- **Maren "Fuse" Holt** - demolitions and gadgets. Paints everything she blows up.
- **Gasket** - ship mechanic. Short-tempered, keeps the Vagabond-9 flying on scrap parts.
- **Brix** - muscle. Short temper, big heart, leaves Kesh behind in 2-2 and is made to go back.
- **Ursk** - tall, strong, furred people. Peaceful. The Sovereignty enslaves them to mine emberstone on Vask.
- **Head Warden Corvane** - head of the Wardens. Cold, patient, always one step behind. Not a Hunter.
- **The Grand Hunter** - leads the Hunters; never seen yet, only reported to.

## Terms
- **The Sovereignty** - the empire. **Wardens** - its masked soldiers. **Shrikes** - its fighters.
- **The Current** - the force. Flows through everything. Keepers can feel and use it.
- **Keepers** - the old guardians who used the Current. Hunted and nearly wiped out.
- **Hunters** - the Sovereignty's agents who find and kill Keepers.
- **Vask** - ash moon where the Cinder Mines are. **Emberstone** - the ore the Ursk dig.
- **The Meridian** - Sovereignty prison transport (the trap). **Lantern Rest** - outpost where Cell 7 sells and trades.

## Chapter 1 (done)
1-1 Salt Flats > 1-2 Highway Run > 1-3 Town Rooftops > 1-4 Highway Escape (bike) > 1-5 The Belt (ship). Kesh meets Cell 7 by robbing their haul, they save him from the Sovereignty, and they flee to Lantern Rest.

## Chapter 2 - "The Current"
**2-1 The Distraction.** A broker at Lantern Rest tells Cell 7 where the Ursk prison list is: the main computer of the transport Meridian. Brix and Renn make noise aboard the ship, fighting through Wardens and drones (swap between them) to pull the guards away. Multi-floor level: stairs, decks and a lift.
**2-2 The Detonators.** Fuse sneaks the ship and plants five charges on walls, computers and engines.
**2-3 The Data Run.** With the guards drawn off, Kesh takes the high route to a data terminal and steals the list. The alarm trips on the way out and he is caught carrying the data ("Too Late"). The crew leaves without him.
**2-4 The Vents.** In custody, Kesh tricks his guards and escapes the cuffs, then crawls through the vents. Meanwhile Val learns Brix left him and they go back. By the time the crew is back inside, Kesh is at the docking bay. Wardens meet them there and they fight their way out. The list points to Vask. (The crew races off in the Vagabond-9; Fuse's charges go off along the Meridian.)
**2-5 The Cinder Mines.** On Vask the Ursk dig emberstone in chains. Kesh sneaks around the fighting to open the cages. More Sovereignty soldiers pour in and there is no way out. Renn reveals he is a Keeper: every soldier fires on him and he blocks every bolt with the Arc-Blade. The crew escapes to the ship.
**2-6 The Catwalk.** Kesh runs back for a young Ursk. Val gets everyone but Kesh aboard. Alone on the catwalk, Kesh and the young Ursk face Head Warden Corvane. Renn arrives in the Vagabond-9 to save them.
**Epilogue.** The crew drops Kesh home at his tower on Calder. Renn explains the Current and offers to train him. Far away, Corvane reports to the Grand Hunter: a Keeper lives, and he is not alone.

## Mechanics each level adds
- 2-1: two playable crew (swap with Tab / Y), Renn blocks and slashes, Brix fires bursts; stairs, decks and lift.
- 2-2: Fuse plants charges; stealth.
- 2-3: climb to a terminal and hold Up to steal the data; ends with "captured".
- 2-4: vent crawl (forced crouch), then a docking-bay fight.
- 2-5: cages; press Up to free an Ursk; must free the required number to leave.
- 2-6: boss Head Warden Corvane, survive until the Vagabond-9 arrives.

## Weapons
- **Arc-Blade** - Renn's energy saber. He uses it to deflect Warden fire (not the Current). Kesh earns one later.

## Chapter 3 (in progress)
The crew is broke: no food, no fuel, no credits. A fence named Orsel offers one job, stealing a shipment of Sovereignty weapons from the port on Halven.
**3-1 Cargo Bay 7.** Fuse and Brix cross the dock's wires and send the Wardens to the wrong bay. Kesh drops in from the vents, crosses the bay (drops, a sunken pit, a wall climb, a high catwalk) and reaches bay 7. The Wardens are about to work out the mix-up.

**3-2 Hold the Gate.** The Wardens work out the mix-up and a squad runs for bay 7. Brix and Renn (swap) hold the dock while Kesh and Fuse load: gantry, dock floor, a sunken trench, stairs up to a high catwalk, and the gate. Drops and stairs only (Brix jumps about 43 px).

### Chapter 3 plan (from James's episode notes)
Skip the opening shuttle argument. Heist on Halven: Wardens sent to the wrong dock (3-1 cards), Kesh sneaks in through the vents to bay 7 (3-1), Brix distracts the Wardens when they learn the mix-up (3-2), Kesh gets the crates aboard (3-3).
Back at Lantern Rest the crew sells to the fence (Orsel) (3-4). Gasket's open comm call is overheard and the Sovereignty shows up. The crew keeps the weapons and destroys them.
Two-legged walkers touch down: Renn and Val take them on (3-5, boss). Brix fights a squad of Wardens, then Corvane one on one; Corvane beats him and, before the kill, Kesh pushes him away with the Current (3-6, ends in a cutscene; needs Kesh's push sprite).
**3-3 Loading Up.** Kesh holds bay 7 for 45 s while the loader fills the Vagabond-9; Wardens arrive from both ends (wave_spawn markers, `wave_every` / `wave_max` on the level).
**3-4 The Sale.** Lantern Rest at night. Gasket leaves the comm open during the sale, so the Wardens come. Kesh runs the market (street plus two raised walkways) back to the Vagabond-9; the crew then blows the weapons. Ends with the walkers touching down.
**3-5 Titan Strider.** Boss: a walker in Lantern Rest. Renn (blade only) fights it; Val strafes in the Vagabond-9 at 2/3 and 1/3 health. The walker shoots high/low bursts, lobs missiles onto red rings, stomps if you stand under it, and vents steam (hits count double) after a missile volley. Val is not playable (no sprites yet).

**3-6 Strider Trap.** Boss: the second Titan Strider on the landing pad. Fuse has no gun: she plants charges on glowing spots and draws the strider over them. Each blast does 7 and stuns it (strider hp 28). No Val strafes. Afterwards Corvane walks out of the smoke.
**3-7 Corvane.** Brix cuts through a squad of Wardens, then fights Corvane one on one. Corvane cannot be hurt below 10 hp: reaching it ends the fight and the cutscene plays. Corvane beats Brix, and Kesh throws him back with the Current. (Kesh uses his slingshot pose until assets/kesh_push_0.png, kesh_push_1.png ... exist; the cutscene picks them up automatically.)
