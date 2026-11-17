# Ämber

C64-hangulatú, borostyán-fekete monitoros platformer (HaxeFlixel 6.2.1, HTML5). Atom-részecskéket gyűjtesz, kulcsot hozol a toronyból, ellenségekre ugrálsz, és eljutsz az ajtóig. 10 hosszú, puzzle-s pálya (alkatrészenként, társ-robotonként haladva), MOD-szerű (Amiga / C64) kódból szintetizált zene és hangok, nincsenek kép- vagy hangfájlok.

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

## A történet és a küldetés
A robot egy elhagyott gépváros roncstelepén ébred, csupaszon. **Először saját magát kell összerakni** (1–2. pálya: LEGS, CORE, VISOR, THRUSTER, CLAWS, PROCESSOR), aztán **barátokat épít** az elveszett alkatrészekből: minden társhoz 3 alkatrészt (keret, motor, fej) kell megtalálni, és a pálya közepén lévő **szerelőasztalnál** (Fel / E) összeépíteni. A társ ettől kezdve csatlakozik, és másképp segít (az ajtó csak a társ megépítése után nyílik):

| Társ | Forma | Segítség |
|---|---|---|
| **WHEELIE** (3. pálya) | apró, egykerekű | átfér a rácson (a robot nem), és a rács mögötti nyomólapra küldhető |
| **TALL** (4. pálya) | magas, hosszú lábú | ha a helyén vár, a feje platform: a magas párkányok elérhetők (rá kell ugrani) |
| **ORB** (5. pálya) | lebegő drón | felrepül, és átbillenti a magasan lévő karokat |

**Lost Vikings-szerű irányítás:** a robotok között váltani lehet (**Tab** / kontroller R1 körbe, **1-4** közvetlenül); csak az éppen irányított robot reagál a gombokra (a kamera és egy kis nyíl mutatja, melyiket). **Q** (L1): a többi robot (a hős is) követi az irányítottat / vár. **Minden robot egyenrangú:** mind felvesz gyémántot, szívet, akkut és alkatrészt, ugrik, ellenségre lép, sérül (saját szívei vannak; ha elfogynak, a mentési pontra kerül vissza), és saját különleges képessége van az X / Shift / V / J gombon:
- a hős: dash, lövés, fal-kapaszkodás, repülő-cella (az alkatrészek adják);
- **WHEELIE**: gyors; **turbó-gurulás** (X): áttöri a repedezett falat, kiüti az ellenséget; átfér a rácson;
- **TALL**: nagyot lép; **láda-emelés** (X): felveszi és leteszi a ládát; ha vár, a feje platform (bárki rá tud állni);
- **ORB**: négy irányba lebeg; **szikra** (X): átbillenti a távoli kart, ellenséget üt; csak ő éri el a lebegő alkatrészt.

**A pálya végén mindenkinek be kell érnie az ajtóhoz:** az irányított robot a Fel / E gombbal lép be (a hős csak akkor, ha minden alkatrész megvan és a társ megépült); belépés után a vezérlés a következő robotra ugrik, és a pálya akkor ér véget, ha mind bent van. R: az irányított robot a mentési pontra kerül vissza.

## Házak és számítógépek
Minden házban van egy **számítógép** a bejáratnál; a belső terem kaput csak a rajta futó **mini-játék** megoldása nyitja ki (Fel / E a gépnél, Esc: kilépés). A játék házanként más: **csúsztatós kirakó** (CIRCUIT REPAIR), **sorrend-ismétlő** (DOOR LOCK, körönként hosszabb), **párkereső memória-kártyák** (MEMORY BANK), **tank-játék** (DEFENSE SIMULATION: ellenséges tankokat lelőni; egy találat és újraindul). A kapu mögött vannak a polcok, az alkatrész, az őrök és a jutalom (akku, szív, gyémántok). Az 1., 2. és 4. pályán bónusz-ház (ARCHIVE) is van, alkatrész nélkül. A feliratok (a gép története) később bővülnek.

