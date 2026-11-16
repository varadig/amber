package;

/**
 * A robot alkatrészei. A hős csupaszon indul; minden alkatrésznek hatása van a játékra, hiányuk pedig hátrány:
 *  - LEGS: teljes ugrás és gyors futás (nélküle csak szökdécsel, lassú)
 *  - CORE: szívek (nélküle csak 2, alkatrészenként +1, legfeljebb 5)
 *  - VISOR: látás (nélküle homályos, sötét, zajos a kép; a LENS = II. szint: a rejtett dolgok is kivehetők)
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
		"FULL JUMP + FAST RUN", "POWER ONLINE: +1 HEART", "VISION CLEARS UP", "DASH: X / SHIFT", "CLING TO WALLS + WALL JUMP",
		"FIRE WITH V / J", "CONTROLS RESPOND FASTER", "AIR CONTROL + STRONGER BOUNCE", "RADAR ONLINE", "FLIGHT: HOLD JUMP"
	];
	public static final INFO2 = [
		"HIGHER JUMP, FASTER RUN", "+1 HEART", "LENS: HIDDEN THINGS GLOW", "BOOSTER: TWO DASHES PER JUMP", "", "RAPID FIRE",
		"SNAPPIER STILL", "EVEN BETTER AIR CONTROL", "RADAR SHOWS ENEMIES TOO", ""
	];

	/** Az akku töltöttsége (0..100): az idővel és a műveletekkel fogy, az akkupakkok töltik; a pálya elején mentett érték köztes szintje marad. */
	public static var battery:Float = 100;
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
		var t = tier(id) + 1;
		owned[id] = true;
		tiers[id] = t;
		return t;
	}

	public static function reset():Void
	{
		owned = [for (_ in 0...COUNT) false];
		tiers = [for (_ in 0...COUNT) 0];
		battery = 100;
		commit();
	}

	/** A pálya elején a mentett állapotra áll vissza (halál után nem maradnak meg a pályán szerzett alkatrészek). */
	public static function restore():Void
	{
		owned = saved.copy();
		tiers = savedTiers.copy();
		battery = Math.max(savedBattery, 60);
	}

	public static function commit():Void
	{
		saved = owned.copy();
		savedTiers = tiers.copy();
		savedBattery = battery;
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
