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

	static final SECTIONS:Array<Section> = [
		{chords: A_CHORDS, melody: null, layers: "pb"},
		{chords: A_CHORDS, melody: null, layers: "pbst"},
		{chords: B_CHORDS, melody: B_MELODY, layers: "pbstm"},
		{chords: B_CHORDS, melody: B_MELODY2, layers: "pbstm"},
		{chords: A_CHORDS.concat(A_CHORDS), melody: null, layers: "pb"}
	];

	/** A teljes dal renderelése interleaved sztereó mintákba. */
	public static function render():Array<Float>
	{
		var rate = Audio.RATE;
		var eighth = 60 / BPM / 2 * rate;
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

		var bar = 0;
		for (si in 0...SECTIONS.length)
		{
			var sec = SECTIONS[si];
			for (b in 0...sec.chords.length)
			{
				var chord = parseChord(sec.chords[b]);
				var barStart = (bar + b) * SLOTS * eighth;
				var third = chord.minor ? 3 : 4;
				var barLen = Std.int(SLOTS * eighth);

				// lebegő pad: a hangok enyhén elhangolt, lassan felfutó fűrészek (alacsony oktáv)
				if (sec.layers.indexOf("p") >= 0)
				{
					var root = chord.root;
					while (root > 52)
						root -= 12;
					while (root < 45)
						root += 12;
					for (iv in [0, third, 7])
						put(pad(freq(root + iv), barLen + Std.int(eighth)), Std.int(barStart), 0.13, 0);
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
					var order = [0, 1, 2, 3, 2, 1, 2, 1];
					for (k in 0...SLOTS)
						put(box(freq(tones[order[k]]), Std.int(eighth * 3)), Std.int(barStart + k * eighth), 0.16, k % 2 == 0 ? -0.35 : 0.2);
				}
				// pengetett basszus az 1. és 3. negyeden
				if (sec.layers.indexOf("s") >= 0)
				{
					var bs = chord.root;
					while (bs > 47)
						bs -= 12;
					while (bs < 38)
						bs += 12;
					put(bassPluck(freq(bs), Std.int(eighth * 3.5)), Std.int(barStart), 0.38, 0);
					put(bassPluck(freq(bs + 7), Std.int(eighth * 3)), Std.int(barStart + 4 * eighth), 0.3, 0);
				}
				// óraműszerű kattogás a 2. és 4. negyeden, halk fa-koppanás az 1.-en
				if (sec.layers.indexOf("t") >= 0)
				{
					put(tickSnd, Std.int(barStart + 2 * eighth), 0.22, -0.5);
					put(tickSnd, Std.int(barStart + 6 * eighth), 0.22, 0.5);
					put(woodSnd, Std.int(barStart), 0.12, 0.2);
				}
				// dallam: klarinétszerű
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
						put(reed(freq(noteToMidi(tok)), Std.int(eighth * len * 1.05)), Std.int(barStart + t * eighth), 0.3, 0.25);
						t += len;
					}
				}
			}
			bar += sec.chords.length;
		}

		// normalizálás + enyhe visszhang (két késleltetett másolat)
		var delay = Std.int(eighth * 3);
		for (i in delay...n)
		{
			left[i] += right[i - delay] * 0.22;
			right[i] += left[i - delay] * 0.22;
		}
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
