# Ämber

**English** · [Magyar](README.hu.md)

A C64-inspired, amber-monochrome monitor platformer (HaxeFlixel 6.2.1, HTML5). Collect atom particles, bring a key down from the tower, hop over enemies, and reach the door. Ten puzzle-driven levels, progressing from part to part and companion to companion. The music and sounds are synthesized from Amiga/C64-style MOD code, and there are no image or sound files.

## Controls

| | |
|---|---|
| Move | Arrows / WASD (gamepad: D-pad, left stick) |
| Jump | Z / Space / Up / C (gamepad: A) |
| Dash (needs THRUSTER) | X / Shift / K (gamepad: X, B) |
| Shoot (needs BLASTER) | V / J / Ctrl (gamepad: Y) |
| Fly (JET CELL) | Hold the jump button in the air |
| Wall-cling / wall-jump (needs CLAWS) | Hold toward a wall + jump |
| Drop through a platform | Down + jump |
| Pause / restart from checkpoint | P or Esc / R |

## Gameplay: part missions

- The robot starts **bare**: slow, barely jumps, blind (no eye light, no core light). Each level has **parts** to find (the slots along the top of the HUD show what is still missing). The door only opens once all of them are collected.
- Every part has an **effect**, and missing it is a handicap. Finding the same type again (level II) upgrades it:

| Part | Effect | Without it |
|---|---|---|
| LEGS | full jump, faster run (II: higher and faster) | hops only, slow |
| CORE | hearts: +1 per part (max 5) | only 2 hearts |
| VISOR | sharp vision (LENS; II: hidden walls flicker, sparks fly off parts) | blurry, dark, noisy picture |
| THRUSTER | dash (BOOSTER; II: two dashes per jump) | no dash |
| CLAWS | wall-cling and wall-jump | none |
| BLASTER | shooting, destroying cracked walls (CANNON; II: rapid fire) | none |
| PROCESSOR (CHIP) | quick, precise control (CIRCUIT; II: even snappier) | sluggish movement, delayed jumps |
| SERVOS (GEAR) | air control, stronger bounce after a stomp | barely steerable in the air |
| ANTENNA | radar strip (bottom), part compass; II: also shows enemies | no map |
| JET CELL | 5 s of flight (hold jump) | - |

- **Mission rooms** (per-level recipes in `LevelData.RECIPES`): open (with guards), tower (full jump needed), well (wall-jump to get out), vault (a cracked wall must be shot), sky platform (JET CELL for a limited flight), gate + pressure plate (the plate sits on a higher platform).
- **Battery:** the gauge in the top-left corner (icon + 10 blocks) drains with time and actions (flying, dashing and shooting cost more). Under 20% it flashes and beeps. When empty the robot powers down for about 4 s (no control, dark picture), then restarts at 18%. **Hidden battery packs** (+35%) sit in niches (two small stacked platforms), on ledges over pits, and inside buildings. ANTENNA II shows them on the radar.
- **Buildings:** press Up / E at a surface door to enter. The interior is dug into the ground (brick walls, shelves, guards, the part inside). The inner door on the left is the exit. The ground height varies (hills, valleys, stairs), so the level goes both up and down.
- **Part pickup:** the robot slows, rings expand, and the large icon pops into the center before flying into the HUD slot.
- Hitting an enemy with a jump, dash or shot defeats it. Spikes cannot be jumped on. Diamonds are optional points (+500 each).
- Special platforms: a **crumbling bridge** (from level 2: falls after you step on it, returns later) and a **moving platform** (from level 3).

## Story and companions

The robot wakes up bare in the wreck field of an abandoned machine city. **First it must rebuild itself** (levels 1–2: LEGS, CORE, VISOR, THRUSTER, CLAWS, PROCESSOR). Then it **builds friends** from the lost parts. Each friend needs three parts (frame, motor, head), assembled at the **workbench** in the middle of the level (Up / E). Once built, the friend joins and helps in its own way. The door only opens after the friend is built.

| Friend | Shape | Help |
|---|---|---|
| **WHEELIE** (level 3) | small, single wheel | fits through the grate (the robot cannot), and can be sent to the pressure plate behind it |
| **TALL** (level 4) | tall, long legs | when waiting in place its head is a platform: high ledges become reachable (jump onto it) |
| **ORB** (level 5) | hovering drone | flies up and flips high levers |

**Lost Vikings-style control:** switch between robots with **Tab** (gamepad R1 cycles) or **1–4** directly. Only the controlled robot responds to input (the camera and a small arrow show which). **Q** (L1) toggles whether the others (including the hero) follow the controlled one or wait. **All robots are equal:** each collects diamonds, hearts, batteries and parts, jumps, stomps enemies, takes damage (each has its own hearts; when they run out it returns to the last checkpoint), and has a special ability on X / Shift / V / J:
- the hero: dash, shoot, wall-cling, flight cell (depends on parts);
- **WHEELIE**: fast; **turbo roll** (X): breaks cracked walls, knocks out enemies; fits through grates;
- **TALL**: takes big steps; **crate lift** (X): picks up and sets down a crate; when waiting, its head is a platform anyone can stand on;
- **ORB**: hovers in four directions; **spark** (X): flips a distant lever, hits enemies; only it can reach floating parts.

**At the end of a level, everyone must reach the door:** the controlled robot enters with Up / E (the hero only once all parts are found and its friend is built). After entering, control jumps to the next robot, and the level ends when everyone is inside. R sends the controlled robot back to the checkpoint.

