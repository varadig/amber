package;

/** Egy szakasz: ütemenként akkord, dallam (ütemenként 8 nyolcad-hely; null = nincs), és a használt rétegek: p pad, b zenedoboz-arpeggio, s basszus, m dallam (klarinét), t óra-kattogás. */
typedef Section =
{
	chords:Array<String>,
	melody:Array<String>,
	layers:String
}

/**
 * Ambient, "elhagyott gépváros"-hangulatú háttérzene (a Machinarium világát idézve): lassú tempó, meleg lebegő pad, zenedoboz-arpeggio,
 * pengetett basszus, klarinétszerű dallam és halk óraműszerű kattogás. Kódból renderelve, sztereó, nincs hangfájl.
 */
class Music
{
	static inline var BPM:Float = 76;
	static inline var SLOTS:Int = 8;

	static final A_CHORDS = ["Dm", "Bb", "Gm", "A"];
	static final B_CHORDS = ["F", "C", "Gm", "A", "F", "C", "Gm", "A"];
	static final B_MELODY = [
		"A4 . C5 . F5 . E5 D5",
		"E5 . D5 C5 . G4 . .",
		"Bb4 . D5 . G5 . F5 D5",
		"E5 . A4 . C#5 . E5 .",
		"A4 . C5 . F5 . G5 A5",
		"G5 . E5 . C5 . . .",
		"D5 . Bb4 . G4 . A4 Bb4",
		"A4 . . . . . . ."
	];
	static final B_MELODY2 = [
		"C5 . A4 . F4 . A4 C5",
		"G4 . E4 . C5 . . .",
		"D5 . Bb4 . D5 . G4 .",
		"A4 . C#5 . E5 . D5 C#5",
		"F5 . A5 . F5 . C5 .",
		"E5 . G5 . E5 D5 C5 .",
		"Bb4 . D5 . F5 . D5 Bb4",
		"A4 . . . E4 . . ."
	];

	// 2. készlet: derűs dúr (C)
	static final C_A = ["C", "Am", "F", "G"];
	static final C_B = ["C", "G", "Am", "F", "C", "G", "F", "G"];
	static final C_M1 = [
		"E5 . G5 . E5 . D5 C5", "D5 . B4 . D5 . G5 .", "C5 . E5 . A5 . G5 E5", "A4 . C5 . F5 . E5 C5",
		"G5 . E5 . C5 . D5 E5", "D5 . G5 . B5 . A5 G5", "A5 . F5 . C5 . A4 C5", "B4 . D5 . G5 . . ."
	];
	static final C_M2 = [
		"G5 . E5 . C5 . E5 G5", "B5 . G5 . D5 . B4 .", "A5 . E5 . C5 . E5 A5", "C6 . A5 . F5 . A5 C6",
		"E5 . G5 . C6 . G5 E5", "D5 . F5 . A5 . G5 F5", "E5 . F5 . A5 . C6 .", "D5 . . . G4 . . ."
	];
	// 3. készlet: sötét, fríg hangulatú (e-moll)
	static final E_A = ["Em", "C", "Am", "B"];
	static final E_B = ["Em", "G", "D", "Am", "Em", "C", "B", "B"];
	static final E_M1 = [
		"B4 . E5 . G5 . F#5 E5", "D5 . B4 . G5 . B5 .", "A4 . D5 . F#5 . A5 F#5", "C5 . E5 . A5 . G5 E5",
		"E5 . G5 . B5 . A5 G5", "G5 . E5 . C5 . E5 G5", "F#5 . D#5 . B4 . D#5 F#5", "B4 . . . F#4 . . ."
	];
	static final E_M2 = [
		"E5 . G5 . B5 . A5 G5", "G5 . E5 . C5 . E5 G5", "F#5 . D#5 . B4 . D#5 F#5", "B4 . . . F#4 . . .",
		"B4 . E5 . G5 . F#5 E5", "D5 . B4 . G5 . B5 .", "A4 . D5 . F#5 . A5 F#5", "C5 . E5 . A5 . G5 E5"
	];

