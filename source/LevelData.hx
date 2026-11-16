package;

typedef Pt =
{
	x:Float,
	y:Float
}

typedef EnemySpawn =
{
	kind:Int,
	x:Float,
	y:Float
}

typedef PartSpawn =
{
	/** Társ-alkatrész esetén a társ azonosítója (Companions.*), különben -1 / hiányzik. */
	?friend:Int,
	icon:Int,
	label:String,
	x:Float,
	y:Float
}

/** Mozgó platform: kezdőpont (px), szélesség (csempe), tengely ("x" / "y"), mozgástartomány (px), sebesség (px/mp). */
typedef MoverDef =
{
	x:Float,
	y:Float,
	w:Int,
	axis:String,
	range:Float,
	speed:Float,
	/** Emelő: az áramcella behelyezése (azonos azonosítójú aljzat) indítja. */
	?id:Int,
	?active:Bool
}

typedef GateDef =
{
	x:Float,
	y:Float,
	id:Int,
	lock:Bool
}

typedef PlateDef =
{
	x:Float,
	y:Float,
	id:Int,
	hold:Bool
}

typedef IdPt =
{
	x:Float,
	y:Float,
	id:Int
}

typedef SwitchDef =
{
	x:Float,
	y:Float,
	id:Int,
	idx:Int,
	label:String
}

typedef BenchDef =
{
	x:Float,
	y:Float,
	comp:Int
}

typedef TextDef =
{
	x:Float,
	y:Float,
	text:String
}

/** Épület: a felszíni ajtó, a belső tér (a talajba vájt terem) és a belső kijárat (px / csempe). */
typedef BuildingDef =
{
	sx:Float,
	sy:Float,
	ix:Float,
	iy:Float,
	x0:Int,
	y0:Int,
	w:Int,
	h:Int
}

/** Egy küldetés-szoba: típus (start / open / tower / well / vault / sky / gated), az alkatrész ikonja és neve, őrzött-e. */
typedef RoomDef =
{
	room:String,
	icon:Int,
	label:String,
	?guard:Bool,
	/** Társ-alkatrész (a társ azonosítója) / "bench": a megépített társ. */
	?friend:Int
}

/**
 * Egy pálya adatai (csempe-koordináták: 16 px). A pályát szegmensekből és küldetés-szobákból építi egy determinisztikus generátor
 * (a pálya sorszáma a mag). Minden szoba a hős képességeire méretezett:
 *  - open: az alkatrész a földön, esetleg őrökkel
 *  - tower: egyirányú platformokból épült torony teteje (teljes ugrás kell)
 *  - well: mély akna alján (fal-ugrás / repülés kell a kijutáshoz)
 *  - vault: téglafalú kamra repedezett fallal (a blaszterrel kell kilőni)
 *  - sky: magasan lebegő platform, a szobában repülő-cella (korlátozott ideig repülni lehet)
 *  - gated: kapu zárja az utat, a kaput egy nyomólap nyitja egy magasabb platformon
 *  - crate: tolható láda a nyomólap-résbe (a lap nyitja a kaput)
 *  - lock: kulcs a fülkében, zárt kapu
 *  - seq: három kapcsoló, a helyes sorrendet egy tábla mutatja
 *  - cell: áramcella az aljzatba, az emelő felviszi a magas polcra
 *  - tunnel: rács mögötti kamra (csak a WHEELIE fér be), benne a nyomólap
 *  - ledge: magas párkány (a TALL fején át érhető el)
 *  - orb: magas kar (az ORB szikrája / érintése billenti át)
 *  - float: magasan lebegő alkatrész (csak az ORB éri el)
 *  - bench: szerelőasztal: itt építhető össze a társ a megtalált alkatrészeiből
 *  - building: épület: az ajtón (fel / E) belépve a talajba vájt belső terem, benne polcokkal, őrökkel; a kijárat a belső ajtó
 * A talajszint változik (dombok, völgyek), így a pálya felfelé és lefelé is halad.
 * Szegmensek: sík, lépcső, szakadék, szigetek, tüskék, aréna, kút, leszakadó híd (1. pálya után), mozgó platform (2. pálya után).
 */
class LevelData
{
	public static inline var T = 16;
	public static inline var H = 56;
	public static inline var COUNT = 5;
	public static inline var WALKER = 0;
	public static inline var FLYER = 1;
	public static inline var CRAWLER = 2;

	public static final NAMES = ["RUSTED CAVES", "COPPER WELLS", "NEON RUINS", "DEEP STATIC", "THE AMBER CORE"];

