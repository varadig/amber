package;

import flixel.FlxG;
import haxe.io.Bytes;
import lime.media.AudioBuffer;
import openfl.media.Sound;

/** Egy szintetizált hangréteg leírása. */
typedef Tone =
{
	dur:Float,
	wave:Int,
	f0:Float,
	/** Végfrekvencia (exponenciális csúszás f0-ról). */
	?f1:Float,
	/** Négyszögjel kitöltési tényezője (0..1). */
	?duty:Float,
	/** Arpeggio félhangokban; arpRate lépés/mp. */
	?arp:Array<Int>,
	?arpRate:Float,
	?arpHold:Bool,
	?attack:Float,
	/** A lecsengés görbülete: (1-t)^decay. */
	?decay:Float,
	?vol:Float,
	?vibrato:Float,
	/** Mintavétel-tartás: ennyi mintánként frissül a kimenet (durvább, "8 bites" hang). */
	?crush:Int,
	/** Késleltetés a hang elején (mp). */
	?delay:Float
}

/**
 * Amiga / MOD-szerű hangok kódból: 8 bites, 22 kHz-es, szándékosan nem élsimított hullámformák, enyhe aluláteresztő szűrővel.
 * Nincsenek hangfájlok.
 */
class Audio
{
	public static inline var RATE:Int = 22050;
	public static inline var SQUARE:Int = 0;
	public static inline var SAW:Int = 1;
	public static inline var TRI:Int = 2;
	public static inline var SINE:Int = 3;
	public static inline var NOISE:Int = 4;

	static inline var MUSIC_VOLUME:Float = 0.5;
	static var sounds = new Map<String, Sound>();
	static var musicSound:Sound;
	static var initialized = false;
	public static var sfxVolume:Float = 1;
	public static var musicVolume:Float = 1;