	/**
		Pályánként más zene: harmóniakészlet + hangnem + tempó + rétegenként más hangszer (a 10 pálya 10 külön hangulat).
		lead (dallam): reed klarinét, box zenedoboz, flute fuvola, vibes vibrafon, epiano elektromos zongora, chip négyszög;
		arp (arpeggio): box, marimba, harp pengetett húr, vibes, glass üvegharang, chip; order: az arpeggio-sorrend;
		pad: warm meleg fűrész, strings vonós, choir kórus; bass: pluck pengetett, sub mély szinusz, chip háromszög;
		perc: ticks óraketyegés, drums halk dob, none.
	**/
	static final THEMES:Array<{bpm:Float, set:Int, shift:Int, lead:String, arp:String, order:Int, pad:String, bass:String, perc:String}> = [
		{bpm: 76, set: 0, shift: 0, lead: "reed", arp: "box", order: 0, pad: "warm", bass: "pluck", perc: "ticks"},
		{bpm: 84, set: 1, shift: 0, lead: "flute", arp: "marimba", order: 1, pad: "strings", bass: "pluck", perc: "ticks"},
		{bpm: 70, set: 2, shift: 0, lead: "epiano", arp: "vibes", order: 2, pad: "warm", bass: "sub", perc: "none"},
		{bpm: 88, set: 0, shift: 3, lead: "chip", arp: "chip", order: 1, pad: "strings", bass: "chip", perc: "drums"},
		{bpm: 66, set: 1, shift: -3, lead: "reed", arp: "harp", order: 2, pad: "choir", bass: "pluck", perc: "ticks"},
		{bpm: 80, set: 2, shift: 5, lead: "flute", arp: "vibes", order: 0, pad: "warm", bass: "pluck", perc: "drums"},
		{bpm: 62, set: 0, shift: -5, lead: "vibes", arp: "glass", order: 2, pad: "choir", bass: "sub", perc: "none"},
		{bpm: 92, set: 1, shift: 2, lead: "chip", arp: "harp", order: 0, pad: "strings", bass: "chip", perc: "drums"},
		{bpm: 74, set: 2, shift: -2, lead: "reed", arp: "harp", order: 1, pad: "choir", bass: "sub", perc: "ticks"},
		{bpm: 96, set: 2, shift: 2, lead: "epiano", arp: "marimba", order: 0, pad: "strings", bass: "pluck", perc: "drums"}
	];

	/** Hangszerenkénti hangerő (a különböző hangszerek nagyjából egyforma hangosan szóljanak a keverékben). */
	static final LEAD_GAIN = ["reed" => 0.3, "box" => 0.42, "flute" => 0.34, "vibes" => 0.4, "epiano" => 0.36, "chip" => 0.13];
	static final ARP_GAIN = ["box" => 0.16, "marimba" => 0.2, "harp" => 0.2, "vibes" => 0.15, "glass" => 0.12, "chip" => 0.06];
	static final PAD_GAIN = ["warm" => 0.13, "strings" => 0.11, "choir" => 0.12];
	static final BASS_GAIN = ["pluck" => 0.38, "sub" => 0.34, "chip" => 0.22];

	/** A téma rövid leírása (cheat-menü): dallam / arpeggio / pad / basszus / ritmus. */
	public static function describe(theme:Int):String
	{
		var th = THEMES[((theme % THEME_COUNT) + THEME_COUNT) % THEME_COUNT];
		return (th.lead + " " + th.arp + " " + th.pad + " " + th.bass + (th.perc == "none" ? "" : " " + th.perc)).toUpperCase();
	}

	/** Dallam- / arpeggio-hangszer (a név szerint). */
	static function voice(name:String, f:Float, len:Int):Array<Float>
	{
		return switch (name)
		{
			case "reed": reed(f, len);
			case "flute": flute(f, len);
			case "marimba": marimba(f, len);
			case "harp": pluck(f, len);
			case "vibes": fm(f, len, 4.0, 1.1, 6.0, 1.8, 0.18);
			case "epiano": fm(f, len, 1.0, 1.7, 4.0, 2.2, 0.0);
			case "glass": fm(f, len, 3.5, 2.0, 2.0, 1.1, 0.06);
			case "chip": chip(f, len);
			default: box(f, len);
		}
	}

	static function padVoice(name:String, f:Float, len:Int):Array<Float>
	{
		return switch (name)
		{
			case "strings": strings(f, len);
			case "choir": choir(f, len);
			default: pad(f, len);
		}
	}

