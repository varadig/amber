package;

import flixel.system.FlxAssets.FlxShader;

/**
 * Borostyán-fekete monitor: a kép fényességét borostyán árnyalatokká képezi le (mint egy régi monokróm CRT),
 * enyhe ragyogással (glow), pásztázó-vonalakkal, hordó-torzítással, peremsötétítéssel és halk vibrálással.
 * A pixel art szürkeárnyalatos (C64-paletta fényesség-lépcsői), a szín csak innen jön.
 */
class AmberShader extends FlxShader
{
	@:glFragmentSource('
		#pragma header

		uniform float uTime;

		void main()
		{
			vec2 uv = openfl_TextureCoordv;
			// enyhe hordó-torzítás
			vec2 c = uv * 2.0 - 1.0;
			c *= 1.0 + 0.028 * dot(c, c);
			vec2 q = c * 0.5 + 0.5;
			if (q.x < 0.0 || q.x > 1.0 || q.y < 0.0 || q.y > 1.0)
			{
				gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
				return;
			}
			vec2 px = vec2(1.0 / 480.0, 1.0 / 270.0);
			vec3 s = flixel_texture2D(bitmap, q).rgb;
			vec3 g = flixel_texture2D(bitmap, q + vec2(px.x, 0.0)).rgb
				+ flixel_texture2D(bitmap, q - vec2(px.x, 0.0)).rgb
				+ flixel_texture2D(bitmap, q + vec2(0.0, px.y)).rgb
				+ flixel_texture2D(bitmap, q - vec2(0.0, px.y)).rgb;
			float l = dot(s, vec3(0.299, 0.587, 0.114));
			float lg = dot(g * 0.25, vec3(0.299, 0.587, 0.114));
			float v = clamp(l + lg * 0.30, 0.0, 1.0);

			// pásztázó-vonalak (belső pixelsoronként)
			float sl = 0.86 + 0.14 * sin(q.y * 270.0 * 6.2831853);
			// halk vibrálás
			float fl = 0.985 + 0.015 * sin(uTime * 47.0) + 0.006 * sin(uTime * 3.1);
			vec3 amber = vec3(1.0, 0.60, 0.04);
			vec3 col = amber * v * sl * fl;
			// a legfényesebb részek a sárgásfehér felé tolódnak (foszfor-izzás)
			col += vec3(1.0, 0.80, 0.40) * pow(max(v - 0.78, 0.0) * 4.5, 2.0) * 0.10;
			// perem-sötétítés
			float vig = 1.0 - 0.42 * dot(c * 0.78, c * 0.78);
			col *= vig;
			// a fekete sem teljesen fekete (csőizzás)
			col += vec3(0.020, 0.009, 0.0) * vig;
			gl_FragColor = vec4(col, 1.0);
		}
	')
	public function new()
	{
		super();
		uTime.value = [0.0];
	}
}
