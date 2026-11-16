package;

/** Cheat-kapu: a cheat kód csak `#if cheats` alatt fordul (haxedef: -debug, -Dtest, -Dcheats); a release-ben nincs benne. */
class Cheats
{
	/** Futott-e cheat az aktuális játékmenetben. */
	public static var used:Bool = false;
}