	static function bassVoice(name:String, f:Float, len:Int):Array<Float>
	{
		return switch (name)
		{
			case "sub": subBass(f, len);
			case "chip": triBass(f, len);
			default: bassPluck(f, len);
		}
	}

	static final ARP_ORDERS = [[0, 1, 2, 3, 2, 1, 2, 1], [0, 2, 1, 3, 1, 2, 3, 2], [0, 1, 2, 1, 3, 2, 1, 2]];

	public static inline var THEME_COUNT:Int = 10;

	static function sections(set:Int):Array<Section>
	{
		var a = [A_CHORDS, C_A, E_A][set];
		var b = [B_CHORDS, C_B, E_B][set];
		var m1 = [B_MELODY, C_M1, E_M1][set];
		var m2 = [B_MELODY2, C_M2, E_M2][set];
		return [
			{chords: a, melody: null, layers: "pb"},
			{chords: a, melody: null, layers: "pbst"},
			{chords: b, melody: m1, layers: "pbstm"},
			{chords: b, melody: m2, layers: "pbstm"},
			{chords: a.concat(a), melody: null, layers: "pb"}
		];
	}

	/** A teljes dal renderelésének előkészítése: a MusicJob.step() részletekben (képkockánként néhány ms) számolja ki, hogy a játék ne akadjon;  interleaved sztereó mintákba (theme: 0..THEME_COUNT-1). A vége a elejére hajlik vissza: zökkenőmentes hurok. */
	public static function start(theme:Int = 0):MusicJob
	{
		var th = THEMES[((theme % THEME_COUNT) + THEME_COUNT) % THEME_COUNT];
		var SECTIONS = sections(th.set);
		var shift = th.shift;
		var rate = Audio.RATE;
		var eighth = 60 / th.bpm / 2 * rate;
		var bars = 0;
		for (s in SECTIONS)
			bars += s.chords.length;
		var n = Std.int(Math.ceil(bars * SLOTS * eighth)) + rate * 2;
		var left = [for (i in 0...n) 0.0];
		var right = [for (i in 0...n) 0.0];

		function put(src:Array<Float>, start:Int, gain:Float, pan:Float):Void
		{
			var gl = gain * (1 - pan) * 0.5 + gain * 0.25;
			var gr = gain * (1 + pan) * 0.5 + gain * 0.25;
			for (i in 0...src.length)
			{
				var j = start + i;
				if (j >= n)
					break;
				left[j] += src[i] * gl;
				right[j] += src[i] * gr;
			}
		}

		var tickSnd = Audio.tone({dur: 0.025, wave: Audio.NOISE, f0: 5200, decay: 2.5, vol: 0.5});
		var woodSnd = Audio.tone({dur: 0.07, wave: Audio.SINE, f0: 880, f1: 700, decay: 2, vol: 0.4});
		var kickSnd = th.perc == "drums" ? kick() : null;
		var snareSnd = th.perc == "drums" ? snare() : null;
		var hatSnd = th.perc == "drums" ? hat() : null;

		var tasks:Array<Void->Void> = [];
		var bar = 0;
		for (si in 0...SECTIONS.length)
		{
			var sec = SECTIONS[si];
			for (b in 0...sec.chords.length)
			{
				var chord0 = parseChord(sec.chords[b]);
				var chord = {root: chord0.root + shift, minor: chord0.minor};
				var barStart = (bar + b) * SLOTS * eighth;
				var third = chord.minor ? 3 : 4;
				var barLen = Std.int(SLOTS * eighth);

				// Minden hang külön kis feladat (a MusicJob időkeretet tart: egy hosszú hang renderelése se akaszthassa meg a képkockát)
				// lebegő pad: a hangok enyhén elhangolt, lassan felfutó fűrészek (alacsony oktáv)
				if (sec.layers.indexOf("p") >= 0)
				{
					var root = chord.root;
					while (root > 52)
						root -= 12;
					while (root < 45)
						root += 12;
					var pg = PAD_GAIN.get(th.pad);
					for (iv in [0, third, 7])
						tasks.push(() -> put(padVoice(th.pad, freq(root + iv), barLen + Std.int(eighth)), Std.int(barStart), pg, th.pad == "warm" ? 0 : (iv == third ? -0.3 : (iv == 7 ? 0.3 : 0))));
				}
				// zenedoboz-arpeggio: nyolcadonként egy akkordhang
				if (sec.layers.indexOf("b") >= 0)
				{
					var base = chord.root;
					while (base < 72)
						base += 12;
					while (base > 80)
						base -= 12;
					var tones = [base, base + third, base + 7, base + 12];
					var order = ARP_ORDERS[th.order];
					var ag = ARP_GAIN.get(th.arp);
					for (k in 0...SLOTS)
						tasks.push(() -> put(voice(th.arp, freq(tones[order[k]]), Std.int(eighth * 3)), Std.int(barStart + k * eighth), ag, k % 2 == 0 ? -0.35 : 0.2));
				}
				// pengetett basszus az 1. és 3. negyeden
				if (sec.layers.indexOf("s") >= 0)
				{
					var bs = chord.root;
					while (bs > 47)
						bs -= 12;
					while (bs < 38)
						bs += 12;
					var bg = BASS_GAIN.get(th.bass);
					tasks.push(() -> put(bassVoice(th.bass, freq(bs), Std.int(eighth * 3.5)), Std.int(barStart), bg, 0));
					tasks.push(() -> put(bassVoice(th.bass, freq(bs + 7), Std.int(eighth * 3)), Std.int(barStart + 4 * eighth), bg * 0.8, 0));
				}
				// ritmus: óraműszerű kattogás a 2. és 4. negyeden, halk fa-koppanás az 1.-en; vagy halk dob (lábdob, pergő, cin)
				if (th.perc == "ticks" && sec.layers.indexOf("t") >= 0)
					tasks.push(() ->
					{
						put(tickSnd, Std.int(barStart + 2 * eighth), 0.22, -0.5);
						put(tickSnd, Std.int(barStart + 6 * eighth), 0.22, 0.5);
						put(woodSnd, Std.int(barStart), 0.12, 0.2);
					});
				if (th.perc == "drums" && sec.layers.indexOf("t") >= 0)
					tasks.push(() ->
					{
						put(kickSnd, Std.int(barStart), 0.5, 0);
						put(kickSnd, Std.int(barStart + 4 * eighth), 0.42, 0);
						put(snareSnd, Std.int(barStart + 2 * eighth), 0.22, 0.1);
						put(snareSnd, Std.int(barStart + 6 * eighth), 0.22, 0.1);
						for (k in 0...4)
							put(hatSnd, Std.int(barStart + (k * 2 + 1) * eighth), 0.1, k % 2 == 0 ? 0.45 : -0.45);
					});
				// dallam: klarinétszerű (hangonként külön feladat)
				if (sec.layers.indexOf("m") >= 0 && sec.melody != null)
				{
					var toks = sec.melody[b % sec.melody.length].split(" ");
					var t = 0;
					while (t < toks.length)
					{
						var tok = toks[t];
						if (tok == ".")
						{
							t++;
							continue;
						}
						var len = 1;
						while (t + len < toks.length && toks[t + len] == ".")
							len++;
						var nf = freq(noteToMidi(tok) + shift);
						var nl = Std.int(eighth * len * 1.05);
						var nt = t;
						var lg = LEAD_GAIN.get(th.lead);
						tasks.push(() -> put(voice(th.lead, nf, nl), Std.int(barStart + nt * eighth), lg, 0.25));
						t += len;
					}
				}
			}
			bar += sec.chords.length;
		}

		// Utómunka (visszhang, hurok-összehajlítás, normalizálás, sztereó összefűzés): szeletekben, külön feladatokként, hogy ne akadjon a játék
		var SLICE = 50000;
		var delay = Std.int(eighth * 3);
		var loopLen = Std.int(bars * SLOTS * eighth);
		var peak = 0.0;
		var gain = 1.0;
		var out:Array<Float> = [];
		var i0 = delay;
		while (i0 < n)
		{
			var a = i0;
			var b = Std.int(Math.min(n, i0 + SLICE));
			// enyhe visszhang (két késleltetett másolat)
			tasks.push(() ->
			{
				for (i in a...b)
				{
					left[i] += right[i - delay] * 0.22;
					right[i] += left[i - delay] * 0.22;
				}
			});
			i0 = b;
		}
		// a dal végén túlnyúló hangok / visszhang a hurok elejére hajlanak: nincs csend és nincs "újraindulás" a hurokpontnál
		i0 = loopLen;
		while (i0 < n)
		{
			var a = i0;
			var b = Std.int(Math.min(n, i0 + SLICE));
			tasks.push(() ->
			{
				for (i in a...b)
				{
					left[i - loopLen] += left[i];
					right[i - loopLen] += right[i];
				}
			});
			i0 = b;
		}
		i0 = 0;
		while (i0 < loopLen)
		{
			var a = i0;
			var b = Std.int(Math.min(loopLen, i0 + SLICE));
			tasks.push(() ->
			{
				for (i in a...b)
					peak = Math.max(peak, Math.max(Math.abs(left[i]), Math.abs(right[i])));
			});
			i0 = b;
		}
		tasks.push(() -> gain = peak > 0 ? 0.9 / peak : 1);
		i0 = 0;
		while (i0 < loopLen)
		{
			var a = i0;
			var b = Std.int(Math.min(loopLen, i0 + SLICE));
			tasks.push(() ->
			{
				for (i in a...b)
				{
					out.push(left[i] * gain);
					out.push(right[i] * gain);
				}
			});
			i0 = b;
		}
		return new MusicJob(tasks, () -> out);
	}

