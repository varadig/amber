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
		uniform float uClear;
		uniform float uClearNew;
		uniform vec2 uFocusPos;
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

		// 5 színű színrámpa (a fényességhez rendelt szín)
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

		// 4x4 rendezett (Bayer) raszter 0..1
		float bayer4(vec2 p)
		{
			vec2 a = mod(p, 2.0);
			vec2 b = mod(floor(p / 2.0), 2.0);
			float ia = a.x * 2.0 + a.y * 3.0 - a.x * a.y * 4.0;
			float ib = b.x * 2.0 + b.y * 3.0 - b.x * b.y * 4.0;
			return (ia * 4.0 + ib) / 16.0;
		}

		void main()
		{
			vec2 uv = openfl_TextureCoordv;
			// enyhe hordó-torzítás
			vec2 c = uv * 2.0 - 1.0;
			// VISOR-élesedés (uFocus 1 -> 0): 0..0.3 villódzás (felvillanó / elsötétülő kép, vízszintes szakadozás), 0.3..0.9 élesítő fénysáv fentről lefelé, 0.9..1 felvillanás
			float fp = 1.0 - clamp(uFocus, 0.0, 1.0);
			bool foc = uFocus > 0.0;
			float flk = 1.0;
			float fh = fract(sin(floor(uTime * 9.0) * 91.7) * 437.58);
			// a képernyő domborúsága; sérüléskor erősebben kidagad (elektromos kisülés)
			float gl = uHit * uHit;
			c *= 1.0 + (uLook.y + 0.075 * uHit) * dot(c, c);
			// szünet: a kép kicsit "hátrébb húzódik" (kicsinyedik), és lassan hullámzik, mint egy elhangolt adás
			float pz = clamp(uPause, 0.0, 1.0);
			c *= 1.0 + 0.06 * pz;
			vec2 q = c * 0.5 + 0.5;
			if (pz > 0.001)
			{
				q.x += sin(q.y * 34.0 + uTime * 2.6) * 0.0035 * pz + sin(q.y * 7.0 - uTime * 1.3) * 0.002 * pz;
				// időnként egy-egy vízszintes sáv elcsúszik (zavar a képben)
				float pb = floor(q.y * 45.0);
				float pr = fract(sin(pb * 41.3 + floor(uTime * 6.0) * 17.1) * 43758.5453);
				q.x += (pr - 0.5) * 0.02 * pz * step(0.93, pr);
			}
			if (foc && fp < 0.3)
			{
				flk = 0.86 + 0.14 * fh; // enyhe vibrálás (régen 1 / 0.12 villogás: túl erős volt)
				float fb = floor(q.y * 22.0);
				float fr = fract(sin(fb * 12.9898 + floor(uTime * 30.0) * 78.233) * 43758.5453);
				q.x += (fr - 0.5) * 0.008 * step(0.8, fr);
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
			float tired = clamp(uTired, 0.0, 1.0);
			float sweep = 0.0;
			// tiszta látás sugara (px): a robot körül éles, kifelé átmenetesen homályos; az élesítő sáv felett már az új (nagyobb) sugár érvényes
			float clearR = uClear;
			if (foc)
			{
				float sweepY = clamp((fp - 0.3) / 0.6, 0.0, 1.0);
				if (fp >= 0.3)
				{
					clearR = q.y < sweepY ? uClearNew : uClear;
					sweep = exp(-abs(q.y - sweepY) * 60.0) * step(sweepY, 0.999);
				}
			}
			float dpx = length((q - uFocusPos / vec2(480.0, 270.0)) * vec2(480.0, 270.0));
			float blurK = clearR > 640.0 ? 0.0 : smoothstep(clearR, clearR * 1.6 + 30.0, dpx);
			float sight = min(clamp(uSight, 0.0, 1.0), mix(1.0, 0.0, blurK));
			if (foc && fp < 0.3)
				sight = min(sight, 0.75);
			float rad = (1.0 - sight) * 3.2; // (az alacsony akku nem mos el: zavaró volt)
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
			// (az alacsony akku nem sötétít: zavaró volt; csak enyhe peremsötétítés marad)
			v *= 0.62 + 0.38 * sight;
			v *= flk;
			// kevés színű (poszterizált) hangulat, pl. kézi konzol
			if (uLook.w > 0.5)
				v = floor(v * uLook.w + 0.5) / uLook.w;

			// pásztázó-vonalak (belső pixelsoronként)
			float sl = 1.0 - uLook.x + uLook.x * sin(q.y * 270.0 * 6.2831853);
			// halk vibrálás
			float fl = 1.0 - uLook.z + uLook.z * sin(uTime * 47.0) + 0.006 * sin(uTime * 3.1);
			// színátmenet-leképezés: a fényességből a hangulat (Looks) három színű rámpája (sötét - közép - világos)
			if (uLook2.y > 0.0)
				v = clamp(v + (bayer4(floor(q * vec2(480.0, 270.0))) - 0.5) * uLook2.y, 0.0, 1.0);
			// szünet: halványabb, kontrasztszegényebb kép (a menü kiemelkedik), lépcsős fényesség (régi monitor-állókép)
			if (pz > 0.001)
			{
				float vp = floor(v * 7.0 + 0.5) / 7.0;
				v = mix(v, vp * 0.62 + 0.06, pz);
			}
			vec3 ramp = rampAt(v);
			float ab = max(uLook2.x, 2.6 * pz);
			if (ab > 0.0)
			{
				// kromatikus aberráció: a vörös és a kék csatorna vízszintesen szétcsúszik (szünetben is)
				vec3 lw = vec3(0.299, 0.587, 0.114);
				float l0 = dot(flixel_texture2D(bitmap, q).rgb, lw);
				float dr = dot(flixel_texture2D(bitmap, q + vec2(px.x * ab, 0.0)).rgb, lw) - l0;
				float db = dot(flixel_texture2D(bitmap, q - vec2(px.x * ab, 0.0)).rgb, lw) - l0;
				ramp = vec3(rampAt(v + dr).r, ramp.g, rampAt(v + db).b);
			}
			// ég / talaj színezés (felül és alul más árnyalat)
			if (uLook2.z > 0.0)
				ramp *= mix(vec3(1.0), mix(uBot, uTop, 1.0 - q.y), uLook2.z);
			vec3 col = ramp * sl * fl;
			// a legfényesebb részek a kiemelő szín felé tolódnak (foszfor-izzás)
			col += uHi * pow(max(v - 0.78, 0.0) * 4.5, 2.0) * 0.10;
			// perem-sötétítés
			float vig = 1.0 - (0.42 + 0.12 * tired) * dot(c * 0.78, c * 0.78);
			// kisülés: fényes függőleges ívek és felvillanás
			float arc = step(0.982 - 0.05 * gl, fract(sin(floor(q.x * 480.0) * 7.13 + floor(uTime * 25.0) * 3.7) * 437.58)) * gl;
			col += uHi * arc * 0.7;
			col *= 1.0 + gl * 0.5;
			// élesítő fénysáv és a végi felvillanás
			col += uHi * sweep * 0.35;
			col *= 1.0 + (foc ? 0.18 : 0.0) * smoothstep(0.88, 0.93, fp) * (1.0 - smoothstep(0.93, 1.0, fp));
			if (pz > 0.001)
			{
				// szünet: lassan lefelé gördülő világos sáv (képcső-hengerlés), sűrűbb pásztázó-vonalak, erősebb perem-sötétítés
				float roll = fract(q.y * 0.9 - uTime * 0.22);
				col += uHi * exp(-pow((roll - 0.5) * 9.0, 2.0)) * 0.10 * pz;
				col *= 1.0 - 0.18 * pz * (0.5 + 0.5 * sin(q.y * 270.0 * 3.14159));
				vig *= 1.0 - 0.35 * pz * dot(c, c);
			}
			col *= vig;
			// a fekete sem teljesen fekete (csőizzás)
			col += uS2 * 0.04 * vig;
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
		uClear.value = [700.0];
		uClearNew.value = [700.0];
		uFocusPos.value = [240.0, 135.0];
		uPause.value = [0.0];
		Looks.apply(this);
	}
}