	/** Pályánként a küldetés-szobák sorrendben (az ajtóhoz mindegyik alkatrész kell). */
	public static final RECIPES:Array<Array<RoomDef>> = [
		// 1. pálya: a saját alkatrészek (a robot csupaszon indul)
		[
			{room: "start", icon: Parts.LEGS, label: "LEGS"},
			{room: "crate", icon: Parts.CORE, label: "CORE"},
			{room: "tower", icon: Parts.VISOR, label: "VISOR"}
		],
		// 2. pálya: még saját alkatrészek, kulcs- és sorrend-rejtvény
		[
			{room: "lock", icon: Parts.THRUSTER, label: "THRUSTER"},
			{room: "seq", icon: Parts.CLAWS, label: "CLAWS"},
			{room: "well", icon: Parts.CHIP, label: "PROCESSOR"}
		],
		// 3. pálya: a maradék saját alkatrész + az első társ (WHEELIE) alkatrészei
		[
			{room: "open", icon: Parts.BLASTER, label: "BLASTER", guard: true},
			{room: "vault", icon: Parts.FRAME, label: "SMALL FRAME", friend: 0},
			{room: "gated", icon: Parts.MOTOR, label: "WHEEL MOTOR", friend: 0},
			{room: "building", icon: Parts.HEAD, label: "TINY HEAD", guard: true, friend: 0},
			{room: "bench", icon: Parts.HEAD, label: "WORKBENCH", friend: 0},
			{room: "tunnel", icon: Parts.GEAR, label: "SERVOS"},
			{room: "cell", icon: Parts.ANTENNA, label: "ANTENNA"}
		],
		// 4. pálya: fejlesztések + a második társ (TALL)
		[
			{room: "tower", icon: Parts.FRAME, label: "LONG LEGS", friend: 1},
			{room: "sky", icon: Parts.MOTOR, label: "TALL FRAME", friend: 1},
			{room: "crate", icon: Parts.HEAD, label: "HEAD LAMP", friend: 1},
			{room: "bench", icon: Parts.HEAD, label: "WORKBENCH", friend: 1},
			{room: "ledge", icon: Parts.LEGS, label: "SPRINGS"},
			{room: "tunnel", icon: Parts.CORE, label: "REACTOR"}
		],
		// 5. pálya: a harmadik társ (ORB) és a végső fejlesztések
		[
			{room: "lock", icon: Parts.FRAME, label: "GLASS BULB", friend: 2},
			{room: "seq", icon: Parts.MOTOR, label: "ROTOR", friend: 2},
			{room: "building", icon: Parts.HEAD, label: "SPARK CORE", guard: true, friend: 2},
			{room: "bench", icon: Parts.HEAD, label: "WORKBENCH", friend: 2},
			{room: "float", icon: Parts.ANTENNA, label: "RADIO"},
			{room: "orb", icon: Parts.GEAR, label: "ACTUATOR"}
		]
	];

	public static final RECIPES_OLD:Array<Array<RoomDef>> = [
		[
			{room: "start", icon: Parts.LEGS, label: "LEGS"},
			{room: "building", icon: Parts.CORE, label: "CORE", guard: true},
			{room: "tower", icon: Parts.VISOR, label: "VISOR"}
		],
		[
			{room: "open", icon: Parts.THRUSTER, label: "THRUSTER", guard: true},
			{room: "tower", icon: Parts.CLAWS, label: "CLAWS"},
			{room: "well", icon: Parts.CHIP, label: "PROCESSOR"}
		],
		[
			{room: "open", icon: Parts.BLASTER, label: "BLASTER"},
			{room: "building", icon: Parts.GEAR, label: "SERVOS", guard: true},
			{room: "sky", icon: Parts.ANTENNA, label: "ANTENNA"}
		],
		[
			{room: "open", icon: Parts.LEGS, label: "SPRINGS", guard: true},
			{room: "gated", icon: Parts.CORE, label: "REACTOR"},
			{room: "building", icon: Parts.CHIP, label: "CIRCUIT", guard: true},
			{room: "sky", icon: Parts.BLASTER, label: "CANNON"}
		],
		[
			{room: "tower", icon: Parts.ANTENNA, label: "RADIO"},
			{room: "well", icon: Parts.GEAR, label: "ACTUATOR"},
			{room: "gated", icon: Parts.THRUSTER, label: "BOOSTER"},
			{room: "building", icon: Parts.VISOR, label: "LENS", guard: true},
			{room: "sky", icon: Parts.CORE, label: "FINAL CORE"}
		]
	];