	/** Teljes, egyben renderelés (tesztekhez). */
	public static function render(theme:Int = 0):Array<Float>
	{
		var j = start(theme);
		while (!j.step(1e9)) {}
		return j.result;
	}

	// --- Hangszerek ---

	/** Zenedoboz: gyorsan lecsengő, kissé inharmonikus részhangok. */
	static function box(f:Float, len:Int):Array<Float>
	{
		var rate = Audio.RATE;
		var out:Array<Float> = [];
		for (i in 0...len)
		{
			var t = i / rate;
			var v = Math.sin(2 * Math.PI * f * t) * Math.exp(-t * 3.2) + 0.45 * Math.sin(2 * Math.PI * f * 2.76 * t) * Math.exp(-t * 7) + 0.2 * Math.sin(2 * Math.PI * f * 5.4 * t) * Math.exp(-t * 12);
			out.push(v * Math.min(1, t * 400));
		}
		return out;
	}

	/** Klarinétszerű dallam: páratlan felhangok, lassú felfutás, késleltetett vibrato. */
	static function reed(f:Float, len:Int):Array<Float>
	{
		var rate = Audio.RATE;
		var out:Array<Float> = [];
		var ph = 0.0;
		var release = Std.int(0.08 * rate);
		for (i in 0...len)
		{
			var t = i / rate;
			var vib = t > 0.18 ? Math.sin(t * Math.PI * 9.5) * 0.18 : 0;
			ph += f * Math.pow(2, vib / 12) / rate;
			var v = Math.sin(2 * Math.PI * ph) + 0.33 * Math.sin(6 * Math.PI * ph) + 0.14 * Math.sin(10 * Math.PI * ph) + 0.05 * Math.sin(14 * Math.PI * ph);
			var env = Math.min(1, t / 0.07) * (0.8 + 0.2 * Math.exp(-t * 3));
			if (i > len - release)
				env *= (len - i) / release;
			out.push(v * env * 0.6);
		}
		return out;
	}