	public static function init():Void
	{
		if (initialized)
			return;
		initialized = true;
		add("jump", [{dur: 0.14, wave: SQUARE, duty: 0.5, f0: 260, f1: 720, decay: 1.2, vol: 0.28, crush: 2}]);
		add("walljump", [{dur: 0.16, wave: SQUARE, duty: 0.25, f0: 330, f1: 900, decay: 1.1, vol: 0.28, crush: 2}, {dur: 0.05, wave: NOISE, f0: 2500, f1: 800, vol: 0.2}]);
		add("land", [{dur: 0.06, wave: NOISE, f0: 1400, f1: 300, decay: 1.5, vol: 0.22}]);
		add("dash", [{dur: 0.18, wave: NOISE, f0: 3500, f1: 700, attack: 0.02, decay: 1.0, vol: 0.32, crush: 2}, {dur: 0.18, wave: SAW, f0: 200, f1: 520, decay: 1.2, vol: 0.2}]);
		add("gem", [{dur: 0.26, wave: SQUARE, duty: 0.5, f0: 1319, arp: [0, 5], arpRate: 16, arpHold: true, decay: 1.2, vol: 0.28}]);
		add("stomp", [{dur: 0.16, wave: SQUARE, duty: 0.5, f0: 330, f1: 990, decay: 1, vol: 0.4}, {dur: 0.08, wave: NOISE, f0: 1200, f1: 400, decay: 1.4, vol: 0.3}]);
		add("kill", [{dur: 0.22, wave: NOISE, f0: 3200, f1: 200, decay: 1.2, vol: 0.45, crush: 3}, {dur: 0.2, wave: SINE, f0: 160, f1: 45, decay: 1.2, vol: 0.5}]);
		add("hurt", [{dur: 0.32, wave: SAW, f0: 520, f1: 70, decay: 1.1, vol: 0.5, crush: 3}, {dur: 0.16, wave: NOISE, f0: 2200, f1: 300, decay: 1.4, vol: 0.35}]);
		add("key", [{dur: 0.5, wave: SQUARE, duty: 0.25, f0: 523, arp: [0, 4, 7, 12, 16, 19, 24], arpRate: 18, arpHold: true, decay: 0.8, vol: 0.35}]);
		add("heal", [{dur: 0.5, wave: TRI, f0: 440, arp: [0, 5, 9, 12, 17, 21, 24], arpRate: 15, arpHold: true, decay: 0.6, vol: 0.5, vibrato: 0.2}]);
		add("checkpoint", [{dur: 0.4, wave: SQUARE, duty: 0.5, f0: 659, arp: [0, 7, 12], arpRate: 12, arpHold: true, decay: 0.9, vol: 0.3}]);
		add("door", [{dur: 0.7, wave: SQUARE, duty: 0.25, f0: 392, arp: [0, 4, 7, 12, 16, 12, 16, 19, 24], arpRate: 16, arpHold: true, decay: 0.7, vol: 0.38, vibrato: 0.12}, {dur: 0.7, wave: TRI, f0: 196, arp: [0, 7, 12, 19], arpRate: 8, arpHold: true, decay: 0.8, vol: 0.3}]);
		add("blip", [{dur: 0.035, wave: SQUARE, duty: 0.5, f0: 1760, decay: 1, vol: 0.18}]);
		add("select", [{dur: 0.12, wave: SQUARE, duty: 0.5, f0: 880, arp: [0, 7], arpRate: 18, arpHold: true, decay: 1, vol: 0.3}]);
		add("shoot", [{dur: 0.1, wave: SQUARE, duty: 0.125, f0: 1800, f1: 500, decay: 1.3, vol: 0.3, crush: 2}, {dur: 0.06, wave: NOISE, f0: 5000, f1: 1500, vol: 0.18}]);
		add("break", [{dur: 0.3, wave: NOISE, f0: 3500, f1: 200, decay: 1.2, vol: 0.55, crush: 3}, {dur: 0.2, wave: SINE, f0: 120, f1: 40, decay: 1.2, vol: 0.5}]);
		add("plate", [{dur: 0.25, wave: SQUARE, duty: 0.5, f0: 220, f1: 440, decay: 1, vol: 0.3, crush: 2}, {dur: 0.3, wave: NOISE, f0: 800, f1: 200, attack: 0.05, decay: 1, vol: 0.3}]);
		add("crumble", [{dur: 0.35, wave: NOISE, f0: 1200, f1: 300, decay: 0.8, vol: 0.3, crush: 4}]);
		add("fall", [{dur: 0.5, wave: SAW, f0: 600, f1: 60, decay: 0.8, vol: 0.4, crush: 2}]);
		musicSound = toSound(Music.render(), 2, 0.8);
	}

	static function add(name:String, layers:Array<Tone>):Void
	{
		var mix:Array<Float> = [];
		for (t in layers)
			mixInto(mix, tone(t), Std.int((t.delay != null ? t.delay : 0) * RATE), 1);
		sounds.set(name, toSound(mix, 1, 0.8));
	}

	/**
	 * A böngésző hangkörnyezete (AudioContext) induláskor felfüggesztett; a Flixel a billentyűket képkockánként olvassa (nem eseménykezelőből),
	 * ezért a zene csak egy későbbi "feléledéskor" (pause / folytatás) szólalt meg. Itt kifejezetten felélesztjük, és ha a zenét már kérték, indítjuk.
	 */
	public static function unlock():Void
	{
		#if js
		try
		{
			var ctx:Dynamic = lime.media.AudioManager.context.web;
			if (ctx != null && ctx.state != "running")
				ctx.resume();
		}
		catch (e:Dynamic) {}
		#end
		if (musicWanted && musicSound != null && (FlxG.sound.music == null || !FlxG.sound.music.playing))
			FlxG.sound.playMusic(musicSound, null, MUSIC_VOLUME * musicVolume, true);
	}

	static var musicWanted:Bool = false;

	public static function play(name:String, volume:Float = 1):Void
	{
		var s = sounds.get(name);
		if (s != null && sfxVolume > 0)
			FlxG.sound.play(s, volume * sfxVolume);
	}

	/** A háttérzene indítása (ha már szól, nem indul újra). */
	public static function playMusic():Void
	{
		if (musicSound == null)
			return;
		musicWanted = true;
		unlock();
		if (FlxG.sound.music != null && FlxG.sound.music.playing)
			return;
		FlxG.sound.playMusic(musicSound, null, MUSIC_VOLUME * musicVolume, true);
		unlock();
	}

