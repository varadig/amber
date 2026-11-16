# Amber Ascent

C64-hangulatú, borostyán-fekete monitoros platformer (HaxeFlixel 6.2.1, HTML5). Gyémántokat gyűjtesz, kulcsot hozol a toronyból, ellenségekre ugrálsz, és eljutsz az ajtóig. 5 generált pálya, MOD-szerű (Amiga / C64) kódból szintetizált zene és hangok, nincsenek kép- vagy hangfájlok.

## Irányítás
| | |
|---|---|
| Mozgás | nyilak / WASD (kontroller: D-pad, bal pálca) |
| Ugrás | Z / Space / Fel / C (kontroller: A); változó ugrásmagasság, fal-ugrás |
| Szökellés (dash) | X / Shift / K (kontroller: X, B); kiüti az ellenséget, közben sérthetetlen; levegőben egyszer, leszállás / fal / ellenség után újra |
| Lefelé a platformról | Le + ugrás |
| Szünet / visszaállás ellenőrzőpontra | P vagy Esc / R |
| Teljes képernyő | F |

## Játékmenet
- **Ellenségre ugrás (stomp):** a slime és a repülő legyőzhető rálépéssel (pattanás, nyomva tartott ugrásnál magasabbra; a levegőben láncolt találatok szorzót adnak). A tüskés csúszómászóra nem lehet ráugrani, csak a szökellés üti ki.
- **Fal-csúszás és fal-ugrás:** a függőleges aknákból (kutak) így lehet kimászni.
- **Torony:** minden pályán egy egyirányú platformokból épített torony tetején van a kulcs; az ajtó csak vele nyílik.
- **Szívek / ellenőrzőpontok:** 3 szív; leesés vagy sérülés levon egyet, ellenőrzőpontnál folytatod. Mind a gyémánt: +500 bónusz.

## Megjelenés és hang
- A pixel art C64 szürke-lépcsőkben készül kódból (`Art.hx`), a borostyán színt a `AmberShader.hx` adja (kamera-szűrő: fényesség → borostyán, ragyogás, pásztázó-vonalak, hordó-torzítás, vibrálás).
- `Audio.hx` / `Music.hx`: 8 bites, 22 kHz-es, A500-szerű szűrt hullámformák; a zene 4 csatornás tracker-minta (arpeggio-akkord 50 Hz-es tickekkel, Amiga-sztereó).

## Fejlesztés
- Fordítás: `powershell -ExecutionPolicy Bypass -File scripts/build.ps1` (`-Test`: egyből a játék indul, `window.__ps`; `?level=N` a pályát választja).
- Futtatás: `scripts/play.ps1` (szerver a 3220-as porton, a hálózaton is).
- Tesztek (fejnélküli Edge, `tests/cdp-lib.ps1`): `shot.ps1` (képernyőkép + állapot), `tower.ps1`, `jump.ps1` (ugrásmagasság), `levels.ps1` (mind az 5 pálya betölt), `gl.ps1`.
- A pálya-generátor (`LevelData.hx`) a hős képességeire méretezett szegmensekből épít (ugrás ~3,8 csempe magas, ~4 csempe széles); a mag a pálya sorszáma.
