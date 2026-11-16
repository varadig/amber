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
- Minden alkatrésznek **hatása van a játékra**, a hiánya pedig hátrány; ugyanazt a típust újra megtalálva (II. szint) erősödik:

| Alkatrész | Hatás | Nélküle |
|---|---|---|
| LEGS | teljes ugrás, gyors futás (II.: magasabb, gyorsabb) | csak szökdécsel, lassú |
| CORE | szívek: +1 alkatrészenként (max 5) | csak 2 szív |
| VISOR | éles látás (LENS, II.: a rejtett falak villognak, az alkatrészekről szikrák szállnak) | homályos, sötét, zajos kép |
| THRUSTER | dash (BOOSTER, II.: két dash egy ugrásra) | nincs dash |
| CLAWS | fal-kapaszkodás és fal-ugrás | nincs |
| BLASTER | lövés, repedezett falak kilövése (CANNON, II.: gyorstűz) | nincs |
| PROCESSOR (CHIP) | gyors, pontos vezérlés (CIRCUIT, II.: még fürgébb) | nehézkes mozgás és késve reagáló ugrás |
| SERVOS (GEAR) | légi irányítás, erősebb pattanás a stomp után | a levegőben alig irányítható |
| ANTENNA | radar-sáv (alul), alkatrész-iránytű; II.: az ellenségeket is mutatja | nincs térkép |
| JET CELL | 5 mp repülés (ugrás nyomva tartva) | - |

- **Küldetés-szobák** (pályánként receptek, `LevelData.RECIPES`): nyitott (őrökkel), torony (teljes ugrás), kút (fal-ugrás kell a kijutáshoz), kamra (repedezett falat ki kell lőni), égi platform (a szobában JET CELL: korlátozott ideig repülhetsz), kapu + nyomólap (a lap egy magasabb platformon van).
- **Akku:** a kijelző a bal felső sarokban (ikon + 10 blokk) az idővel és a műveletekkel fogy (repülés, dash, lövés többet visz); 20% alatt villog és sípol. Lemerülve a robot ~4 mp-re leáll (nem irányítható, sötét kép), majd 18%-kal újraindul. **Rejtett akkupakkok** (+35%) vannak fülkékben (két egymás fölötti kis platform), szakadékok párkányain és az épületekben; az ANTENNA II. szintje a radaron mutatja őket.
- **Épületek:** a felszíni ajtónál Fel / E (kontroller: D-pad fel) gombbal be lehet lépni: a belső terem a talajba van vájva (téglafal, polcok, őrök, benne az alkatrész, akkupakkok); a bal oldali belső ajtó a kijárat. A talajszint is változik (dombok, völgyek, lépcsők), így a pálya felfelé és lefelé is halad.
- **Látványos felvétel:** alkatrésznél lassítás, táguló gyűrűk, a nagy ikon középre pattan, majd a HUD foglalatába repül.
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
