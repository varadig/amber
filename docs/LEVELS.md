# Pályák szerkesztése Tiled-ben

Az Amber Ascent pályái a [Tiled](https://www.mapeditor.org) térképszerkesztőben szerkeszthetők (`levels/levelN.tmj`).
A játék a Tiled JSON formátumát olvassa; a fájlok be vannak ágyazva (`Project.xml`: `assets path="levels"`), tehát **mentés után újra kell fordítani**
(VS Code: *Build HTML5*). Ha egy pályának nincs `.tmj` fájlja (vagy hibás), a játék a régi módon, a generátorból (`LevelData.generate`) építi.

A térképeken **valódi sprite-előnézet** van: a `levels/tiles.png` (terep) és a `levels/sprites/*.png` (minden objektum) a játék saját pixel artjából
készül, borostyán árnyalattal, így a Tiled-ben nagyjából úgy látszik a pálya, ahogy a játékban.

## Munkafolyamat

1. Telepítsd a Tiled-et (1.10 vagy újabb). VS Code: *Run Task → Open levels in Tiled*, vagy nyisd meg a `levels/amber.tiled-project` projektet
   (ebben vannak az objektumosztályok: legördülő listák, alapértékek).
2. Nyisd meg a pályát (`levels/level1.tmj` ...), szerkeszd, **mentsd** (Ctrl+S; nincs külön export, a `.tmj` maga a forrás).
3. Ellenőrzés: *Run Task → Validate Tiled levels* (`tests/validate-levels.ps1`).
4. Fordítás: *Build HTML5* (vagy dev build), majd próba. A `tests/tiledlevels.ps1` a betöltést ellenőrzi.
5. Új pálya: másold a `levelN.tmj`-t `level(N+1).tmj`-re (a játékban a pályák száma: `LevelData.COUNT`, nevük: `LevelData.NAMES`).

> A pályák kiindulópontját a generátor adta; a kézzel szerkesztett `.tmj`-ket a `scripts/generate-levels.ps1` **csak `-Force`-szal** írja felül.
> A script mindig újragenerálja a sprite-okat, a csempekészleteket és a Tiled projektet (*Regenerate Tiled assets*), például ha új sprite kerül a játékba.

## A térkép

- 16 × 16 px-es csempe, **56 sor** magas (`LevelData.H`), a szélesség tetszőleges. Csemperéteg-formátum: **CSV** (a Tiled alapértelmezése).
- Térkép-tulajdonságok: `name` (a pálya neve), `killRow` (ennél mélyebbre esve a hős meghal: a felszíni szakadékok alja; a belső termek ez alatt vannak),
  `seq<id>` (sorrend-rejtvény: az `id` kapcsolóinak helyes sorrendje, pl. `seq3` = `2,0,1`).
- A hős ugrása ~3,5 csempe magas, a hős ~12 × 14 px: a szakadékok és lépcsők a generált pályák mintájára méretezendők.

### Csemperétegek

| Réteg | Csempék |
|---|---|
| `solid` | 1 = talaj teteje, 2 = talaj, 3 = tégla (mind szilárd) |
| `platforms` | egyirányú platform (alulról átjárható); bármely csempe számít |

A talaj sötétítését, díszeit a játék számolja. A felszíni talaj a pálya aljáig tart (a szakadék = nincs csempe az oszlopban).

### Objektumrétegek (`buildings`, `hazards`, `puzzle`, `items`, `enemies`, `markers`)

A rétegek neve szabad (a játék minden objektumréteget beolvas, a rejtetteket és a rejtett objektumokat kihagyja). Az objektumokat az
`objects` csempekészletből húzd be (Insert Tile, T): a csempe sprite-ja látszik, az osztály és az alapértékek vele jönnek. A csempe-objektum helye a
**bal alsó sarka** (Tiled-konvenció), a játékban a sprite bal felső sarka ennek felel meg: ne méretezd át.

| Osztály | Tulajdonságok (alap) | Jelentés |
|---|---|---|
| `Spawn` | – | A hős kezdőpontja (pontosan egy kell) |
| `Door` | – | A pálya végi ajtó (pontosan egy kell) |
| `Checkpoint` | – | Ellenőrzőpont (legalább ~26 csempe távolságra egymástól) |
| `Gem`, `Heart`, `Battery` | – | Gyűjthető: kristály (pont), szív, rejtett akkupakk |
| `Part` | `icon` (0), `label`, `friend` (-1) | Alkatrész: az `icon` az alkatrész képe (0-9 a saját alkatrészek: LEGS, CORE, VISOR, THRUSTER, CLAWS, BLASTER, PROCESSOR, SERVOS, ANTENNA, JET CELL; 10-12: társ-alkatrész kerete / motorja / feje). A `friend` a társ azonosítója (0 WHEELIE, 1 TALL, 2 ORB), -1 = saját. A kijárathoz mindegyik alkatrész kell |
| `Cell` | – | Repülő-cella (korlátozott ideig repülni lehet) |
| `Key`, `PowerCell` | `id` | Kulcs a zárt kapuhoz, áramcella az azonos `id`-jú aljzatba (`Socket`) |
| `Enemy` | `kind` (WALKER / FLYER / CRAWLER) | Ellenség |
| `Spike`, `Cracked`, `Crumble` | – | Tüske; repedezett fal (a WHEELIE töri); leszakadó platform (48 px széles) |
| `Mover` | `w` (3 csempe), `axis` (x / y), `range` (px), `speed` (px/mp), `id` (-1), `active` | Mozgó platform; `id`-vel az áramcella-aljzat indítja (emelő) |
| `Gate` | `id`, `lock` | Kapu-csempe: az azonos `id`-jú nyomólap / kar / terminál nyitja; `lock` = a kulcs nyitja |
| `Plate` | `id`, `hold` | Nyomólap (`hold`: csak amíg nyomják) |
| `Lever`, `Switch`, `Socket` | `id` (Switch: `idx`, `label`) | Kar (az ORB billenti), sorrend-kapcsoló (`idx` = a kapcsoló sorszáma a `seq<id>` listában), áramcella-aljzat |
| `Crate`, `Grate` | – | Tolható láda (a TALL cipeli); rács (csak a WHEELIE fér át) |
| `Bench` | `comp` (0) | Szerelőasztal: a `comp` társ itt építhető össze |
| `Terminal` | `id`, `game` (0-3) | Számítógép mini-játékkal (0 CIRCUIT REPAIR, 1 DOOR LOCK, 2 MEMORY BANK, 3 DEFENSE SIMULATION); megoldása az `id` kapuit nyitja |
| `Text` | (szöveg-objektum) | Világ-felirat (Tiled text object, Insert Text) |
| `BuildingRoom` | `id`, `walls` (true), `clear` (true) | Az épület / bunker belső termének **téglalapja** (csempehatárokra igazítva). A játék **automatikusan téglafalat épít köré** (1 csempe vastag keret, a szoba alatt és mellett is), a belsejét pedig kiüríti: elég egy téglalapot húznod egy tömör talajba. `walls = false`: nem épít falat (kézzel festett fal); `clear = false`: a belső csempéket meghagyja (saját belső szerkezet, pl. platformok a `solid` rétegen) |
| `BuildingDoor` | `id`, `target`, `room`, `inside` | Épület-ajtó (Fel / E belép). **`target`** = annak az ajtónak az `id`-ja, ahova ez az ajtó visz: így bunkerből bunkerbe is át lehet menni, láncban, körben, nem csak vissza a főrészre. A `target` ajtó az `id`-ja szerint keresendő, ezért minden célzott ajtónak legyen egyedi `id`-ja (> 0). Régi módszer (ha nincs `target`): két ajtó azonos `room`-mal és eltérő `inside`-dal egymás párja. A játék a belső / külső helyzetet az ajtó mélységéből (a `killRow` alatt) számolja |
| `Decor` | – | Az épület homlokzata (téglalap, csak díszlet) |

## Saját bunkerek építése

1. Húzz egy **`BuildingRoom`** téglalapot a talajba (a `buildings` rétegen; a méretet és a helyet csempehatárra igazítsd, 16 px). A fal és a kiürített belső tér betöltéskor elkészül A Tiled-ben a `solid` rétegen a fal egyelőre nem látszik: **futtasd a *Bake bunker walls into Tiled levels* feladatot** (`scripts/bake-bunkers.ps1`), ami a falat beleírja a `solid` rétegbe (3-as csempe, a belső tér üres), így látod és kézzel is szerkesztheted (pl. nyílást vághatsz a falon). Beégetés után a szoba `walls` és `clear` értéke `false` lesz, hogy a játék betöltéskor ne írja felül a kézi módosításaidat. Ha a szobát átméreteznéd: állítsd vissza ezeket `true`-ra, töröld a régi falat, és futtasd újra. A Tiled-ben nyitott pályát a Tiled újratöltésre ajánlja fel (mentsd előtte a változásaidat).
2. Tegyél be **`BuildingDoor`** objektumokat (csempe-objektum, a lába a padlón): a bunkerben és a felszínen is. Adj mindegyiknek egyedi `id`-t, és a `target` mezőbe írd annak az ajtónak az `id`-ját, ahova vezet.
3. **Bunker a bunkerbe**: a bunker egyik ajtajának `target`-je egy másik bunker ajtaja. Minden ajtó egyirányú: a visszaútnak külön ajtó (a másik oldalon, a `target` az eredeti `id`) kell.
4. A felszín felett a `Decor` téglalap adja a homlokzatot (csak díszlet). A `killRow` legyen a bunkerek fölött (különben a hős leesik a felszínen); a bunkerek a `killRow` alatt vannak.
5. Ellenőrzés: *Validate Tiled levels* (hiányzó vagy nem létező `target`-et jelez). Példa és teszt: `tests/bunkers.ps1`.

Minden épülethez legalább 1 `BuildingRoom` és 2 `BuildingDoor` kell. Az objektum-osztály a Tiled `Class` mezője; ha egy csempe-objektumnál üres, a csempe osztálya számít.

## Eszközök és fájlok

- `levels/amber.tiled-project`, `tiles.tsj` + `tiles.png` (terep), `objects.tsj` + `sprites/*.png` (objektumok): generáltak (`scripts/generate-levels.ps1`).
  A Tiled az objektum-csempekészlet `firstgid`-jét mentéskor újraszámolja (5): a betöltő ezt a térkép `tilesets` listájából olvassa.
- `source/LevelFormat.hx`: az objektumosztályok táblája (osztály, alapértékek) – a sprite-ok sorrendje is. Új objektumtípus: itt vedd fel, adj hozzá képet a
  `LevelExport.art`-ban, kezeld a `LevelLoader`-ben, és futtasd a *Regenerate Tiled assets* feladatot.
- `source/LevelLoader.hx`: a `.tmj` beolvasása `LevelData`-vá; `source/LevelExport.hx` (csak cheats buildben): a generátor pályáinak exportja + körút-ellenőrzés.
- Hibakeresés: a loader hibáit a böngésző konzolja mutatja (`LevelLoader: ...`); hiba esetén a generátor pályája töltődik.