	public var level:Int;
	public var name:String;
	public var w:Int = 0;
	/** Oszloponként a talaj teteje (a csempesor); 99 = szakadék. */
	public var top:Array<Int> = [];
	/** Szilárd csempék (1 talaj teteje, 2 talaj, 3 tégla). */
	public var solid:Array<Int> = [];
	/** Egyirányú platformok (csempe 4). */
	public var plats:Array<Int> = [];
	public var gems:Array<Pt> = [];
	public var hearts:Array<Pt> = [];
	public var enemies:Array<EnemySpawn> = [];
	public var spikes:Array<Pt> = [];
	public var checkpoints:Array<Pt> = [];
	public var parts:Array<PartSpawn> = [];
	public var cells:Array<Pt> = [];
	public var crackeds:Array<Pt> = [];
	public var gates:Array<GateDef> = [];
	public var plates:Array<PlateDef> = [];
	public var levers:Array<IdPt> = [];
	public var switches:Array<SwitchDef> = [];
	/** Sorrend-rejtvények: azonosító -> a kapcsolók helyes sorrendje (idx-ek). */
	public var seqs:Map<Int, Array<Int>> = new Map();
	public var keys:Array<IdPt> = [];
	public var sockets:Array<IdPt> = [];
	public var powerCells:Array<IdPt> = [];
	public var crates:Array<Pt> = [];
	public var grates:Array<Pt> = [];
	public var benches:Array<BenchDef> = [];
	public var texts:Array<TextDef> = [];
	/** Leszakadó platform-darabok (px; 3 csempe szélesek). */
	public var crumbles:Array<Pt> = [];
	public var movers:Array<MoverDef> = [];
	/** Rejtett akkupakkok (az út mellett, fülkékben, szakadékok párkányain, épületekben). */
	public var batteries:Array<Pt> = [];
	public var buildings:Array<BuildingDef> = [];
	/** Épület-homlokzatok (csempe-koordináták x, y, szélesség, magasság), csak díszlet. */
	public var decor:Array<{x:Int, y:Int, w:Int, h:Int}> = [];
	/** Ennél a sornál mélyebbre esve a hős meghal (a felszíni szakadékokhoz; a belső termek ez alatt vannak). */
	public var killRow:Int = 0;
	public var door:Pt;
	public var spawn:Pt;

	var seed:Int;
	var cur:Int = 18;
	var platList:Array<{x:Int, y:Int, w:Int}> = [];
	var bricks:Array<{x:Int, y:Int}> = [];
	var lastCp:Int = -100;
	var nextId:Int = 1;

	function new(level:Int)
	{
		this.level = level;
		name = NAMES[level % NAMES.length];
		seed = level * 7919 + 4243;
	}

	function rnd():Float
	{
		seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF;
		return (seed >> 8) / 8388608.0;
	}

	function ri(a:Int, b:Int):Int
		return a + Std.int(rnd() * (b - a + 1));

	inline function flat(len:Int, h:Int):Void
	{
		for (i in 0...len)
			top.push(h);
	}

	function gem(col:Float, row:Float):Void
		gems.push({x: col * T + 4, y: row * T + 4});

	/** Szilárd csempe-e a (tx, ty) (az ellenségek éldetektálásához és a lövedékekhez). */
	public function isSolid(tx:Int, ty:Int):Bool
	{
		if (tx < 0 || tx >= w || ty < 0 || ty >= H)
			return false;
		return solid[ty * w + tx] != 0;
	}

	/** Szilárd vagy egyirányú platform (az ellenség talaj-ellenőrzéséhez). */
	public function isStandable(tx:Int, ty:Int):Bool
	{
		if (tx < 0 || tx >= w || ty < 0 || ty >= H)
			return false;
		var i = ty * w + tx;
		return solid[i] != 0 || plats[i] != 0;
	}

	public static function generate(level:Int):LevelData
	{
		var d = new LevelData(level);
		d.build();
		return d;
	}

	/** Ellenőrzőpont: csak ha az előzőtől legalább 26 csempényire van (ne legyen kettő közvetlenül egymás után). */
	/** A talajszint lépcsőzetes (2 soronként) módosítása a célsorra, 3 oszlopnyi lépcsőfokokkal. */
	function moveTo(target:Int):Void
	{
		while (cur != target)
		{
			cur += Std.int(Math.max(-2, Math.min(2, target - cur)));
			flat(3, cur);
		}
	}

	function checkpointAt(c0:Int):Void
	{
		if (c0 - lastCp < 26)
			return;
		lastCp = c0;
		checkpoints.push({x: (c0 + 1) * T + 4, y: cur * T - 16});
	}

	function build():Void
	{
		var L = level;
		var rooms = RECIPES[L % RECIPES.length].copy();
		flat(8, cur);
		spawn = {x: 3 * T + 2, y: cur * T - 30};
		// az első szoba a kezdő sík szakaszon (a csupasz hős itt találja meg az első alkatrészt)
		if (rooms[0].room == "start")
		{
			var r = rooms.shift();
			parts.push({friend: r.friend != null && r.room != "bench" ? r.friend : -1, icon: r.icon, label: r.label, x: 6 * T + 3, y: cur * T - 14});
			gem(4, cur - 2);
		}
		var si = 0;
		var fillers = rooms.length >= 6 ? 1 : 2 + (L >= 2 ? 1 : 0);
		for (r in rooms)
		{
			for (k in 0...fillers)
				filler(si++);
			room(r);
		}
		for (k in 0...2)
			filler(si++);
		// vég: sík szakasz az ajtóval
		var c0 = top.length;
		flat(12, cur);
		door = {x: (c0 + 8) * T, y: cur * T - 24};
		w = top.length;
		var maxTop = 0;
		for (t in top)
			if (t < 99 && t > maxTop)
				maxTop = t;
		killRow = maxTop + 12;
		fill();
	}

