package;

/**
 * A robot alkatrészei. A hős csupaszon indul; az alkatrészek visszaadják a képességeit (és látszanak is rajta).
 * A birtokolt alkatrészek pályák között megmaradnak (`saved`: a pálya elejének állapota, halál után ide áll vissza).
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
	public static inline var COUNT = 10;

	public static final NAMES = ["LEGS", "CORE", "VISOR", "THRUSTER", "CLAWS", "BLASTER", "CHIP", "GEAR", "ANTENNA", "JET CELL"];

	/** Az első felvételkor kiírt képesség-leírás (angolul, a játék szövege). */
	public static final INFO = [
		"JUMP AND RUN RESTORED", "POWER ONLINE", "PART COMPASS ONLINE", "DASH: X / SHIFT", "WALL CLAWS: PUSH TOWARD A WALL + JUMP",
		"BLASTER: V / J TO FIRE", "MEMORY INSTALLED", "SERVO INSTALLED", "SIGNAL RESTORED", "FLIGHT: HOLD JUMP"
	];

	public static var owned:Array<Bool> = [for (_ in 0...COUNT) false];
	public static var saved:Array<Bool> = [for (_ in 0...COUNT) false];

	public static inline function has(id:Int):Bool
		return owned[id];

	public static function reset():Void
	{
		owned = [for (_ in 0...COUNT) false];
		saved = owned.copy();
	}

	/** A pálya elején a mentett állapotra áll vissza (halál után nem maradnak meg a pályán szerzett alkatrészek). */
	public static function restore():Void
		owned = saved.copy();

	public static function commit():Void
		saved = owned.copy();

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
