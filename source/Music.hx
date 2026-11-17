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

	/** Pályánként más zene: harmóniakészlet + hangnem + tempó + hangszerelés (a 10 pálya 10 külön hangulat). */
	static final THEMES:Array<{bpm:Float, set:Int, shift:Int, lead:String, arp:Int, ticks:Bool}> = [
		{bpm: 76, set: 0, shift: 0, lead: "reed", arp: 0, ticks: true},
		{bpm: 84, set: 1, shift: 0, lead: "box", arp: 1, ticks: true},
		{bpm: 70, set: 2, shift: 0, lead: "reed", arp: 2, ticks: true},
		{bpm: 88, set: 0, shift: 3, lead: "box", arp: 1, ticks: false},
		{bpm: 66, set: 1, shift: -3, lead: "reed", arp: 2, ticks: true},
		{bpm: 80, set: 2, shift: 5, lead: "reed", arp: 0, ticks: false},
		{bpm: 62, set: 0, shift: -5, lead: "reed", arp: 2, ticks: true},
		{bpm: 92, set: 1, shift: 2, lead: "box", arp: 0, ticks: false},
		{bpm: 74, set: 2, shift: -2, lead: "reed", arp: 1, ticks: true},
		{bpm: 96, set: 2, shift: 2, lead: "box", arp: 0, ticks: true}
	];

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

				// lebegő pad: a hangok enyhén elhangolt, lassan felfutó fűrészek (alacsony oktáv)
				if (sec.layers.indexOf("p") >= 0)
					tasks.push(() ->
					{
					var root = chord.root;
					while (root > 52)
						root -= 12;
					while (root < 45)
						root += 12;
					for (iv in [0, third, 7])
						put(pad(freq(root + iv), barLen + Std.int(eighth)), Std.int(barStart), 0.13, 0);
					});
				// zenedoboz-arpeggio: nyolcadonként egy akkordhang
				if (sec.layers.indexOf("b") >= 0)
					tasks.push(() ->
					{
					var base = chord.root;
					while (base < 72)
						base += 12;
					while (base > 80)
						base -= 12;
					var tones = [base, base + third, base + 7, base + 12];
					var order = ARP_ORDERS[th.arp];
					for (k in 0...SLOTS)
						put(box(freq(tones[order[k]]), Std.int(eighth * 3)), Std.int(barStart + k * eighth), 0.16, k % 2 == 0 ? -0.35 : 0.2);
					});
				// pengetett basszus az 1. és 3. negyeden
				if (sec.layers.indexOf("s") >= 0)
					tasks.push(() ->
					{
					var bs = chord.root;
					while (bs > 47)
						bs -= 12;
					while (bs < 38)
						bs += 12;
					put(bassPluck(freq(bs), Std.int(eighth * 3.5)), Std.int(barStart), 0.38, 0);
					put(bassPluck(freq(bs + 7), Std.int(eighth * 3)), Std.int(barStart + 4 * eighth), 0.3, 0);
					});
				// óraműszerű kattogás a 2. és 4. negyeden, halk fa-koppanás az 1.-en
				if (th.ticks && sec.layers.indexOf("t") >= 0)
					tasks.push(() ->
					{
					put(tickSnd, Std.int(barStart + 2 * eighth), 0.22, -0.5);
					put(tickSnd, Std.int(barStart + 6 * eighth), 0.22, 0.5);
					put(woodSnd, Std.int(barStart), 0.12, 0.2);
					});
				// dallam: klarinétszerű
				if (sec.layers.indexOf("m") >= 0 && sec.melody != null)
					tasks.push(() ->
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
						put(th.lead == "box" ? box(nf, nl) : reed(nf, nl), Std.int(barStart + t * eighth), th.lead == "box" ? 0.42 : 0.3, 0.25);
						t += len;
					}
					});
			}
			bar += sec.chords.length;
		}

		function finish():Array<Float>
		{
		// normalizálás + enyhe visszhang (két késleltetett másolat)
		var delay = Std.int(eighth * 3);
		for (i in delay...n)
		{
			left[i] += right[i - delay] * 0.22;
			right[i] += left[i - delay] * 0.22;
		}
		// a dal végén túlnyúló hangok / visszhang a hurok elejére hajlanak: nincs csend és nincs "újraindulás" a hurokpontnál
		var loopLen = Std.int(bars * SLOTS * eighth);
		for (i in loopLen...n)
		{
			left[i - loopLen] += left[i];
			right[i - loopLen] += right[i];
		}
		n = loopLen;
		var peak = 0.0;
		for (i in 0...n)
			peak = Math.max(peak, Math.max(Math.abs(left[i]), Math.abs(right[i])));
		var g = peak > 0 ? 0.9 / peak : 1;
		var out:Array<Float> = [];
		for (i in 0...n)
		{
			out.push(left[i] * g);
			out.push(right[i] * g);
		}
		return out;
		}
		return new MusicJob(tasks, finish);
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