	function room(r:RoomDef):Void
	{
		switch (r.room)
		{
			case "tower":
				roomTower(r);
			case "well":
				roomWell(r);
			case "vault":
				roomVault(r);
			case "sky":
				roomSky(r);
			case "gated":
				roomGated(r);
			case "building":
				roomBuilding(r);
			case "crate":
				roomCrate(r);
			case "lock":
				roomLock(r);
			case "seq":
				roomSeq(r);
			case "cell":
				roomCell(r);
			case "tunnel":
				roomTunnel(r);
			case "ledge":
				roomLedge(r);
			case "orb":
				roomOrb(r);
			case "float":
				roomFloat(r);
			case "bench":
				roomBench(r);
			default:
				roomOpen(r);
		}
	}

	function filler(s:Int):Void
	{
		var L = level;
		// minden harmadik szegmens nyugodt, ellenőrzőpontos sík szakasz
		if (s % 3 == 2)
		{
			var c0 = top.length;
			flat(ri(6, 8), cur);
			checkpointAt(c0);
			gem(c0 + 3, cur - 2);
			gem(c0 + 4, cur - 2);
			if (L >= 1 && rnd() < 0.3)
				hearts.push({x: (c0 + 5) * T + 4, y: cur * T - 12});
			return;
		}
		// a későbbi pályák különleges platformjai
		if (L >= 1 && rnd() < 0.22)
		{
			segCrumble();
			return;
		}
		if (L >= 2 && rnd() < 0.22)
		{
			segMover();
			return;
		}
		if (rnd() < 0.2)
		{
			segHill();
			return;
		}
		if (rnd() < 0.22)
		{
			segNiche();
			return;
		}
		var wells = L >= 2 ? 1 : 0;
		var pick = rnd() * (3 + 3 + 3 + (L >= 1 ? 2 : 0) + 2 + 2 + wells);
		if (pick < 3)
			segFlat(0.55 + 0.08 * L, enemies.length < 2 + L);
		else if (pick < 6)
			segStep();
		else if (pick < 9)
			segPit(L);
		else if (pick < 9 + (L >= 1 ? 2 : 0))
			segIslands();
		else if (pick < 11 + (L >= 1 ? 2 : 0))
			segSpikes(L);
		else if (pick < 13 + (L >= 1 ? 2 : 0))
			segArena(L);
		else
			segWell();
	}

	// --- Szegmensek ---

	/** Fülke: két kis egymás fölötti platform az út mellett, a tetején rejtett akkupakk. */
	function segNiche():Void
	{
		var c0 = top.length;
		flat(9, cur);
		platList.push({x: c0 + 2, y: cur - 2, w: 2});
		platList.push({x: c0 + 5, y: cur - 4, w: 2});
		batteries.push({x: (c0 + 5) * T + 4 + 8, y: (cur - 4) * T - 14});
		gem(c0 + 3, cur - 4);
	}

	/** Domb / völgy: a talajszint több lépcsőben jelentősen változik (felfelé vagy lefelé), a lépcsőkön ékszerekkel. */
	function segHill():Void
	{
		var target = ri(14, 26);
		if (Math.abs(target - cur) < 4)
			target = cur + (cur > 20 ? -6 : 6);
		var from = cur;
		moveTo(target);
		var c0 = top.length;
		flat(4, cur);
		gem(c0 + 1, cur - 2);
		gem(c0 + 2, cur - 2);
		if (rnd() < 0.5)
			enemies.push({kind: WALKER, x: (c0 + 2) * T, y: cur * T - 10});
	}

	function segFlat(chance:Float, force:Bool):Void
	{
		var c0 = top.length;
		var len = ri(5, 9);
		flat(len, cur);
		var n = ri(2, 4);
		for (i in 0...n)
			gem(c0 + 1 + i * 1.5, cur - 2);
		if (force || rnd() < chance)
			enemies.push({kind: WALKER, x: (c0 + len / 2) * T, y: cur * T - 10});
	}

	function segStep():Void
	{
		var opts:Array<Int> = [];
		for (dy in [-2, -1, 1, 2])
			if (cur + dy >= 13 && cur + dy <= 27)
				opts.push(dy);
		cur += opts[ri(0, opts.length - 1)];
		var c0 = top.length;
		flat(4, cur);
		gem(c0 + 1, cur - 2);
		gem(c0 + 2, cur - 2);
	}

	function segPit(L:Int):Void
	{
		var len = ri(2, 3 + (L >= 2 ? 1 : 0));
		var c0 = top.length;
		for (i in 0...len)
			top.push(99);
		for (i in 0...len)
			gem(c0 + i, cur - 3 - ((i == Std.int(len / 2)) ? 1 : 0));
		if (len >= 4)
			platList.push({x: c0 + 1, y: cur + 1, w: 2});
		else if (len >= 3 && rnd() < 0.5)
		{
			// párkány a szakadékban: rejtett akkupakk (ugorj le érte, onnan ki lehet ugrani)
			platList.push({x: c0 + Std.int(len / 2) - 1, y: cur + 3, w: 2});
			batteries.push({x: (c0 + Std.int(len / 2)) * T + 4, y: (cur + 3) * T - 14});
		}
		flat(3, cur);
	}

