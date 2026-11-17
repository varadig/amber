package;

import flixel.system.FlxAssets.FlxShader;

/**
 * Lámpa-fény: egy négyzet alakú sprite-ra húzott shader, ami sugárirányú, lépcsőzetes (pixel art hatású) fényfoltot rajzol,
 * enyhe vibrálással (flicker). Additív keverés mellett használjuk (PlayState.addLamp), így a sötét termek lámpa körül kivilágosodnak.
 * Uniformok: uTime (mp), uColor (rgb 0..1), uIntensity, uFlicker (0 = állandó fény, 1 = vibráló), uSeed (lámpánként más fázis).
 */
class LampShader extends FlxShader
{
	@:glFragmentSource('
		#pragma header

		uniform float uTime;
		uniform vec3 uColor;
		uniform float uIntensity;
		uniform float uFlicker;
		uniform float uSeed;

		void main()
		{
			vec2 p = openfl_TextureCoordv * 2.0 - 1.0;
			float d = length(p);
			if (d >= 1.0)
			{
				gl_FragColor = vec4(0.0);
				return;
			}
			float fall = pow(1.0 - d, 2.0);
			float core = exp(-d * d * 14.0);
			float fl = 1.0 + uFlicker * (0.10 * sin(uTime * 13.0 + uSeed) + 0.06 * sin(uTime * 29.0 + uSeed * 2.3) + 0.04 * sin(uTime * 53.0 + uSeed * 0.7));
			float a = (fall * 0.55 + core * 0.7) * uIntensity * fl;
			// sávosított fény: pixel art hatás
			a = floor(a * 7.0 + 0.5) / 7.0;
			gl_FragColor = vec4(uColor * a, a);
		}
	')
	public function new()
	{
		super();
		uTime.value = [0.0];
		uColor.value = [1.0, 0.8, 0.45];
		uIntensity.value = [1.0];
		uFlicker.value = [1.0];
		uSeed.value = [0.0];
	}
}
