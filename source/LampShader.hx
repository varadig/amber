package;

import flixel.system.FlxAssets.FlxShader;

/**
 * Lámpa-fény a képernyőn: egy teljes képernyős sprite-ra húzott shader, ami
 *  - a lámpák alatt valódi fénynyalábot (kúp) rajzol, enyhe ködösséggel és a nyalábban lebegő porszemekkel,
 *  - a lámpák körül kis ragyogást ad,
 *  - a lámpás termekben (uZ0 / uZ1 téglalapok) sötétséget terít a képre, amit a fény kivilágosít (a hős, a falak, az ellenségek is sötétednek / világosodnak).
 * Egyszerre legfeljebb 8 lámpa: uAn = (x, y, hatótáv, erősség) képernyő-pixelben, uBn = (irány-x, irány-y, cos(fél nyílásszög), magszám: negatív = nem vibrál).
 * A kimenet előszorzott alfa: a sötétség az alfa, a köd a szín (normál keverés).
 */
class LampShader extends FlxShader
{
	@:glFragmentSource('
		#pragma header

		uniform float uTime;
		uniform float uAmbient;
		uniform vec4 uZ0;
		uniform vec4 uZ1;
		uniform vec4 uA0; uniform vec4 uB0;
		uniform vec4 uA1; uniform vec4 uB1;
		uniform vec4 uA2; uniform vec4 uB2;
		uniform vec4 uA3; uniform vec4 uB3;
		uniform vec4 uA4; uniform vec4 uB4;
		uniform vec4 uA5; uniform vec4 uB5;
		uniform vec4 uA6; uniform vec4 uB6;
		uniform vec4 uA7; uniform vec4 uB7;

		float zoneAt(vec4 z, vec2 p)
		{
			if (z.z <= 0.0)
				return 0.0;
			return (p.x >= z.x && p.x <= z.x + z.z && p.y >= z.y && p.y <= z.y + z.w) ? 1.0 : 0.0;
		}

		// x: megvilágítás, y: látható köd (csak a nyalábban)
		vec2 lampAt(vec4 A, vec4 B, vec2 p)
		{
			if (A.z <= 0.0)
				return vec2(0.0);
			vec2 v = p - A.xy;
			float d = length(v);
			float fl = 1.0;
			if (B.w > 0.0)
				fl = 1.0 + 0.10 * sin(uTime * 13.0 + B.w) + 0.06 * sin(uTime * 29.0 + B.w * 2.3) + 0.04 * sin(uTime * 53.0 + B.w * 0.7);
			float halo = exp(-d * d / (A.z * A.z * 0.025)) * 0.9;
			float beam = 0.0;
			if (d < A.z && d > 0.5)
			{
				float ca = dot(v / d, B.xy);
				float cone = smoothstep(B.z - 0.10, B.z + 0.05, ca);
				beam = cone * pow(1.0 - d / A.z, 1.4);
			}
			return vec2(halo + beam, beam) * A.w * fl;
		}

		void main()
		{
			vec2 p = openfl_TextureCoordv * vec2(480.0, 270.0);
			vec2 s = lampAt(uA0, uB0, p) + lampAt(uA1, uB1, p) + lampAt(uA2, uB2, p) + lampAt(uA3, uB3, p)
				+ lampAt(uA4, uB4, p) + lampAt(uA5, uB5, p) + lampAt(uA6, uB6, p) + lampAt(uA7, uB7, p);
			float lit = clamp(s.x, 0.0, 1.0);
			lit = floor(lit * 6.0 + 0.5) / 6.0;
			float amb = max(zoneAt(uZ0, p), zoneAt(uZ1, p)) * uAmbient;
			float dark = amb * (1.0 - lit);
			// köd a nyalábban
			float haze = floor(clamp(s.y, 0.0, 1.0) * 8.0 + 0.5) / 8.0 * 0.32;
			haze = clamp(haze, 0.0, 1.0);
			vec3 col = vec3(1.0, 0.85, 0.55) * haze;
			gl_FragColor = vec4(col, dark);
		}
	')
	public function new()
	{
		super();
		uTime.value = [0.0];
		uAmbient.value = [0.36];
		uZ0.value = [0.0, 0.0, 0.0, 0.0];
		uZ1.value = [0.0, 0.0, 0.0, 0.0];
		for (i in 0...8)
		{
			Reflect.field(data, "uA" + i).value = [0.0, 0.0, 0.0, 0.0];
			Reflect.field(data, "uB" + i).value = [0.0, 1.0, 0.0, 0.0];
		}
	}
}