	function segIslands():Void
	{
		var n = ri(2, 3);
		var c0 = top.length;
		var rowPrev = cur;
		for (i in 0...n)
		{
			for (k in 0...5)
				top.push(99);
			var row = Std.int(Math.max(cur - 3, Math.min(cur + 1, rowPrev + ri(-1, 1))));
			rowPrev = row;
			var px = c0 + i * 5 + 2;
			platList.push({x: px, y: row, w: 3});
			gem(px + 1, row - 2);
		}
		top.push(99);
		top.push(99);
		flat(3, cur);
		if (rnd() < 0.6)
			enemies.push({kind: FLYER, x: (c0 + n * 2.5) * T, y: (cur - 5) * T});
	}

	function segSpikes(L:Int):Void
	{
		var len = L >= 2 ? ri(2, 3) : 2;
		flat(2, cur);
		var c0 = top.length;
		flat(len, cur);
		for (i in 0...len)
			spikes.push({x: (c0 + i) * T, y: cur * T - 8});
		for (i in 0...len)
			gem(c0 + i, cur - 3 - ((i == 1) ? 1 : 0));
		flat(3, cur);
	}

	function segArena(L:Int):Void
	{
		var c0 = top.length;
		var len = ri(10, 12);
		flat(len, cur);
		var nw = ri(1, 2) + (L >= 2 ? 1 : 0);
		for (i in 0...nw)
			enemies.push({kind: WALKER, x: (c0 + 2 + i * 3) * T, y: cur * T - 10});
		if (L >= 1)
			enemies.push({kind: FLYER, x: (c0 + len / 2) * T, y: (cur - 5) * T});
		if (L >= 2 && rnd() < 0.7)
			enemies.push({kind: CRAWLER, x: (c0 + len - 3) * T, y: cur * T - 10});
		for (i in 0...4)
			gem(c0 + 2 + i * 2, cur - 2 - (i % 2));
	}

	function segWell():Void
	{
		flat(2, cur);
		var c0 = top.length;
		for (i in 0...3)
			top.push(cur + 6);
		gem(c0 + 1, cur + 2);
		gem(c0 + 1, cur + 4);
		flat(3, cur);
	}

	/** Leszakadó híd: szakadék fölött 3 egymás melletti, 3 csempe széles darab; a ráállás után rövid idővel lehullik (és később visszatér). */
	function segCrumble():Void
	{
		flat(2, cur);
		var c0 = top.length;
		for (i in 0...9)
			top.push(99);
		for (k in 0...3)
		{
			crumbles.push({x: (c0 + k * 3) * T, y: cur * T});
			gem(c0 + k * 3 + 1, cur - 2);
		}
		flat(3, cur);
	}

	/** Mozgó platform: széles szakadék fölött egy 3 csempés platform jár ide-oda (az egyirányú platformot alulról át lehet ugrani). */
	function segMover():Void
	{
		flat(2, cur);
		var c0 = top.length;
		for (i in 0...10)
			top.push(99);
		movers.push({x: c0 * T + 8, y: cur * T, w: 3, axis: "x", range: 6 * T, speed: 38 + level * 4});
		gem(c0 + 4, cur - 3);
		flat(3, cur);
		if (level >= 3 && rnd() < 0.6)
			enemies.push({kind: FLYER, x: (c0 + 5) * T, y: (cur - 5) * T});
	}

	// --- Küldetés-szobák ---

	/**
	 * Épület: a felszínen homlokzat és ajtó; a belső terem a talajba van vájtal, az alsó sávban (nem látszik a felszínről). A teremben két polc (egymásra
	 * épülő lépcső), az alkatrész a felső polcon, őrök a padlón; a bal oldali ajtó a kijárat.
	 */
	function roomBuilding(r:RoomDef):Void
	{
		moveTo(Std.int(Math.max(14, Math.min(24, cur))));
		var c0 = top.length;
		flat(24, cur);
		checkpointAt(c0);
		var wI = 22;
		var x0 = c0 + 1;
		var yBot = H - 4;
		var y0 = yBot - 10;
		decor.push({x: c0 + 8, y: cur - 7, w: 9, h: 7});
		buildings.push({sx: (c0 + 12) * T, sy: cur * T - 24, ix: (x0 + 1) * T, iy: yBot * T - 24, x0: x0, y0: y0, w: wI, h: 10});
		platList.push({x: x0 + 5, y: yBot - 3, w: 4});
		platList.push({x: x0 + 11, y: yBot - 6, w: 4});
		parts.push({friend: r.friend != null && r.room != "bench" ? r.friend : -1, icon: r.icon, label: r.label, x: (x0 + 12) * T + 3, y: (yBot - 6) * T - 14});
		gem(x0 + 6, yBot - 5);
		gem(x0 + 7, yBot - 5);
		gem(x0 + 12, yBot - 8);
		gem(x0 + 18, yBot - 2);
		if (r.guard == true)
		{
			enemies.push({kind: WALKER, x: (x0 + 9) * T, y: yBot * T - 10});
			enemies.push({kind: WALKER, x: (x0 + 16) * T, y: yBot * T - 10});
			if (level >= 2)
				enemies.push({kind: FLYER, x: (x0 + 8) * T, y: (yBot - 5) * T});
			if (level >= 3)
				enemies.push({kind: CRAWLER, x: (x0 + 14) * T, y: yBot * T - 10});
		}
		if (level >= 1)
			for (i in 0...2)
				spikes.push({x: (x0 + 15 + i) * T, y: yBot * T - 8});
		hearts.push({x: (x0 + 19) * T + 4, y: yBot * T - 12});
		batteries.push({x: (x0 + 3) * T + 4, y: yBot * T - 14});
		batteries.push({x: (x0 + 13) * T + 4, y: (yBot - 6) * T - 14});
	}

