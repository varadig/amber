package;

/**
 * A társak (a veszett alkatrészekből összeépített barát-robotok): mindegyik más forma és más segítség a rejtvényekben.
 *  - WHEELIE: apró, egykerekű; átfér a rácson (a hős nem), és a rács mögötti nyomólapra küldhető
 *  - TALL: magas, hosszú lábú; ha a helyén áll, a feje platform (a hős a fejére ugorva eléri a magas párkányokat)
 *  - ORB: lebegő drón; fel- és oldalra küldhető, a magasan lévő karokat átbillenti
 */
class Companions
{
	public static inline var WHEELIE = 0;
	public static inline var TALL = 1;
	public static inline var ORB = 2;
	public static inline var COUNT = 3;

	public static final NAMES = ["WHEELIE", "TALL", "ORB"];

	public static var owned:Array<Bool> = [false, false, false];
	static var saved:Array<Bool> = [false, false, false];

	public static function reset():Void
	{
		owned = [false, false, false];
		saved = owned.copy();
	}

	public static function restore():Void
		owned = saved.copy();

	public static function commit():Void
		saved = owned.copy();
}
