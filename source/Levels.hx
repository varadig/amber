package;

/** Egy kampány-pálya: a Tiled-fájl (levels/<file>.tmj), a zenetéma (0..9), a háttér-stílus (0..9) és hogy a WALKER-ek fele HUNTER legyen-e. */
typedef LevelEntry =
{
	file:String,
	music:Int,
	backdrop:Int,
	hunters:Bool
}

/**
 * A játékban elérhető pályák és sorrendjük (kampány). EZ a lista dönti el, mi kerül a játékba és milyen sorrendben:
 * új pálya: tedd a .tmj-t a levels/ mappába, és vegyél fel ide egy sort; sorrendváltás: a sorok cseréje (a zene / háttér a pályával megy).
 * A pálya sorszáma (PlayState.level) a listabeli helye; a pálya neve a .tmj `name` tulajdonságából jön.
 * Ami nincs a listában (pl. level0.tmj), csak a dev buildben érhető el (cheat-menü: WORLD > LEVEL SELECT, URL: ?map=level0).
 * Hiányzó / hibás fájl helyett a generátor készít pályát (LevelData.generate, RECIPES). Ellenőrzés: tests/validate-levels.ps1.
 * (A kiinduló tartalmat a meglévő level1..level10 fájlokból generáltuk.)
 */
class Levels
{
	public static final CAMPAIGN:Array<LevelEntry> = [
		{file: "level1", music: 0, backdrop: 0, hunters: false}, // 1. RUSTED CAVES
		{file: "level2", music: 1, backdrop: 1, hunters: true}, // 2. COPPER WELLS
		{file: "level3", music: 2, backdrop: 2, hunters: true}, // 3. NEON RUINS
		{file: "level4", music: 3, backdrop: 3, hunters: true}, // 4. DEEP STATIC
		{file: "level5", music: 4, backdrop: 4, hunters: true}, // 5. THE HOLLOW
		{file: "level6", music: 5, backdrop: 5, hunters: true}, // 6. SIGNAL TOWERS
		{file: "level7", music: 6, backdrop: 6, hunters: true}, // 7. GLASS GARDEN
		{file: "level8", music: 7, backdrop: 7, hunters: true}, // 8. BLACK RELAY
		{file: "level9", music: 8, backdrop: 8, hunters: true}, // 9. THE LONG DARK
		{file: "level10", music: 9, backdrop: 9, hunters: true}, // 10. THE AMBER CORE
	];

	public static inline function count():Int
		return CAMPAIGN.length;

	static function entry(i:Int):LevelEntry
		return i >= 0 && i < CAMPAIGN.length ? CAMPAIGN[i] : null;

	/** A pálya fájlneve (kiterjesztés nélkül); a listán kívüli sorszámra null. */
	public static function fileOf(i:Int):String
	{
		var e = entry(i);
		return e == null ? null : e.file;
	}

	public static function musicOf(i:Int):Int
	{
		var e = entry(i);
		return e == null ? i : e.music;
	}

	public static function backdropOf(i:Int):Int
	{
		var e = entry(i);
		return e == null ? i % 10 : e.backdrop;
	}

	public static function huntersOf(i:Int):Bool
	{
		var e = entry(i);
		return e == null ? i >= 1 : e.hunters;
	}

	/** A fájl helye a kampányban (0-tól), vagy -1, ha nincs benne. */
	public static function indexOfFile(file:String):Int
	{
		for (i in 0...CAMPAIGN.length)
			if (CAMPAIGN[i].file == file)
				return i;
		return -1;
	}
}
