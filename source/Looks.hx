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
	poster:Float,
	/** Színes hangulat: 5 színű rámpa (ha van, ez a dark/mid/light helyett). */
	?stops:Array<Array<Float>>,
	/** Kromatikus aberráció (px): a vörös / kék csatorna szétcsúszik. */
	?aberr:Float,
	/** Rendezett (Bayer) raszterezés erőssége. */
	?dither:Float,
	/** Függőleges színezés (ég / talaj): erősség és a felső / alsó szorzó szín. */
	?vgrad:Float,
	?top:Array<Float>,
	?bot:Array<Float>
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
		{name: "CLEAN MONO (NO CRT)", dark: [0, 0, 0], mid: [0.45, 0.47, 0.50], light: [0.95, 0.97, 1.0], hi: [1.0, 1.0, 1.0], scan: 0.0, curve: 0.0, flick: 0.0, poster: 0},
		// --- színes hangulatok: több színű rámpa (a fényességhez több árnyalat rendelődik), ég / talaj színezés, aberráció, raszter ---
		colorLook("SUNSET GRADIENT", [[0.04, 0.02, 0.15], [0.35, 0.08, 0.45], [0.85, 0.20, 0.40], [1.0, 0.55, 0.20], [1.0, 0.95, 0.70]], [1.0, 0.9, 0.6], 0.06, 0.012, 0.008, 0, 0, 0.55, [0.85, 0.85, 1.2], [1.15, 0.95, 0.75]),
		colorLook("AURORA", [[0.0, 0.02, 0.08], [0.0, 0.22, 0.34], [0.10, 0.62, 0.45], [0.55, 0.90, 0.55], [0.92, 1.0, 0.85]], [0.8, 1.0, 0.9], 0.05, 0.015, 0.008, 0, 0, 0.6, [0.8, 1.1, 1.1], [1.15, 0.8, 1.15]),
		colorLook("CYBERPUNK", [[0.02, 0.0, 0.08], [0.10, 0.10, 0.50], [0.0, 0.70, 0.90], [0.95, 0.30, 0.70], [1.0, 0.92, 1.0]], [1.0, 0.6, 1.0], 0.12, 0.035, 0.015, 1.4, 0, 0.0, [1, 1, 1], [1, 1, 1]),
		colorLook("CANDY POP", [[0.15, 0.10, 0.25], [0.45, 0.35, 0.70], [0.95, 0.55, 0.75], [0.60, 0.90, 0.85], [1.0, 0.98, 0.85]], [1.0, 1.0, 0.9], 0.0, 0.0, 0.0, 0, 0, 0.35, [1.1, 1.05, 1.15], [1.1, 1.0, 0.9]),
		colorLook("DEEP SEA", [[0.0, 0.02, 0.05], [0.0, 0.12, 0.25], [0.0, 0.35, 0.50], [0.20, 0.65, 0.70], [0.80, 0.95, 0.90]], [0.7, 1.0, 1.0], 0.04, 0.02, 0.01, 0.6, 0, 0.7, [1.2, 1.2, 1.0], [0.6, 0.8, 1.1]),
		colorLook("FIRE & ICE", [[0.0, 0.03, 0.20], [0.10, 0.25, 0.60], [0.50, 0.50, 0.55], [0.95, 0.50, 0.15], [1.0, 0.90, 0.40]], [1.0, 0.8, 0.5], 0.08, 0.02, 0.01, 0.4, 0, 0.0, [1, 1, 1], [1, 1, 1]),
		colorLook("CGA DITHER", [[0.0, 0.0, 0.0], [0.0, 0.67, 0.67], [0.67, 0.0, 0.67], [1.0, 0.33, 1.0], [1.0, 1.0, 1.0]], [1.0, 1.0, 1.0], 0.0, 0.0, 0.0, 0, 0.55, 0.0, [1, 1, 1], [1, 1, 1]),
		colorLook("NEON NOIR", [[0.0, 0.0, 0.0], [0.20, 0.20, 0.22], [0.50, 0.50, 0.52], [0.90, 0.15, 0.20], [1.0, 0.80, 0.80]], [1.0, 0.5, 0.5], 0.10, 0.025, 0.012, 0.5, 0, 0.0, [1, 1, 1], [1, 1, 1]),
		colorLook("DAYLIGHT", [[0.05, 0.07, 0.15], [0.20, 0.30, 0.50], [0.50, 0.60, 0.55], [0.90, 0.80, 0.50], [1.0, 1.0, 0.90]], [1.0, 1.0, 0.85], 0.0, 0.0, 0.0, 0, 0, 0.8, [0.75, 0.95, 1.3], [1.15, 1.0, 0.8]),
		colorLook("FOREST DUSK", [[0.02, 0.05, 0.04], [0.10, 0.22, 0.12], [0.35, 0.45, 0.18], [0.75, 0.65, 0.30], [0.98, 0.93, 0.70]], [1.0, 0.95, 0.7], 0.05, 0.015, 0.006, 0, 0, 0.7, [0.8, 0.95, 1.2], [1.1, 0.95, 0.8])
	];

	/** Színes hangulat összeállítása (a dark / mid / light a rámpa 1., 3. és 5. színe, a régi shader-ágak miatt). */
	static function colorLook(name:String, stops:Array<Array<Float>>, hi:Array<Float>, scan:Float, curve:Float, flick:Float, aberr:Float, dither:Float, vgrad:Float,
			top:Array<Float>, bot:Array<Float>):Look
	{
		return {
			name: name, dark: stops[0], mid: stops[2], light: stops[4], hi: hi, scan: scan, curve: curve, flick: flick, poster: 0,
			stops: stops, aberr: aberr, dither: dither, vgrad: vgrad, top: top, bot: bot
		};
	}

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
		// 5 színű rámpa: a 3 színűből a köztes színek számolódnak (ugyanaz a lineáris átmenet)
		function mix(a:Array<Float>, b:Array<Float>):Array<Float>
			return [for (i in 0...3) (a[i] + b[i]) / 2];
		var st = l.stops != null ? l.stops : [l.dark, mix(l.dark, l.mid), l.mid, mix(l.mid, l.light), l.light];
		shader.uS0.value = st[0];
		shader.uS1.value = st[1];
		shader.uS2.value = st[2];
		shader.uS3.value = st[3];
		shader.uS4.value = st[4];
		shader.uHi.value = l.hi;
		shader.uLook.value = [l.scan, l.curve, l.flick, l.poster];
		var ab:Float = l.aberr != null ? l.aberr : 0.0;
		var di:Float = l.dither != null ? l.dither : 0.0;
		var vg:Float = l.vgrad != null ? l.vgrad : 0.0;
		shader.uLook2.value = [ab, di, vg, 0.0];
		shader.uTop.value = l.top != null ? l.top : [1.0, 1.0, 1.0];
		shader.uBot.value = l.bot != null ? l.bot : [1.0, 1.0, 1.0];
	}
}