	/** Kapu-oszlop (6 csempe magas) azonosítóval. */
	function gateColumn(col:Int, id:Int, lock:Bool):Void
	{
		for (k in 1...7)
			gates.push({x: col * T, y: (cur - k) * T, id: id, lock: lock});
	}

	/** Láda-rejtvény: a nyomólap egy 1 csempe széles, 2 mély résben van; a ládát bele kell tolni, így a lap lenyomva marad és a kapu nyitva. */
	function roomCrate(r:RoomDef):Void
	{
		var c0 = top.length;
		flat(6, cur);
		checkpointAt(c0);
		var id = nextId++;
		top.push(cur + 2);
		flat(12, cur);
		plates.push({x: (c0 + 6) * T, y: (cur + 2) * T - 6, id: id, hold: true});
		crates.push({x: (c0 + 2) * T, y: cur * T - 16});
		gateColumn(c0 + 13, id, false);
		parts.push({friend: r.friend != null ? r.friend : -1, icon: r.icon, label: r.label, x: (c0 + 16) * T + 3, y: cur * T - 14});
		texts.push({x: (c0 + 1) * T, y: (cur - 4) * T, text: "PUSH THE CRATE INTO THE SLOT"});
		gem(c0 + 9, cur - 2);
	}

	/** Zárt kapu: a kulcs egy fülkében (két egymás fölötti kis platform) van. */
	function roomLock(r:RoomDef):Void
	{
		var c0 = top.length;
		flat(18, cur);
		checkpointAt(c0);
		var id = nextId++;
		platList.push({x: c0 + 2, y: cur - 2, w: 2});
		platList.push({x: c0 + 5, y: cur - 4, w: 2});
		keys.push({x: (c0 + 5) * T + 3, y: (cur - 4) * T - 12, id: id});
		gateColumn(c0 + 11, id, true);
		parts.push({friend: r.friend != null ? r.friend : -1, icon: r.icon, label: r.label, x: (c0 + 14) * T + 3, y: cur * T - 14});
		gem(c0 + 3, cur - 4);
	}

	/** Sorrend-kapcsolók: három kapcsoló (A, B, C), a helyes sorrendet egy tábla mutatja; rossz sorrendnél visszaáll. */
	function roomSeq(r:RoomDef):Void
	{
		var c0 = top.length;
		flat(20, cur);
		checkpointAt(c0);
		var id = nextId++;
		var order = [0, 1, 2];
		for (i in 0...2)
		{
			var j = ri(i, 2);
			var tmp = order[i];
			order[i] = order[j];
			order[j] = tmp;
		}
		if (order[0] == 0 && order[1] == 1)
			order = [2, 0, 1];
		var labels = ["A", "B", "C"];
		for (i in 0...3)
			switches.push({x: (c0 + 3 + i * 3) * T + 2, y: cur * T - 14, id: id, idx: i, label: labels[i]});
		seqs.set(id, order);
		texts.push({x: (c0 + 2) * T, y: (cur - 5) * T, text: "ORDER: " + [for (o in order) labels[o]].join(" > ")});
		gateColumn(c0 + 14, id, false);
		parts.push({friend: r.friend != null ? r.friend : -1, icon: r.icon, label: r.label, x: (c0 + 17) * T + 3, y: cur * T - 14});
	}

	/** Áramcella + emelő: a cella egy fülkében van, az aljzatba téve az emelő felviszi a hőst a magas polcra az alkatrészhez. */
	function roomCell(r:RoomDef):Void
	{
		moveTo(Std.int(Math.max(15, Math.min(22, cur))));
		var c0 = top.length;
		flat(24, cur);
		checkpointAt(c0);
		var id = nextId++;
		platList.push({x: c0 + 2, y: cur - 2, w: 2});
		platList.push({x: c0 + 5, y: cur - 4, w: 2});
		powerCells.push({x: (c0 + 5) * T + 4, y: (cur - 4) * T - 14, id: id});
		sockets.push({x: (c0 + 10) * T + 2, y: cur * T - 12, id: id});
		movers.push({x: (c0 + 13) * T, y: cur * T, w: 3, axis: "y", range: 10 * T, speed: 46, id: id, active: false});
		platList.push({x: c0 + 17, y: cur - 10, w: 4});
		parts.push({friend: r.friend != null ? r.friend : -1, icon: r.icon, label: r.label, x: (c0 + 18) * T + 3, y: (cur - 10) * T - 14});
		texts.push({x: (c0 + 8) * T, y: (cur - 4) * T, text: "SOCKET NEEDS A POWER CELL"});
		gem(c0 + 11, cur - 3);
	}