## Buildings and computers

Each building has a **computer** at the entrance. The inner room's gate only opens when you solve the **mini-game** running on it (Up / E at the computer, Esc to exit). The mini-games differ per building: a **sliding puzzle** (CIRCUIT REPAIR), a **sequence repeat** (DOOR LOCK, gets longer each round), **memory card pairs** (MEMORY BANK), and a **tank game** (DEFENSE SIMULATION: shoot the enemy tanks; one hit and you restart). Behind the gate: shelves, the part, guards, and the reward (battery, heart, diamonds). Levels 1, 2 and 4 also have a bonus building (ARCHIVE) with no part. The in-game terminal texts (the story of the machine city) expand over time.

## Puzzles

- **Crate + pressure plate:** push the movable crate into the plate's slot so the plate stays down and the gate stays open. (Crates reset at checkpoints.)
- **Key + locked gate:** the key is in a niche.
- **Sequence switches:** three switches (A, B, C). A board shows the correct order. A wrong order resets them (Up / E at a switch).
- **Power cell + socket + lift:** carry the cell into the socket (Up / E), and the lift raises it to the high shelf.
- **Grate chamber** (WHEELIE), **high ledge** (TALL), **high lever** (ORB), **cracked wall** (blaster), **gate + plate**, **buildings** with interior rooms, crumbling and moving platforms.

## Robot states

- When entering a level, or when a new friend joins, **follow** is the default (Q toggles FOLLOW / WAIT).
- States: follow (`follow`), wait (`wait`), controlled (`control`), going to the door (`door`). When a following robot stands next to the motionless hero, or a waiting robot has been idle for about 4 s, it does a random **idle** gesture: looks around (`look`), hops (or the ORB circles) (`hop`), strolls (`stroll`), or squashes and beeps (`beep`). A waiting tall robot does not hop (it is a platform).

## Gamepad and cheats

- The computer mini-games also work with a gamepad: D-pad / left stick to navigate, A to act, B to go back.
- **Cheat menu** (debug/test builds only, F9 or gamepad SELECT): HERO (heal, damage, die, jump to door), PARTS (per level, all, bare), BATTERY & SCREEN (battery levels, drain, electric discharge, tired effect, blurred vision), ROBOTS (friends, summon, follow, damage), WORLD (gates, terminals, complete the level, next / previous / any level), ENEMIES (spawn, clear), MINI-GAMES (all four), TOGGLES (god mode, infinite battery, slow-motion).

## Visuals and sound

- The screen is a curved CRT: on damage it bulges more and electric discharge runs across it (shifting bands, shake, bright arcs, flashes).
- **Low battery:** below 25% the picture gradually darkens and blurs (tired effect, smooth transition), and it gets strong on power-down.
- Without VISOR the picture is blurry.
- The C64-style grey-scale pixel art is generated in code (`Art.hx`). The amber tint comes from `AmberShader.hx` (camera filter: brightness → amber, glow, scanlines, barrel distortion, flicker).
- `Audio.hx` / `Music.hx`: 8-bit, 22 kHz filtered waveforms. The background music is ambient, in the mood of Machinarium: slow tempo (76 BPM), a floating warm pad, music-box arpeggio, plucked bass, a clarinet-like melody and quiet clockwork ticks, with light reverb (D minor, F major bridge; about 100 s, looped).

## Development

- Build: `powershell -ExecutionPolicy Bypass -File scripts/build.ps1` (`-Test`: launches the game straight away, `window.__ps`; `?level=N` picks the level).
- Run: `scripts/play.ps1` (server on port 3220, also reachable over the network).
- Tests (headless Edge, `tests/cdp-lib.ps1`): `shot.ps1` (screenshot + state), `tower.ps1`, `jump.ps1` (jump height), `levels.ps1` (all 5 levels load), `gl.ps1`.
- The level generator (`LevelData.hx`) builds from segments scaled to the hero's abilities (jump ~3.8 tiles high, ~4 tiles wide); the seed is the level number.
- Requires Haxe 4.3.6 with `lime 8.3.2`, `openfl 9.5.2`, `flixel 6.2.1` (pinned in `Project.xml`). Install dependencies with `powershell -ExecutionPolicy Bypass -File scripts/setup.ps1`.
- VS Code: the `.vscode` folder has ready-made tasks (*Build HTML5*, *Run HTML5 (browser)*, *Build HTML5 (test)*, and others).
- Haxe code comments are in Hungarian; the game's UI text is in English, with a Hungarian language file in `lang/hu.json`.

## Levels

Levels live in `levels/levelN.tmj`, edited in [Tiled](https://www.mapeditor.org) (with real sprite previews). In VS Code: *Run Task → Open levels in Tiled*, then *Build HTML5* after saving. Details and object classes: [docs/LEVELS.md](docs/LEVELS.md).

## Release (itch.io)

- One step: VS Code *Run Task → Release (build + package + publish)*, or `scripts/release.ps1`. It checks the levels, builds the release, verifies there are no cheats in it, zips, and uploads.
- Without uploading: *Release (build + package, no publish)* (`-SkipPublish`).
- Page text, settings and images: `docs/ITCH.md`, `docs/itch/`.
- Uploads use itch.io's `butler`, which is downloaded on the first run. The first upload needs *This file will be played in the browser* ticked once for the html5 file.

## Leaderboard

An optional global leaderboard uses Supabase over REST. Setup and SQL: `docs/LEADERBOARD.md`. Without a configured `assets/config/leaderboard.json` the feature stays hidden.
