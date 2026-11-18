package;

/**
 * A robot alkatrészei. A hős csupaszon indul; minden alkatrésznek hatása van a játékra, hiányuk pedig hátrány:
 *  - LEGS: teljes ugrás és gyors futás (nélküle csak szökdécsel, lassú)
 *  - CORE: az akku lassabban fogy és a találat kevesebbet vesz el (nincs szív: az akku az életerő; kimerülve elvész egy élet)
 *  - VISOR: látás (nélküle homályos, sötét, zajos a kép; a LENS = II. szint: a titkos atomok világítanak, és 3-at érnek)
 *  - THRUSTER: szökellés (dash); II. szint: két szökellés leszállás előtt
 *  - CLAWS: fal-kapaszkodás és fal-ugrás
 *  - BLASTER: lövés; II. szint: gyorstűz
 *  - CHIP (processzor): a vezérlés fürgesége (nélküle nehézkes, késve reagál)
 *  - GEAR (szervók): légi irányítás és erősebb pattanás (nélküle a levegőben alig irányítható)
 *  - ANTENNA: radar (a térkép-sáv és az alkatrész-iránytű); II. szint: az ellenségeket is mutatja
 * Ugyanazt az alkatrész-típust újra megtalálva a hatás erősödik (szint). A birtokolt alkatrészek pályák között megmaradnak
 * (\`saved\`: a pálya elejének állapota, halál után ide áll vissza).
 */
class Parts
{
	public static inline var LEGS = 0;
	public static inline var CORE = 1;
	public static inline var VISOR = 2;
	public static inline var THRUSTER = 3;
	public static inline var CLAWS = 4;
	public static inline var BLASTER = 5;
	public static inline var CHIP = 6;
	public static inline var GEAR = 7;
	public static inline var ANTENNA = 8;
	public static inline var JET = 9;
	/** Társ-alkatrészek ikonjai (nem képességek): keret, motor, fej. */
	public static inline var FRAME = 10;
	public static inline var MOTOR = 11;
	public static inline var HEAD = 12;
	public static inline var COUNT = 10;

	public static final NAMES = ["LEGS", "CORE", "VISOR", "THRUSTER", "CLAWS", "BLASTER", "PROCESSOR", "SERVOS", "ANTENNA", "JET CELL"];

	/** Az első felvételkor kiírt hatás-leírás (a játék szövege angolul), és a magasabb szintekre. */
	public static final INFO = [
		"FULL JUMP + FAST RUN", "POWER ONLINE: BATTERY DRAINS SLOWER", "VISION CLEARS UP", "DASH: X / SHIFT", "CLING TO WALLS + WALL JUMP",
		"FIRE WITH V / J", "CONTROLS RESPOND FASTER", "AIR CONTROL + STRONGER BOUNCE", "RADAR ONLINE", "FLIGHT: HOLD JUMP"
	];
	public static final INFO2 = [
		"HIGHER JUMP, FASTER RUN", "BATTERY DRAINS EVEN SLOWER", "LENS: SECRET ATOMS GLOW (+3 EACH)", "BOOSTER: TWO DASHES PER JUMP", "GRIP: SLOWER WALL SLIDE", "RAPID FIRE",
		"SNAPPIER STILL", "EVEN BETTER AIR CONTROL", "RADAR SHOWS ENEMIES TOO", "LONGER FLIGHT"
	];

	/** A II. szint utáni fejlesztések (III-tól): részenként a következő szintek hatása; a hossza adja a legnagyobb szintet. */
	static final UP = [
		["TURBO LEGS: HIGHER, FASTER", "RACING LEGS: HIGHER, FASTER", "PEAK LEGS: HIGHER, FASTER"],
		["HITS DRAIN LESS BATTERY", "LONGER PROTECTION AFTER A HIT", "TOUGHEST: LEAST DAMAGE, QUICK RECOVERY"],
		["SECRET ATOMS WORTH +4", "SECRET ATOMS WORTH +5", "SECRET ATOMS WORTH +6"],
		["THREE DASHES PER JUMP", "FASTER DASH RECHARGE", "FOUR DASHES PER JUMP"],
		["HIGHER WALL JUMP", "IRON GRIP: BARELY SLIDES", "MASTER CLIMBER: WALL JUMP++"],
		["FASTER FIRE", "FASTER STILL", "MAXIMUM FIRE RATE"],
		["SHARPER GROUND CONTROL", "RAZOR REFLEXES", "PERFECT REFLEXES"],
		["AIR CONTROL +, BOUNCIER", "AIR CONTROL ++, BOUNCIER", "AIR MASTER"],
		["RADAR SHOWS SECRET ATOMS", "RADAR SHOWS ALL ATOMS"],
		["FLIGHT +50%", "FLIGHT +100%"]
	];

