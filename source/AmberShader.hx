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
		uniform float uSight;
		uniform float uHit;
		uniform float uTired;
		uniform float uFocus;

		void main()
		{
			vec2 uv = openfl_TextureCoordv;
			// enyhe hordó-torzítás
			vec2 c = uv * 2.0 - 1.0;
			// VISOR-élesedés (uFocus 1 -> 0): 0..0.3 villódzás (felvillanó / elsötétülő kép, vízszintes szakadozás), 0.3..0.9 élesítő fénysáv fentről lefelé, 0.9..1 felvillanás
			float fp = 1.0 - clamp(uFocus, 0.0, 1.0);
			bool foc = uFocus > 0.0;
			float flk = 1.0;
			float fh = fract(sin(floor(uTime * 22.0) * 91.7) * 437.58);
			// a képernyő domborúsága; sérüléskor erősebben kidagad (elektromos kisülés)
			float gl = uHit * uHit;
			c *= 1.0 + (0.028 + 0.075 * uHit) * dot(c, c);
			vec2 q = c * 0.5 + 0.5;
			if (foc && fp < 0.3)
			{
				flk = fh > 0.45 ? 1.0 : 0.12;
				float fb = floor(q.y * 22.0);
				float fr = fract(sin(fb * 12.9898 + floor(uTime * 30.0) * 78.233) * 43758.5453);
				q.x += (fr - 0.5) * 0.06 * step(0.5, fr);
			}
			if (gl > 0.001)
			{
				// kisülés: sávonkénti vízszintes elcsúszás és függőleges remegés
				float bnd = floor(q.y * 28.0);
				float r1 = fract(sin(bnd * 12.9898 + floor(uTime * 40.0) * 78.233) * 43758.5453);
				q.x += (r1 - 0.5) * 0.10 * gl * step(0.55, r1);
				q.y += 0.012 * gl * sin(uTime * 90.0);
			}
			if (q.x < 0.0 || q.x > 1.0 || q.y < 0.0 || q.y > 1.0)
			{
				gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
				return;
			}
			vec2 px = vec2(1.0 / 480.0, 1.0 / 270.0);
			// látás: VISOR nélkül a kép homályos (elmosott), sötétebb és zajos; a LENS (uSight > 1) kicsit fényesít
			float sight = clamp(uSight, 0.0, 1.0);
			float tired = clamp(uTired, 0.0, 1.0);
			float sweep = 0.0;
			if (foc)
			{
				float sweepY = clamp((fp - 0.3) / 0.6, 0.0, 1.0);
				if (fp >= 0.3)
				{
					// a sáv fölötti rész már éles, alatta még homályos
					sight = q.y < sweepY ? 1.0 : sight;
					sweep = exp(-abs(q.y - sweepY) * 60.0) * step(sweepY, 0.999);
				}
				else
					sight = min(sight, 0.4);
			}
			float rad = (1.0 - sight) * 3.2 + tired * 2.6;
			vec3 s = flixel_texture2D(bitmap, q).rgb * (rad > 0.01 ? 0.34 : 1.0);
			if (rad > 0.01)
			{
				s += flixel_texture2D(bitmap, q + vec2(px.x * rad, 0.0)).rgb * 0.12;
				s += flixel_texture2D(bitmap, q - vec2(px.x * rad, 0.0)).rgb * 0.12;
				s += flixel_texture2D(bitmap, q + vec2(0.0, px.y * rad)).rgb * 0.12;
				s += flixel_texture2D(bitmap, q - vec2(0.0, px.y * rad)).rgb * 0.12;
				s += flixel_texture2D(bitmap, q + vec2(px.x, px.y) * rad * 0.7).rgb * 0.045;
				s += flixel_texture2D(bitmap, q - vec2(px.x, px.y) * rad * 0.7).rgb * 0.045;
				s += flixel_texture2D(bitmap, q + vec2(px.x, -px.y) * rad * 0.7).rgb * 0.045;
				s += flixel_texture2D(bitmap, q - vec2(px.x, -px.y) * rad * 0.7).rgb * 0.045;
			}
			vec3 g = flixel_texture2D(bitmap, q + vec2(px.x, 0.0)).rgb
				+ flixel_texture2D(bitmap, q - vec2(px.x, 0.0)).rgb
				+ flixel_texture2D(bitmap, q + vec2(0.0, px.y)).rgb
				+ flixel_texture2D(bitmap, q - vec2(0.0, px.y)).rgb;
			float l = dot(s, vec3(0.299, 0.587, 0.114));
			float lg = dot(g * 0.25, vec3(0.299, 0.587, 0.114));
			float v = clamp(l + lg * 0.30, 0.0, 1.0) * (uSight > 1.0 ? 1.12 : 1.0);
			float nz = fract(sin(dot(floor(q * vec2(480.0, 270.0)) + vec2(uTime * 37.0, uTime * 11.0), vec2(12.9898, 78.233))) * 43758.5453);
			v += (nz - 0.5) * 0.10 * (1.0 - sight);
			v *= 1.0 - 0.6 * tired;
			v *= 0.62 + 0.38 * sight;
			v *= flk;

			// pásztázó-vonalak (belső pixelsoronként)
			float sl = 0.86 + 0.14 * sin(q.y * 270.0 * 6.2831853);
			// halk vibrálás
			float fl = 0.985 + 0.015 * sin(uTime * 47.0) + 0.006 * sin(uTime * 3.1);
			vec3 amber = vec3(1.0, 0.60, 0.04);
			vec3 col = amber * v * sl * fl;
			// a legfényesebb részek a sárgásfehér felé tolódnak (foszfor-izzás)
			col += vec3(1.0, 0.80, 0.40) * pow(max(v - 0.78, 0.0) * 4.5, 2.0) * 0.10;
			// perem-sötétítés
			float vig = 1.0 - (0.42 + 0.3 * tired) * dot(c * 0.78, c * 0.78);
			// kisülés: fényes függőleges ívek és felvillanás
			float arc = step(0.982 - 0.05 * gl, fract(sin(floor(q.x * 480.0) * 7.13 + floor(uTime * 25.0) * 3.7) * 437.58)) * gl;
			col += vec3(1.0, 0.85, 0.5) * arc * 0.7;
			col *= 1.0 + gl * 0.5;
			// élesítő fénysáv és a végi felvillanás
			col += vec3(1.0, 0.82, 0.45) * sweep * 0.9;
			col *= 1.0 + (foc ? 0.7 : 0.0) * smoothstep(0.88, 0.93, fp) * (1.0 - smoothstep(0.93, 1.0, fp));
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
		uSight.value = [1.0];
		uHit.value = [0.0];
		uTired.value = [0.0];
		uFocus.value = [0.0];
	}
}