	/** Meleg pad: három enyhén elhangolt fűrész, egypólusú aluláteresztővel, lassú ki- és beúszással. */
	static function pad(f:Float, len:Int):Array<Float>
	{
		var rate = Audio.RATE;
		var out:Array<Float> = [];
		var p1 = 0.0, p2 = 0.0, p3 = 0.0, lp = 0.0;
		var att = 0.9 * rate, rel = 0.7 * rate;
		for (i in 0...len)
		{
			p1 = (p1 + f * 0.997 / rate) % 1;
			p2 = (p2 + f / rate) % 1;
			p3 = (p3 + f * 1.004 / rate) % 1;
			var raw = (p1 * 2 - 1 + p2 * 2 - 1 + p3 * 2 - 1) / 3;
			lp += (raw - lp) * 0.05;
			var env = Math.min(1, i / att) * (i > len - rel ? Math.max(0, (len - i) / rel) : 1);
			out.push(lp * env);
		}
		return out;
	}

	/** Pengetett basszus: szinusz + halk második harmonikus, puha támadás, lassú lecsengés. */
	static function bassPluck(f:Float, len:Int):Array<Float>
	{
		var rate = Audio.RATE;
		var out:Array<Float> = [];
		for (i in 0...len)
		{
			var t = i / rate;
			var v = Math.sin(2 * Math.PI * f * t) + 0.3 * Math.sin(4 * Math.PI * f * t) * Math.exp(-t * 6);
			out.push(v * Math.exp(-t * 2.2) * Math.min(1, t * 120));
		}
		return out;
	}