	/** Rács mögötti kamra: a hős nem fér be, az apró WHEELIE igen; a benne lévő nyomólap nyitja a kaput. */
	function roomTunnel(r:RoomDef):Void
	{
		var c0 = top.length;
		flat(19, cur);
		checkpointAt(c0);
		// 2 csempe magas kamra (a társak is átmásznak rajta), a bal oldalán rács: a hős nem fér be, a kicsi igen; az alkatrész bent van
		for (x in c0 + 5...c0 + 12)
			bricks.push({x: x, y: cur - 2});
		bricks.push({x: c0 + 11, y: cur - 1});
		grates.push({x: (c0 + 5) * T, y: (cur - 1) * T});
		parts.push({friend: r.friend != null ? r.friend : -1, icon: r.icon, label: r.label, x: (c0 + 8) * T + 3, y: cur * T - 14});
		texts.push({x: (c0 + 3) * T, y: (cur - 5) * T, text: "ONLY THE SMALL ONE FITS"});
		gem(c0 + 14, cur - 2);
	}

	/** Magas párkány (6 csempe): a TALL fejéről érhető el. */
	function roomLedge(r:RoomDef):Void
	{
		moveTo(Std.int(Math.max(15, Math.min(24, cur))));
		var c0 = top.length;
		flat(16, cur);
		checkpointAt(c0);
		platList.push({x: c0 + 9, y: cur - 6, w: 4});
		parts.push({friend: r.friend != null ? r.friend : -1, icon: r.icon, label: r.label, x: (c0 + 10) * T + 3, y: (cur - 6) * T - 14});
		texts.push({x: (c0 + 3) * T, y: (cur - 7) * T, text: "TOO HIGH. NEED A BOOST"});
		gem(c0 + 5, cur - 3);
	}

	/** Magas kar: az ORB felrepül és átbillenti; a kar nyitja a kaput. */
	/** Magasan lebegő alkatrész: csak az ORB éri el (repülve veszi fel). */
	function roomFloat(r:RoomDef):Void
	{
		moveTo(Std.int(Math.max(15, Math.min(24, cur))));
		var c0 = top.length;
		flat(16, cur);
		checkpointAt(c0);
		parts.push({friend: r.friend != null ? r.friend : -1, icon: r.icon, label: r.label, x: (c0 + 8) * T + 3, y: (cur - 12) * T});
		texts.push({x: (c0 + 3) * T, y: (cur - 6) * T, text: "TOO HIGH FOR ANYONE WHO CAN'T FLY"});
		gem(c0 + 6, cur - 3);
		gem(c0 + 10, cur - 3);
	}

	function roomOrb(r:RoomDef):Void
	{
		var c0 = top.length;
		flat(20, cur);
		checkpointAt(c0);
		var id = nextId++;
		levers.push({x: (c0 + 8) * T, y: (cur - 10) * T + 6, id: id});
		gateColumn(c0 + 13, id, false);
		parts.push({friend: r.friend != null ? r.friend : -1, icon: r.icon, label: r.label, x: (c0 + 16) * T + 3, y: cur * T - 14});
		texts.push({x: (c0 + 5) * T, y: (cur - 6) * T, text: "LEVER OUT OF REACH"});
	}

	/** Szerelőasztal: itt építhető meg a társ (ha megvan mindhárom alkatrésze). */
	function roomBench(r:RoomDef):Void
	{
		var c0 = top.length;
		flat(12, cur);
		checkpointAt(c0);
		benches.push({x: (c0 + 5) * T, y: cur * T - 16, comp: r.friend != null ? r.friend : 0});
		gem(c0 + 3, cur - 2);
		gem(c0 + 9, cur - 2);
	}

	function roomOpen(r:RoomDef):Void
	{
		var c0 = top.length;
		flat(10, cur);
		checkpointAt(c0);
		parts.push({friend: r.friend != null && r.room != "bench" ? r.friend : -1, icon: r.icon, label: r.label, x: (c0 + 6) * T + 3, y: cur * T - 14});
		if (r.guard == true)
		{
			enemies.push({kind: WALKER, x: (c0 + 4) * T, y: cur * T - 10});
			enemies.push({kind: WALKER, x: (c0 + 8) * T, y: cur * T - 10});
			if (level >= 2)
				enemies.push({kind: FLYER, x: (c0 + 6) * T, y: (cur - 5) * T});
		}
		gem(c0 + 3, cur - 3);
		gem(c0 + 9, cur - 3);
	}