	/** A legnagyobb elérhető szint (I-től). */
	/** Hátralévő életek (a játékmenet egészére; halálkor fogy, pályánként +1 jár; 0 = vége a játéknak). Nem része a mentett állapotnak. */
	public static inline var START_LIVES = 3;
	public static inline var MAX_LIVES = 5;
	public static var lives:Int = START_LIVES;

	static inline function at(v:Array<Float>, id:Int):Float
		return v[Std.int(Math.max(0, Math.min(v.length, tier(id)) - 1))];

	/** A társak a hős LEGS-szintjéből kapnak futás- és ugrásbónuszt (a hőssel azonos arány), hogy tarthassák a tempót. */
	public static function runBoost():Float
		return at([1.0, 1.10, 1.19, 1.27, 1.36], LEGS);

	public static function jumpBoost():Float
		return at([1.0, 1.10, 1.15, 1.20, 1.24], LEGS);

	/** Mennyi akkut vesz el egy találat (a CORE szintje csökkenti). */
	public static function hitCost():Float
		return has(CORE) ? at([24.0, 22.0, 19.0, 19.0, 16.0], CORE) : 26.0;

	/** Az akku fogyásának szorzója (a CORE szintje csökkenti). */
	public static function drainMul():Float
		return has(CORE) ? at([0.85, 0.7, 0.6, 0.6, 0.55], CORE) : 1.0;

	public static function maxTier(id:Int):Int
		return 2 + UP[id].length;

	/** A `t`. szintre (2-től) fejlesztés hatásának szövege. */
	public static function upInfo(id:Int, t:Int):String
		return t <= 1 ? INFO[id] : (t == 2 ? INFO2[id] : (t - 3 < UP[id].length ? UP[id][t - 3] : "MAXED OUT"));

	/** Az akku töltöttsége (0..100): az idővel és a műveletekkel fogy, az akkupakkok töltik; a pálya elején mentett érték köztes szintje marad. */
	public static var battery:Float = 100;
	/** Az összegyűjtött atomok bankja (pályák között megmarad; a MŰHELYBEN alkatrész-fejlesztésre költhető). */
	public static var atoms:Int = 0;
	static var savedAtoms:Int = 0;
	static var savedBattery:Float = 100;
	public static var owned:Array<Bool> = [for (_ in 0...COUNT) false];
	public static var tiers:Array<Int> = [for (_ in 0...COUNT) 0];
	public static var saved:Array<Bool> = [for (_ in 0...COUNT) false];
	public static var savedTiers:Array<Int> = [for (_ in 0...COUNT) 0];

	public static inline function has(id:Int):Bool
		return owned[id];

	/** Szint: 0 = nincs, 1 = megvan, 2+ = továbbfejlesztett. */
	public static inline function tier(id:Int):Int
		return owned[id] ? (tiers[id] > 0 ? tiers[id] : 1) : 0;

	public static function add(id:Int):Int
	{
		var t = Std.int(Math.min(tier(id) + 1, maxTier(id)));
		owned[id] = true;
		tiers[id] = t;
		return t;
	}

	public static function reset():Void
	{
		owned = [for (_ in 0...COUNT) false];
		tiers = [for (_ in 0...COUNT) 0];
		battery = 100;
		atoms = 0;
		lives = START_LIVES;
		commit();
	}

	/** A pálya elején a mentett állapotra áll vissza (halál után nem maradnak meg a pályán szerzett alkatrészek). */
	public static function restore():Void
	{
		owned = saved.copy();
		tiers = savedTiers.copy();
		battery = Math.max(savedBattery, 60);
		atoms = savedAtoms;
	}

	public static function commit():Void
	{
		saved = owned.copy();
		savedTiers = tiers.copy();
		savedBattery = battery;
		savedAtoms = atoms;
	}

	/** A látszathoz: a birtokolt alkatrészek bitmaszkja. */
	public static function mask():Int
	{
		var m = 0;
		for (i in 0...COUNT)
			if (owned[i])
				m |= 1 << i;
		return m;
	}
}