## Rejtvények
- **Láda + nyomólap:** a tolható ládát a nyomólapos résbe kell tolni, így a lap lenyomva marad és a kapu nyitva. (Ládák checkpointnál visszaállnak.)
- **Kulcs + zárt kapu:** a kulcs egy fülkében van.
- **Sorrend-kapcsolók:** három kapcsoló (A, B, C), a helyes sorrendet egy tábla mutatja; rossz sorrendnél visszaáll (Fel / E a kapcsolónál).
- **Áramcella + aljzat + emelő:** a cellát az aljzatba kell vinni (Fel / E), az emelő felviszi a magas polcra.
- **Rács mögötti kamra** (WHEELIE), **magas párkány** (TALL), **magas kar** (ORB), **repedezett fal** (blaszter), **kapu + nyomólap**, **épületek** belső termekkel, leszakadó és mozgó platformok.

## Robotok: állapotok
- Pályára lépéskor és új társ csatlakozásakor a **követés** az alapértelmezett (Q kapcsolja: FOLLOW / WAIT).
- Állapotok: követ (`follow`), vár (`wait`), irányított (`control`), ajtóhoz megy (`door`). Ha a követő robot a mozdulatlan hős mellett, vagy a váró robot ~4 mp-ig tétlen, véletlen **üresjárati** apróságot tesz: körülnéz (`look`), ugrik / az ORB kering (`hop`), sétál (`stroll`), vagy összenyomódva "pittyeg" (`beep`). A váró magas robot nem ugrál (platform).

## Kontroller és cheatek
- A számítógépek mini-játékai kontrollerrel is játszhatók: D-pad / bal pálca, A: művelet, B: vissza.
- **Cheat-menü** (csak debug / teszt build, F9 vagy kontroller SELECT): HERO (gyógyítás, találat, halál, ajtóhoz ugrás), PARTS (alkatrészek szintenként, mind, csupasz), BATTERY & SCREEN (akku szintek, lemerülés, elektromos kisülés, fáradtság-effekt, homályos látás), ROBOTS (társak, összehívás, követés, sebzés), WORLD (kapuk, terminálok, pálya teljesítése, következő / előző / tetszőleges pálya), ENEMIES (spawn, törlés), MINI-GAMES (mind a négy), TOGGLES (isten-mód, végtelen akku, lassítás).

## Képernyő-effektek
- A képernyő domború (CRT-hordó); **sérüléskor** erősebben kidagad, és elektromos kisülés fut át rajta (elcsúszó sávok, remegés, fényes ívek, felvillanás).
- **Lemerülő akku:** 25% alatt fokozatosan elsötétül és elmosódik a kép (fáradtság, sima átmenettel), leálláskor erősen.
- VISOR nélkül homályos a kép.

## Megjelenés és hang
- A pixel art C64 szürke-lépcsőkben készül kódból (`Art.hx`), a borostyán színt a `AmberShader.hx` adja (kamera-szűrő: fényesség → borostyán, ragyogás, pásztázó-vonalak, hordó-torzítás, vibrálás).
- `Audio.hx` / `Music.hx`: 8 bites, 22 kHz-es szűrt hullámformák. A háttérzene ambient, a Machinarium hangulatát idézi: lassú tempó (76 BPM), lebegő meleg pad, zenedoboz-arpeggio, pengetett basszus, klarinétszerű dallam és halk óraműszerű kattogás, enyhe visszhanggal (d-moll, F-dúr híd; ~100 mp, hurkolva).

## Fejlesztés
- Fordítás: `powershell -ExecutionPolicy Bypass -File scripts/build.ps1` (`-Test`: egyből a játék indul, `window.__ps`; `?level=N` a pályát választja).
- Futtatás: `scripts/play.ps1` (szerver a 3220-as porton, a hálózaton is).
- Tesztek (fejnélküli Edge, `tests/cdp-lib.ps1`): `shot.ps1` (képernyőkép + állapot), `tower.ps1`, `jump.ps1` (ugrásmagasság), `levels.ps1` (mind az 5 pálya betölt), `gl.ps1`.
- A pálya-generátor (`LevelData.hx`) a hős képességeire méretezett szegmensekből épít (ugrás ~3,8 csempe magas, ~4 csempe széles); a mag a pálya sorszáma.

## Pályák szerkesztése (Tiled)

A pályák a `levels/levelN.tmj` fájlokban vannak, [Tiled](https://www.mapeditor.org)-ben szerkeszthetők (valós sprite-előnézettel). VS Code: *Run Task → Open levels in Tiled*,
mentés után *Build HTML5*. Részletek, objektumosztályok: [docs/LEVELS.md](docs/LEVELS.md).
