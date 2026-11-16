package;

import flixel.system.FlxAssets.FlxShader;

/**
 * A HUD-kamera shadere: ugyanaz a borostyán árnyalat, hordó-görbület és halk pásztázó-vonal, mint a játékon (AmberShader), de a sérülés-kisülés,
 * az elmosás és a sötétítés nélkül, és az átlátszóságot megtartja (a HUD a játékkép fölött rajzol). Így a szívek, az akku és az alkatrészek
 * minden effekt alatt tisztán olvashatók.
 */
class HudShader extends FlxShader
{
	@:glFragmentSource('
		#pragma header

		void main()
		{
			vec2 c = openfl_TextureCoordv * 2.0 - 1.0;
			c *= 1.0 + 0.028 * dot(c, c);
			vec2 q = c * 0.5 + 0.5;
			if (q.x < 0.0 || q.x > 1.0 || q.y < 0.0 || q.y > 1.0)
			{
				gl_FragColor = vec4(0.0);
				return;
			}
			vec4 t = flixel_texture2D(bitmap, q);
			float l = dot(t.rgb, vec3(0.299, 0.587, 0.114));
			float sl = 0.90 + 0.10 * sin(q.y * 270.0 * 6.2831853);
			vec3 col = vec3(1.0, 0.60, 0.04) * l * sl;
			col += vec3(1.0, 0.80, 0.40) * pow(max(l - 0.78, 0.0) * 4.5, 2.0) * 0.10 * t.a;
			gl_FragColor = vec4(col, t.a);
		}
	')
	public function new()
	{
		super();
	}
}