	public static function stopMusic():Void
	{
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();
	}

	public static function pauseMusic():Void
	{
		if (FlxG.sound.music != null)
			FlxG.sound.music.pause();
	}

	public static function resumeMusic():Void
	{
		if (FlxG.sound.music != null)
			FlxG.sound.music.resume();
	}

	// --- Szintézis ---------------------------------------------------------------

	public static function mixInto(dst:Array<Float>, src:Array<Float>, start:Int, gain:Float):Void
	{
		var end = start + src.length;
		while (dst.length < end)
			dst.push(0);
		for (i in 0...src.length)
			dst[start + i] += src[i] * gain;
	}

	public static inline function osc(wave:Int, phase:Float, duty:Float, noise:Float):Float
	{
		return switch (wave)
		{
			case SQUARE: phase < duty ? 1.0 : -1.0;
			case SAW: phase * 2 - 1;
			case TRI: 1 - 4 * Math.abs(phase - 0.5);
			case SINE: Math.sin(phase * Math.PI * 2);
			default: noise;
		}
	}

	public static function tone(t:Tone):Array<Float>
	{
		var n = Std.int(t.dur * RATE);
		var f1 = t.f1 != null ? t.f1 : t.f0;
		var duty = t.duty != null ? t.duty : 0.5;
		var attack = t.attack != null ? t.attack : 0.003;
		var decay = t.decay != null ? t.decay : 1.0;
		var vol = t.vol != null ? t.vol : 1.0;
		var crush = t.crush != null ? t.crush : 1;
		var vib = t.vibrato != null ? t.vibrato : 0.0;
		var arpRate = t.arpRate != null ? t.arpRate : 50.0;

		var out:Array<Float> = [];
		var phase = 0.0, noise = 0.0, held = 0.0;
		for (i in 0...n)
		{
			var time = i / RATE;
			var p = i / n;
			var f = t.f0 * Math.pow(f1 / t.f0, p);
			if (t.arp != null)
			{
				var idx = Std.int(time * arpRate);
				idx = t.arpHold == true ? Std.int(Math.min(idx, t.arp.length - 1)) : idx % t.arp.length;
				f *= Math.pow(2, t.arp[idx] / 12);
			}
			if (vib > 0)
				f *= Math.pow(2, vib * Math.sin(time * Math.PI * 12) / 12);
			phase += f / RATE;
			if (phase >= 1)
			{
				phase -= Math.ffloor(phase);
				noise = Math.random() * 2 - 1;
			}
			var env = (time < attack ? time / attack : 1) * Math.pow(1 - p, decay);
			if (i % crush == 0)
				held = osc(t.wave, phase, duty, noise) * env * vol;
			out.push(held);
		}
		return out;
	}

	/** 8 bites WAV a mintákból (interleaved, ha sztereó), egypólusú aluláteresztő szűrővel (A500-szerű). */
	public static function toSound(samples:Array<Float>, channels:Int, lp:Float):Sound
	{
		var dataLen = samples.length;
		var b = Bytes.alloc(44 + dataLen);
		function str(pos:Int, s:String)
			for (i in 0...s.length)
				b.set(pos + i, s.charCodeAt(i));
		str(0, "RIFF");
		b.setInt32(4, 36 + dataLen);
		str(8, "WAVE");
		str(12, "fmt ");
		b.setInt32(16, 16);
		b.setUInt16(20, 1);
		b.setUInt16(22, channels);
		b.setInt32(24, RATE);
		b.setInt32(28, RATE * channels);
		b.setUInt16(32, channels);
		b.setUInt16(34, 8);
		str(36, "data");
		b.setInt32(40, dataLen);

		var state = [for (c in 0...channels) 0.0];
		for (i in 0...dataLen)
		{
			var c = i % channels;
			state[c] += (samples[i] - state[c]) * lp;
			var v = Math.max(-1, Math.min(1, state[c]));
			b.set(44 + i, Std.int(Math.round(v * 127)) + 128);
		}
		return Sound.fromAudioBuffer(AudioBuffer.fromBytes(b));
	}
}