	// --- Új hangszerek (változatosabb hangszerelés) ---

	/** Determinisztikus zaj (a zene minden rendereléskor ugyanúgy szóljon). */
	static var seed:Int = 12345;

	static inline function rnd():Float
	{
		seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF;
		return seed / 0x7FFFFFFF * 2 - 1;
	}

	/** Hang vége: rövid lecsengés (ne kattanjon). */
	static function fadeEnd(out:Array<Float>, ms:Float):Array<Float>
	{
		var n = Std.int(Math.min(out.length, ms / 1000 * Audio.RATE));
		for (k in 0...n)
			out[out.length - 1 - k] *= k / n;
		return out;
	}

	/** Pengetett húr (Karplus-Strong): hárfa / koto-szerű, a magas hangok gyorsabban csengenek le. */
	static function pluck(f:Float, len:Int):Array<Float>
	{
		var n = Std.int(Math.max(2, Audio.RATE / f));
		var buf = [for (i in 0...n) rnd()];
		// a zajlöket lágyítása (kevésbé "csörgő" pengetés)
		for (i in 1...n)
			buf[i] = (buf[i] + buf[i - 1]) * 0.5;
		var out:Array<Float> = [];
		var idx = 0;
		for (i in 0...len)
		{
			var a = buf[idx];
			var b = buf[(idx + 1) % n];
			buf[idx] = (a + b) * 0.5 * 0.997;
			out.push(a * Math.min(1, i / 30));
			idx = (idx + 1) % n;
		}
		return fadeEnd(out, 30);
	}

	/** FM-szintézis: vibrafon / elektromos zongora / üvegharang (vivő + moduláló, lecsengő modulációs index, opcionális tremoló). */
	static function fm(f:Float, len:Int, ratio:Float, index:Float, indexDecay:Float, decay:Float, trem:Float):Array<Float>
	{
		var rate = Audio.RATE;
		var out:Array<Float> = [];
		for (i in 0...len)
		{
			var t = i / rate;
			var I = index * Math.exp(-t * indexDecay);
			var v = Math.sin(2 * Math.PI * f * t + I * Math.sin(2 * Math.PI * f * ratio * t));
			var env = Math.exp(-t * decay) * Math.min(1, t * 300) * (1 - trem + trem * Math.cos(2 * Math.PI * 5.2 * t));
			out.push(v * env);
		}
		return fadeEnd(out, 40);
	}

	/** Marimba: tompa ütés, az alaphang és a ~4x-es részhang gyorsan lecseng. */
	static function marimba(f:Float, len:Int):Array<Float>
	{
		var rate = Audio.RATE;
		var out:Array<Float> = [];
		for (i in 0...len)
		{
			var t = i / rate;
			var v = Math.sin(2 * Math.PI * f * t) * Math.exp(-t * 5) + 0.35 * Math.sin(2 * Math.PI * f * 3.93 * t) * Math.exp(-t * 16)
				+ 0.12 * Math.sin(2 * Math.PI * f * 9.2 * t) * Math.exp(-t * 40);
			out.push(v * Math.min(1, t * 500));
		}
		return fadeEnd(out, 30);
	}

	/** Fuvola: szinusz + halk felhangok, késleltetett vibrato, lágy levegőzaj. */
	static function flute(f:Float, len:Int):Array<Float>
	{
		var rate = Audio.RATE;
		var out:Array<Float> = [];
		var ph = 0.0;
		var lp = 0.0;
		var release = Std.int(0.09 * rate);
		for (i in 0...len)
		{
			var t = i / rate;
			var vib = t > 0.25 ? Math.sin(t * Math.PI * 10) * 0.12 : 0;
			ph += f * Math.pow(2, vib / 12) / rate;
			lp += (rnd() - lp) * 0.2;
			var v = Math.sin(2 * Math.PI * ph) + 0.18 * Math.sin(4 * Math.PI * ph) + 0.06 * Math.sin(6 * Math.PI * ph) + lp * 0.18;
			var env = Math.min(1, t / 0.09) * (0.85 + 0.15 * Math.exp(-t * 2));
			if (i > len - release)
				env *= (len - i) / release;
			out.push(v * env * 0.6);
		}
		return out;
	}

