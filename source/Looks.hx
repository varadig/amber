package;

/** Egy vizuális hangulat (a képernyő-shader színrámpája és a CRT-jegyek). */
typedef Look =
{
	name:String,
	dark:Array<Float>,
	mid:Array<Float>,
	light:Array<Float>,
	/** Kiemelés (izzás, kisülés, élesítő sáv) színe. */
	hi:Array<Float>,
	/** Pásztázó-vonalak erőssége. */
	scan:Float,
	/** Hordó-görbület. */
	curve:Float,
	/** Vibrálás. */
	flick:Float,
	/** Poszterizálás: a fényesség ennyi lépcsőre (0 = folytonos). */
	poster:Float
}

/**
 * Hangulat-készlet a képernyő-shaderhez (a pixel art szürkeárnyalatos, a színt a shader adja: fényesség -> 3 színű rámpa).
 * A fejlesztői (cheat) buildben a cheat-menüből váltható (LOOK), és a választás megmarad a következő betöltésre (FlxSave).
 * Release-ben mindig az alap (AMBER).
 */
class Looks
{
	public static final LIST:Array<Look> = [
		{name: "AMBER (DEFAULT)", dark: [0, 0, 0], mid: [0.5, 0.30, 0.02], light: [1.0, 0.60, 0.04], hi: [1.0, 0.80, 0.40], scan: 0.14, curve: 0.028, flick: 0.015, poster: 0},
		{name: "GREEN PHOSPHOR", dark: [0, 0.01, 0], mid: [0.06, 0.42, 0.10], light: [0.40, 1.0, 0.40], hi: [0.75, 1.0, 0.75], scan: 0.16, curve: 0.03, flick: 0.02, poster: 0},
		{name: "ICE BLUE", dark: [0, 0.01, 0.04], mid: [0.08, 0.28, 0.52], light: [0.55, 0.88, 1.0], hi: [0.9, 1.0, 1.0], scan: 0.12, curve: 0.028, flick: 0.012, poster: 0},
		{name: "HANDHELD (4 SHADES)", dark: [0.06, 0.22, 0.06], mid: [0.33, 0.52, 0.12], light: [0.61, 0.74, 0.06], hi: [0.61, 0.74, 0.06], scan: 0.0, curve: 0.0, flick: 0.0, poster: 3},
		{name: "SEPIA PAPER", dark: [0.06, 0.035, 0.02], mid: [0.42, 0.30, 0.18], light: [0.93, 0.82, 0.62], hi: [1.0, 0.95, 0.80], scan: 0.08, curve: 0.015, flick: 0.005, poster: 0},
		{name: "VIOLET NEON", dark: [0.02, 0, 0.05], mid: [0.48, 0.08, 0.55], light: [1.0, 0.42, 0.78], hi: [1.0, 0.85, 1.0], scan: 0.14, curve: 0.035, flick: 0.02, poster: 0},
		{name: "RED ALERT", dark: [0.03, 0, 0], mid: [0.45, 0.04, 0.03], light: [1.0, 0.18, 0.10], hi: [1.0, 0.60, 0.50], scan: 0.14, curve: 0.03, flick: 0.02, poster: 0},
		{name: "CLEAN MONO (NO CRT)", dark: [0, 0, 0], mid: [0.45, 0.47, 0.50], light: [0.95, 0.97, 1.0], hi: [1.0, 1.0, 1.0], scan: 0.0, curve: 0.0, flick: 0.0, poster: 0}
	];

	public static var current:Int = 0;

	static function save():Void
	{
		#if (cheats && js)
		try
		{
			var s = new flixel.util.FlxSave();
			if (s.bind("amber-look"))
			{
				s.data.look = current;
				s.flush();
			}
		}
		catch (e:Dynamic) {}
		#end
	}

	/** A mentett hangulat betöltése (csak fejlesztői buildben; release-ben az alap). */
	public static function load():Void
	{
		#if (cheats && js)
		try
		{
			var s = new flixel.util.FlxSave();
			if (s.bind("amber-look") && s.data.look != null)
				current = Std.int(Math.max(0, Math.min(LIST.length - 1, s.data.look)));
		}
		catch (e:Dynamic) {}
		#end
	}

	/** Beállítja a hangulatot (a képernyő- és a HUD-shaderen is), és elmenti. */
	public static function set(i:Int):Void
	{
		current = (i + LIST.length) % LIST.length;
		save();
		Main.applyLook();
		HudShader.refreshAll();
	}

	public static function next():Void
		set(current + 1);

	/** A shader uniformjainak beállítása az aktuális hangulatból (AmberShader / HudShader). */
	public static function apply(shader:Dynamic):Void
	{
		var l = LIST[current];
		shader.uDark.value = l.dark;
		shader.uMid.value = l.mid;
		shader.uLight.value = l.light;
		shader.uHi.value = l.hi;
		shader.uLook.value = [l.scan, l.curve, l.flick, l.poster];
	}
}
