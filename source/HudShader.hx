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
			vec2 q = c * 0.5 + 0.5;
			if (q.x < 0.0 || q.x > 1.0 || q.y < 0.0 || q.y > 1.0)
			{
				gl_FragColor = vec4(0.0);
				return;
			}
			vec4 t = flixel_texture2D(bitmap, q);
			float l = dot(t.rgb, vec3(0.299, 0.587, 0.114));
			if (uLook.w > 0.5)
				l = floor(l * uLook.w + 0.5) / uLook.w;
			float sl = 1.0 - uLook.x * 0.7 + uLook.x * 0.7 * sin(q.y * 270.0 * 6.2831853);
			vec3 col = rampAt(l) * sl;
			col += uHi * pow(max(l - 0.78, 0.0) * 4.5, 2.0) * 0.10 * t.a;
			gl_FragColor = vec4(col, t.a);
		}
	')
	public function new()
	{
		super();
		all.push(this);
		Looks.apply(this);
	}

	/** A hangulat váltásakor az összes HUD-shader példány frissítése. */
	public static function refreshAll():Void
	{
		for (s in all)
			Looks.apply(s);
	}
}