	/** Chiptune: 25%-os négyszög, enyhe vibrato, kissé lágyítva (ne legyen bántó). */
	static function chip(f:Float, len:Int):Array<Float>
	{
		var rate = Audio.RATE;
		var out:Array<Float> = [];
		var ph = 0.0;
		var lp = 0.0;
		for (i in 0...len)
		{
			var t = i / rate;
			var vib = t > 0.15 ? Math.sin(t * Math.PI * 12) * 0.1 : 0;
			ph = (ph + f * Math.pow(2, vib / 12) / rate) % 1;
			var raw = ph < 0.25 ? 1.0 : -0.33;
			lp += (raw - lp) * 0.35;
			out.push(lp * Math.exp(-t * 1.2) * Math.min(1, t * 400));
		}
		return fadeEnd(out, 25);
	}

	/** Vonós pad: öt elhangolt fűrész, lassú felfutás, lágyabb szűrés, enyhe közös vibrato. */
	static function strings(f:Float, len:Int):Array<Float>
	{
		var rate = Audio.RATE;
		var out:Array<Float> = [];
		var det = [0.994, 0.998, 1.0, 1.003, 1.006];
		var ph = [0.0, 0.2, 0.4, 0.6, 0.8];
		var lp = 0.0;
		var lp2 = 0.0;
		var att = 1.1 * rate, rel = 0.8 * rate;
		for (i in 0...len)
		{
			var t = i / rate;
			var vib = 1 + Math.sin(t * Math.PI * 9) * 0.0025;
			var raw = 0.0;
			for (k in 0...5)
			{
				ph[k] = (ph[k] + f * det[k] * vib / rate) % 1;
				raw += ph[k] * 2 - 1;
			}
			lp += (raw / 5 - lp) * 0.06;
			lp2 += (lp - lp2) * 0.12;
			var env = Math.min(1, i / att) * (i > len - rel ? Math.max(0, (len - i) / rel) : 1);
			out.push(lp2 * env * 1.4);
		}
		return out;
	}

	/** Kórus pad ("á" magánhangzó): egy periódusnyi hullámtábla a formánsokhoz súlyozott felhangokból, vibratóval olvasva (olcsó). */
	static function choir(f:Float, len:Int):Array<Float>
	{
		var rate = Audio.RATE;
		var TN = 256;
		var table = [for (i in 0...TN) 0.0];
		var formants = [[730.0, 1.0, 90.0], [1090.0, 0.5, 110.0], [2440.0, 0.25, 160.0]];
		var hk = 1;
		while (hk * f < 3500 && hk <= 24)
		{
			var a = 0.0;
			for (fo in formants)
				a += fo[1] * Math.exp(-Math.pow((hk * f - fo[0]) / fo[2], 2));
			a += 0.15 / hk; // alaphang-test
			for (i in 0...TN)
				table[i] += a * Math.sin(2 * Math.PI * hk * i / TN);
			hk++;
		}
		var peak = 0.0;
		for (v in table)
			peak = Math.max(peak, Math.abs(v));
		var out:Array<Float> = [];
		var ph = 0.0, ph2 = 0.37;
		var att = 0.9 * rate, rel = 0.8 * rate;
		for (i in 0...len)
		{
			var t = i / rate;
			var vib = Math.sin(t * Math.PI * 10.4) * 0.004;
			ph = (ph + f * (1 + vib) / rate) % 1;
			ph2 = (ph2 + f * 1.004 * (1 - vib) / rate) % 1;
			var v = (table[Std.int(ph * TN) % TN] + table[Std.int(ph2 * TN) % TN]) * 0.5 / (peak > 0 ? peak : 1);
			var env = Math.min(1, i / att) * (i > len - rel ? Math.max(0, (len - i) / rel) : 1);
			out.push(v * env * 0.8);
		}
		return out;
	}