	function roomTower(r:RoomDef):Void
	{
		moveTo(Std.int(Math.max(15, Math.min(22, cur))));
		var c0 = top.length;
		flat(14, cur);
		checkpointAt(c0);
		for (k in 1...5)
		{
			var row = cur - 3 * k;
			var px = k % 2 == 1 ? c0 + 2 : c0 + 8;
			platList.push({x: px, y: row, w: 4});
			if (k < 4)
			{
				gem(px + 1, row - 2);
				gem(px + 2, row - 2);
			}
			else
				parts.push({friend: r.friend != null && r.room != "bench" ? r.friend : -1, icon: r.icon, label: r.label, x: (px + 1) * T + 3, y: row * T - 14});
		}
		gem(c0 + 5, cur - 2);
	}

	function roomWell(r:RoomDef):Void
	{
		flat(3, cur);
		checkpointAt(top.length - 3);
		var c0 = top.length;
		for (i in 0...3)
			top.push(cur + 6);
		parts.push({friend: r.friend != null && r.room != "bench" ? r.friend : -1, icon: r.icon, label: r.label, x: (c0 + 1) * T + 3, y: (cur + 6) * T - 14});
		gem(c0 + 1, cur + 2);
		gem(c0 + 1, cur + 4);
		flat(4, cur);
	}

	function roomVault(r:RoomDef):Void
	{
		var c0 = top.length;
		flat(15, cur);
		checkpointAt(c0);
		// kamra: tető és jobb fal tégla, a bal fal két repedezett blokk (blaszterrel kilőhető); a kamra 3 csempe magas, átugorható
		for (x in c0 + 5...c0 + 12)
			bricks.push({x: x, y: cur - 2});
		bricks.push({x: c0 + 11, y: cur - 1});
		crackeds.push({x: (c0 + 5) * T, y: (cur - 1) * T});
		parts.push({friend: r.friend != null && r.room != "bench" ? r.friend : -1, icon: r.icon, label: r.label, x: (c0 + 8) * T + 3, y: cur * T - 14});
		gem(c0 + 7, cur - 5);
		gem(c0 + 9, cur - 5);
	}

	function roomSky(r:RoomDef):Void
	{
		moveTo(Std.int(Math.max(15, Math.min(22, cur))));
		var c0 = top.length;
		flat(14, cur);
		checkpointAt(c0);
		cells.push({x: (c0 + 3) * T + 3, y: cur * T - 14});
		var row = cur - 12;
		platList.push({x: c0 + 9, y: row, w: 3});
		parts.push({friend: r.friend != null && r.room != "bench" ? r.friend : -1, icon: r.icon, label: r.label, x: (c0 + 10) * T + 3, y: row * T - 14});
		for (i in 0...4)
			gem(c0 + 4 + i * 0.5, cur - 3 - i * 2.5);
	}

	function roomGated(r:RoomDef):Void
	{
		var c0 = top.length;
		flat(16, cur);
		checkpointAt(c0);
		// nyomólap egy magasabb platformon, a kapu az út közepén (6 csempe magas: átugorhatatlan)
		platList.push({x: c0 + 2, y: cur - 3, w: 4});
		platList.push({x: c0 + 1, y: cur - 1, w: 2});
		var gid = nextId++;
		plates.push({x: (c0 + 4) * T, y: (cur - 3) * T - 6, id: gid, hold: false});
		for (k in 1...7)
			gates.push({x: (c0 + 9) * T, y: (cur - k) * T, id: gid, lock: false});
		parts.push({friend: r.friend != null && r.room != "bench" ? r.friend : -1, icon: r.icon, label: r.label, x: (c0 + 13) * T + 3, y: cur * T - 14});
		gem(c0 + 11, cur - 2);
	}

	/** A talaj-, tégla- és platform-csempék feltöltése. */
	function fill():Void
	{
		solid = [for (i in 0...(w * H)) 0];
		plats = [for (i in 0...(w * H)) 0];
		for (x in 0...w)
		{
			var t = top[x];
			if (t >= H)
				continue;
			for (y in t...H)
				solid[y * w + x] = (y == t) ? 1 : 2;
		}
		// épületek: a belső terem kivájása téglafallal körülvéve
		for (bd in buildings)
		{
			for (y in bd.y0 - 1...bd.y0 + bd.h + 1)
				for (x in bd.x0 - 1...bd.x0 + bd.w + 1)
				{
					var edge = y == bd.y0 - 1 || y == bd.y0 + bd.h || x == bd.x0 - 1 || x == bd.x0 + bd.w;
					solid[y * w + x] = edge ? 3 : 0;
				}
		}
		for (b in bricks)
			if (b.x >= 0 && b.x < w && b.y >= 0 && b.y < H)
				solid[b.y * w + b.x] = 3;
		for (p in platList)
			for (i in 0...p.w)
			{
				var x = p.x + i;
				if (x >= 0 && x < w && p.y >= 0 && p.y < H && solid[p.y * w + x] == 0)
					plats[p.y * w + x] = 4;
			}
	}
}
