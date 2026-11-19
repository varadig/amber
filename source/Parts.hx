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
	/** Hang-processzor (APU): a hang minősége (nélküle tompa, recsegő, zajos; szintenként tisztább, V. szinten tiszta: AudioFx). */
	public static inline var AUDIO = 13;
	/** Az első tíz képesség (0..9); a teljes tömbméret TOTAL (a 10..12 a társ-ikonok helye), a képességek listája ABILITIES. */
	public static inline var COUNT = 10;
	public static inline var TOTAL = 14;
	public static final ABILITIES = [LEGS, CORE, VISOR, THRUSTER, CLAWS, BLASTER, CHIP, GEAR, ANTENNA, JET, AUDIO];

	/** Képesség-alkatrész-e (nem társ-ikon). */
	public static inline function isAbility(id:Int):Bool
		return (id >= 0 && id < COUNT) || id == AUDIO;

	/** A VISOR neve GPU (a látásért felel), a CHIP-é CPU (a vezérlés fürgesége), az AUDIO-é APU (a hang minősége). A 10..12 a társ-ikonok. */
	public static final NAMES = ["LEGS", "CORE", "GPU", "THRUSTER", "CLAWS", "BLASTER", "CPU", "SERVOS", "ANTENNA", "JET CELL", "FRAME", "MOTOR", "HEAD", "APU"];

	/** Régi alkatrész-nevek (Tiled-feliratok, régi mentések): az új névre képezve. */
	public static function canonical(label:String):String
	{
		var l = StringTools.trim(label).toUpperCase();
		return l == "VISOR" ? "GPU" : (l == "PROCESSOR" ? "CPU" : (l == "AUDIO PROCESSOR" || l == "AUDIO" ? "APU" : l));
	}

	/** Az első felvételkor kiírt hatás-leírás (a játék szövege angolul), és a magasabb szintekre. */
	public static final INFO = [
		"FULL JUMP + FAST RUN", "POWER ONLINE: BATTERY DRAINS SLOWER", "CLEAR SIGHT AROUND YOU", "DASH: X / SHIFT", "CLING TO WALLS + WALL JUMP",
		"FIRE: V / J / RIGHT CLICK", "CONTROLS RESPOND FASTER", "AIR CONTROL + STRONGER BOUNCE", "RADAR ONLINE", "FLIGHT: HOLD JUMP",
		"", "", "", "AUDIO PROCESSOR: CLEARER SOUND"
	];
	public static final INFO2 = [
		"HIGHER JUMP, FASTER RUN", "BATTERY DRAINS EVEN SLOWER", "LENS: SEE FARTHER, SECRET ATOMS GLOW", "BOOSTER: TWO DASHES PER JUMP", "GRIP: SLOWER WALL SLIDE", "RAPID FIRE",
		"SNAPPIER STILL", "EVEN BETTER AIR CONTROL", "RADAR SHOWS ENEMIES TOO", "LONGER FLIGHT",
		"", "", "", "CLEANER SOUND, LESS NOISE"
	];

	/**
		A III. szint hatása (minden alkatrész legfeljebb III. szintű: a hossza 1). A GPU és az APU III. szinten teljes
		(korlátlan látás, tiszta hang); a mozgás-alkatrészek III. szintje mérsékelt (ne legyen túl erős a végére).
	**/
	static final UP = [
		["TURBO LEGS: HIGHER, FASTER"],
		["HITS DRAIN LESS BATTERY"],
		["FULL CLEAR VISION, ATOMS +4"],
		["THREE DASHES PER JUMP"],
		["HIGHER WALL JUMP"],
		["FASTER FIRE"],
		["SHARPER GROUND CONTROL"],
		["AIR CONTROL +, BOUNCIER"],
		["RADAR SHOWS SECRET ATOMS"],
		["FLIGHT +50%"],
		[], [], [],
		["PERFECT SOUND"]
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
		return at([1.0, 1.08, 1.17], LEGS);

	public static function jumpBoost():Float
		return at([1.0, 1.06, 1.11], LEGS);

	/** A tiszta látás sugara (px, a 480x270-es képen): GPU nélkül kis kör a robot körül, II. szinten nagyobb; III. szinten az egész kép éles (700 = korlátlan). */
	public static function visionRadius():Float
		return has(VISOR) ? at([80.0, 140.0, 700.0], VISOR) : 40.0;

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
	public static var owned:Array<Bool> = [for (_ in 0...TOTAL) false];
	public static var tiers:Array<Int> = [for (_ in 0...TOTAL) 0];
	public static var saved:Array<Bool> = [for (_ in 0...TOTAL) false];
	public static var savedTiers:Array<Int> = [for (_ in 0...TOTAL) 0];

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
		owned = [for (_ in 0...TOTAL) false];
		tiers = [for (_ in 0...TOTAL) 0];
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

