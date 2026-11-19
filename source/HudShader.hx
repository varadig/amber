package;

import flixel.system.FlxAssets.FlxShader;

/**
 * A HUD-kamera shadere: ugyanaz a hangulat (színrámpa, hordó-görbület, halk pásztázó-vonal, lásd Looks / AmberShader), mint a játékon,
 * de a sérülés-kisülés, az elmosás és a sötétítés nélkül, és az átlátszóságot megtartja (a HUD a játékkép fölött rajzol). Így az akku,
 * az életek és az alkatrészek minden effekt alatt tisztán olvashatók.
 */
class HudShader extends FlxShader
{
	static var all:Array<HudShader> = [];

	@:glFragmentSource('
		#pragma header

		uniform vec3 uS0;
		uniform vec3 uS1;
		uniform vec3 uS2;
		uniform vec3 uS3;
		uniform vec3 uS4;
		uniform vec3 uHi;
		uniform vec4 uLook;
		uniform vec4 uLook2;
		uniform vec3 uTop;
		uniform vec3 uBot;
		uniform float uPause;
		uniform float uTime;

		vec3 rampAt(float v)
		{
			float t = clamp(v, 0.0, 1.0) * 4.0;
			if (t < 1.0)
				return mix(uS0, uS1, t);
			if (t < 2.0)
				return mix(uS1, uS2, t - 1.0);
			if (t < 3.0)
				return mix(uS2, uS3, t - 2.0);
			return mix(uS3, uS4, t - 3.0);
		}

		void main()
		{
			vec2 c = openfl_TextureCoordv * 2.0 - 1.0;
			c *= 1.0 + uLook.y * dot(c, c);
			// szünet (a játékképpel együtt): kicsinyedés, hullámzás; a HUD is a háttérbe húzódik, csak a szünet-menü éles
			float pz = clamp(uPause, 0.0, 1.0);
			c *= 1.0 + 0.06 * pz;
			vec2 q = c * 0.5 + 0.5;
			if (pz > 0.001)
				q.x += sin(q.y * 34.0 + uTime * 2.6) * 0.0035 * pz + sin(q.y * 7.0 - uTime * 1.3) * 0.002 * pz;
			if (q.x < 0.0 || q.x > 1.0 || q.y < 0.0 || q.y > 1.0)
			{
				gl_FragColor = vec4(0.0);
				return;
			}
			vec4 t = flixel_texture2D(bitmap, q);
			if (pz > 0.001)
			{
				// enyhe elmosás: a HUD szövegei a háttérbe olvadnak
				vec2 px = vec2(1.0 / 480.0, 1.0 / 270.0) * 1.5 * pz;
				t = t * 0.4 + (flixel_texture2D(bitmap, q + vec2(px.x, 0.0)) + flixel_texture2D(bitmap, q - vec2(px.x, 0.0))
					+ flixel_texture2D(bitmap, q + vec2(0.0, px.y)) + flixel_texture2D(bitmap, q - vec2(0.0, px.y))) * 0.15;
			}
			float l = dot(t.rgb, vec3(0.299, 0.587, 0.114));
			if (uLook.w > 0.5)
				l = floor(l * uLook.w + 0.5) / uLook.w;
			float sl = 1.0 - uLook.x * 0.7 + uLook.x * 0.7 * sin(q.y * 270.0 * 6.2831853);
			vec3 col = rampAt(l) * sl;
			col += uHi * pow(max(l - 0.78, 0.0) * 4.5, 2.0) * 0.10 * t.a;
			// szünet: halványabb, sűrűbb pásztázó-vonalak
			col *= 1.0 - 0.55 * pz;
			col *= 1.0 - 0.18 * pz * (0.5 + 0.5 * sin(q.y * 270.0 * 3.14159));
			gl_FragColor = vec4(col, t.a * (1.0 - 0.35 * pz));
		}
	')
	public function new()
	{
		super();
		all.push(this);
		uPause.value = [0.0];
		uTime.value = [0.0];
		Looks.apply(this);
	}

	/** Szünet-effekt erőssége (0..1) és idő (a hullámzáshoz): a PlayState a HUD-kamera shaderén állítja (a menü-kameráén 0 marad). */
	public function setPause(p:Float, time:Float):Void
	{
		uPause.value = [p];
		uTime.value = [time];
	}

	/** A hangulat váltásakor az összes HUD-shader példány frissítése. */
	public static function refreshAll():Void
	{
		for (s in all)
			Looks.apply(s);
	}
}
