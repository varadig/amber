package;

/** A Tiled-objektumtípusok táblája (osztály + alapértékek): az exportáló (LevelExport) és a betöltő (LevelLoader) közös forrása. */
typedef SpriteDef =
{
	/** A sprite-fájl neve (levels/sprites/<név>.png) */
	name:String,
	/** Az objektum Class mezője a Tiled-ben */
	cls:String,
	/** Az alap tulajdonságok (a Tiled-ben a tile-osztály tagjai) */
	?def:Dynamic
}

/**
 * A pályák Tiled-formátuma (levels/levelN.tmj, leírás: docs/LEVELS.md):
 *  - csemperétegek: `solid` (1 talaj teteje, 2 talaj, 3 tégla), `platforms` (4, egyirányú);
 *  - objektumrétegek: az objektumok a `objects.tsj` képgyűjtemény-csempéi (gid = OBJ_FIRST + tile id), így a Tiled-ben valós sprite látszik;
 *  - téglalapok: `BuildingRoom` (belső terem), `Decor` (homlokzat); szöveg-objektum: `Text`;
 *  - a térkép tulajdonságai: `name`, `killRow`, `seq<id>` (a sorrend-rejtvény helyes sorrendje: "2,0,1").
 */
class LevelFormat
{
	/** Az objektum-csempekészlet első gid-je (a terep-csempéké 1..4; a Tiled mentéskor sorban újraszámolja, ezért a betöltő a térkép tilesets listájából olvassa). */
	public static inline var OBJ_FIRST = 5;
	/** Az alkatrész-ikonok (Art.partIcons) képkockáinak száma. */
	public static inline var PART_FRAMES = 13;

	public static final ENEMY_KINDS = ["WALKER", "FLYER", "CRAWLER", "HUNTER"];

	public static final SPRITES:Array<SpriteDef> = build();

	static function build():Array<SpriteDef>
	{
		var l:Array<SpriteDef> = [
			{name: "spawn", cls: "Spawn"},
			{name: "door", cls: "Door"},
			{name: "checkpoint", cls: "Checkpoint"},
			{name: "gem", cls: "Gem"},
			{name: "heart", cls: "Heart"},
			{name: "battery", cls: "Battery"},
			{name: "spikes", cls: "Spike"},
			{name: "cracked", cls: "Cracked"},
			{name: "crumble", cls: "Crumble"},
			{name: "mover", cls: "Mover", def: {w: 3, axis: "x", range: 64, speed: 40, id: -1, active: true}},
			{name: "grate", cls: "Grate"},
			{name: "crate", cls: "Crate"},
			{name: "gate", cls: "Gate", def: {id: 1, lock: false}},
			{name: "lockgate", cls: "Gate", def: {id: 1, lock: true}},
			{name: "plate", cls: "Plate", def: {id: 1, hold: false}},
			{name: "lever", cls: "Lever", def: {id: 1}},
			{name: "switch", cls: "Switch", def: {id: 1, idx: 0, label: "1"}},
			{name: "socket", cls: "Socket", def: {id: 1}},
			{name: "key", cls: "Key", def: {id: 1}},
			{name: "powercell", cls: "PowerCell", def: {id: 1}},
			{name: "bench", cls: "Bench", def: {comp: 0}},
			{name: "terminal", cls: "Terminal", def: {id: 1, game: 0}},
			{name: "bdoor", cls: "BuildingDoor", def: {room: 1, inside: false, id: 0, target: 0}},
			{name: "walker", cls: "Enemy", def: {kind: "WALKER"}},
			{name: "flyer", cls: "Enemy", def: {kind: "FLYER"}},
			{name: "crawler", cls: "Enemy", def: {kind: "CRAWLER"}},
			{name: "cell", cls: "Cell"}
		];
		for (i in 0...PART_FRAMES)
			l.push({name: "part" + i, cls: "Part", def: {icon: i, label: i < Parts.COUNT ? Parts.NAMES[i] : "", friend: -1}});
		// a lámpa a lista végén: az eddigi csempe-azonosítók (gid) nem tolódnak el
		l.push({name: "lamp", cls: "Lamp", def: {radius: 110, intensity: 1.0, flicker: true, angle: 90, spread: 50}});
		// a később felvett alkatrészek a lista végén (a meglévő csempék gid-je nem tolódik el): 13 = APU (hang-processzor)
		l.push({name: "part13", cls: "Part", def: {icon: Parts.AUDIO, label: Parts.NAMES[Parts.AUDIO], friend: -1}});
		// rugós ugrólap: a rálépő robotot `power` csempe magasra dobja (a lista végén: a gid-ek nem tolódnak)
		l.push({name: "spring", cls: "Spring", def: {power: 8}});
		return l;
	}

	public static function spriteIndex(name:String):Int
	{
		for (i in 0...SPRITES.length)
			if (SPRITES[i].name == name)
				return i;
		return -1;
	}
}