	/** Mély szinusz-basszus: puha, hosszan kitartott. */
	static function subBass(f:Float, len:Int):Array<Float>
	{
		var rate = Audio.RATE;
		var out:Array<Float> = [];
		for (i in 0...len)
		{
			var t = i / rate;
			var v = Math.sin(2 * Math.PI * f * t) + 0.15 * Math.sin(4 * Math.PI * f * t);
			out.push(v * Math.exp(-t * 0.9) * Math.min(1, t * 60));
		}
		return fadeEnd(out, 40);
	}

	/** Chiptune háromszög-basszus. */
	static function triBass(f:Float, len:Int):Array<Float>
	{
		var rate = Audio.RATE;
		var out:Array<Float> = [];
		var ph = 0.0;
		for (i in 0...len)
		{
			var t = i / rate;
			ph = (ph + f / rate) % 1;
			var v = ph < 0.5 ? ph * 4 - 1 : 3 - ph * 4;
			out.push(v * Math.exp(-t * 1.6) * Math.min(1, t * 300));
		}
		return fadeEnd(out, 25);
	}

	/** Halk lábdob: lefelé söprő szinusz. */
	static function kick():Array<Float>
	{
		var rate = Audio.RATE;
		var out:Array<Float> = [];
		var ph = 0.0;
		for (i in 0...Std.int(0.3 * rate))
		{
			var t = i / rate;
			ph += (45 + 75 * Math.exp(-t * 30)) / rate;
			out.push(Math.sin(2 * Math.PI * ph) * Math.exp(-t * 9));
		}
		return out;
	}

	/** Pergő: zaj (felülvágva) + rövid hang. */
	static function snare():Array<Float>
	{
		var rate = Audio.RATE;
		var out:Array<Float> = [];
		var prev = 0.0;
		for (i in 0...Std.int(0.2 * rate))
		{
			var t = i / rate;
			var n = rnd();
			var hp = n - prev;
			prev = n;
			out.push(hp * 0.45 * Math.exp(-t * 18) + Math.sin(2 * Math.PI * 190 * t) * 0.4 * Math.exp(-t * 22));
		}
		return out;
	}

	/** Cin: rövid, magas zaj. */
	static function hat():Array<Float>
	{
		var rate = Audio.RATE;
		var out:Array<Float> = [];
		var prev = 0.0;
		for (i in 0...Std.int(0.05 * rate))
		{
			var n = rnd();
			out.push((n - prev) * 0.5 * Math.exp(-i / rate * 45));
			prev = n;
		}
		return out;
	}

	static inline function freq(midi:Float):Float
		return 440 * Math.pow(2, (midi - 69) / 12);

	static final NOTE_INDEX = ["C" => 0, "D" => 2, "E" => 4, "F" => 5, "G" => 7, "A" => 9, "B" => 11];

	/** "G#5" / "Bb5" -> MIDI hangszám. */
	static function noteToMidi(s:String):Int
	{
		var n = NOTE_INDEX.get(s.charAt(0));
		var i = 1;
		if (s.charAt(1) == "#")
		{
			n++;
			i++;
		}
		else if (s.charAt(1) == "b")
		{
			n--;
			i++;
		}
		return (Std.parseInt(s.substr(i)) + 1) * 12 + n;
	}

	/** "Dm", "Bb", "F", "A" -> gyökhang és moll-e. */
	static function parseChord(s:String):{root:Int, minor:Bool}
	{
		var minor = s.length > 1 && s.charAt(s.length - 1) == "m";
		var name = minor ? s.substr(0, s.length - 1) : s;
		return {root: noteToMidi(name + "3"), minor: minor};
	}
}

/** Részletekben (időkeretben) futó zene-renderelés: a feladatok a dal rétegei ütemenként. */
class MusicJob
{
	var tasks:Array<Void->Void>;
	var finish:Void->Array<Float>;
	var i:Int = 0;

	public var result:Array<Float>;
	public var done:Bool = false;

	public function new(tasks:Array<Void->Void>, finish:Void->Array<Float>)
	{
		this.tasks = tasks;
		this.finish = finish;
	}

	/** Legfeljebb ~ms milliszekundumnyi munkát végez; igazzal tér vissza, ha kész (result). */
	public function step(ms:Float):Bool
	{
		if (done)
			return true;
		var t0 = haxe.Timer.stamp();
		while (i < tasks.length)
		{
			tasks[i++]();
			if ((haxe.Timer.stamp() - t0) * 1000 >= ms)
				return false;
		}
		result = finish();
		done = true;
		return true;
	}
}
