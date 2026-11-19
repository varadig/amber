package;

/**
 * Hangminőség az APU (hang-processzor, Parts.AUDIO) szintjéből: a HANGEFFEKTEK "digital reducer" effekttel rontva
 * (mintavétel- és bitmélység-csökkentés: recsegős, butított hang; Audio.reduce / setSfxQuality). A zene tiszta marad.
 * Fokozatok: 0 = nincs APU (legerősebb, de élvezhető), 1..4 egyre tisztább, 5 (V. szint) = tiszta.
 * Képkockánként a Main hívja (update): szintváltáskor az összes hangeffekt újraépül.
 */
class AudioFx
{
	/** A jelenlegi fokozat (0..5) az APU szintjéből. */
	public static function quality():Int
		return Parts.has(Parts.AUDIO) ? [0, 1, 3, 5][Std.int(Math.min(3, Parts.tier(Parts.AUDIO)))] : 0;

	public static function update():Void
		Audio.setSfxQuality(quality());

	/** Teszthez. */
	public static function debug():String
		return "q=" + Audio.sfxQuality();
}
