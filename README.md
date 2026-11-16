# Amber Ascent

C64-hangulatú, borostyán-fekete monitoros platformer (HaxeFlixel 6.2.1, HTML5). Gyémántokat gyűjtesz, kulcsot hozol a toronyból, ellenségekre ugrálsz, és eljutsz az ajtóig. 5 generált pálya, MOD-szerű (Amiga / C64) kódból szintetizált zene és hangok, nincsenek kép- vagy hangfájlok.

## Irányítás
| | |
|---|---|
| Mozgás | nyilak / WASD (kontroller: D-pad, bal pálca) |
| Ugrás | Z / Space / Fel / C (kontroller: A) |
| Szökellés (dash; THRUSTER kell) | X / Shift / K (kontroller: X, B) |
| Lövés (BLASTER kell) | V / J / Ctrl (kontroller: Y) |
| Repülés (JET CELL) | az ugrás gomb nyomva tartva a levegőben |
| Fal-kapaszkodás / fal-ugrás (CLAWS kell) | a fal felé tartva + ugrás |
| Lefelé a platformról | Le + ugrás |
| Szünet / visszaállás ellenőrzőpontra | P vagy Esc / R |

## Játékmenet: alkatrész-küldetések
- A robot **csupaszon** indul: lassú, csak picit ugrik, vak (nincs szem-fény), nincs mag-fény. Minden pályán **alkatrészeket** kell megtalálni (a HUD tetején a foglalatok, a pálya elején a küldetés listája); az ajtó csak akkor nyílik, ha mind megvan.
- Az alkatrészek **képességeket** adnak és látszanak a roboton: LEGS (ugrás, futás), VISOR (alkatrész-iránytű), THRUSTER (dash), CLAWS (fal-kapaszkodás és fal-ugrás), BLASTER (lövés); a CORE / CHIP / GEAR / ANTENNA csak küldetés-alkatrész. A birtokolt alkatrészek pályák között megmaradnak, halál után a pálya elejének állapotára állnak vissza.
- **Küldetés-szobák** (pályánként receptek, `LevelData.RECIPES`): nyitott (őrökkel), torony (teljes ugrás), kút (fal-ugrás kell a kijutáshoz), kamra (repedezett falat ki kell lőni), égi platform (a szobában JET CELL: korlátozott ideig repülhetsz), kapu + nyomólap (a lap egy magasabb platformon van).
- Ellenségre ugrás, dash és lövés is kiüti őket; a tüskés csúszómászóra nem lehet ráugrani. Gyémántok: opcionális pontok (mind: +500).
- Különleges platformok: **leszakadó híd** (2. pályától: a ráállás után lehullik, később visszatér) és **mozgó platform** (3. pályától).

## Megjelenés és hang
- A pixel art C64 szürke-lépcsőkben készül kódból (`Art.hx`), a borostyán színt a `AmberShader.hx` adja (kamera-szűrő: fényesség → borostyán, ragyogás, pásztázó-vonalak, hordó-torzítás, vibrálás).
- `Audio.hx` / `Music.hx`: 8 bites, 22 kHz-es, A500-szerű szűrt hullámformák; a zene 4 csatornás tracker-minta (arpeggio-akkord 50 Hz-es tickekkel, Amiga-sztereó).

## Fejlesztés
- Fordítás: `powershell -ExecutionPolicy Bypass -File scripts/build.ps1` (`-Test`: egyből a játék indul, `window.__ps`; `?level=N` a pályát választja).
- Futtatás: `scripts/play.ps1` (szerver a 3220-as porton, a hálózaton is).
- Tesztek (fejnélküli Edge, `tests/cdp-lib.ps1`): `shot.ps1` (képernyőkép + állapot), `tower.ps1`, `jump.ps1` (ugrásmagasság), `levels.ps1` (mind az 5 pálya betölt), `gl.ps1`.
- A pálya-generátor (`LevelData.hx`) a hős képességeire méretezett szegmensekből épít (ugrás ~3,8 csempe magas, ~4 csempe széles); a mag a pálya sorszáma.
