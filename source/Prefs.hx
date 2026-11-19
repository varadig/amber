package;

/** Játékos-beállítások, amelyeket a böngésző megjegyez (FlxSave "amber-prefs"): eszköz-súgó (DEVICE HINTS) be / ki. */
class Prefs
{
	/** Az eszközök (terminál, láda, nyomólap, kar...) melletti súgó-kiírás (beállítások menü: DEVICE HINTS). */
	public static var hints:Bool = true;

	public static function load():Void
	{
		#if (js || desktop)
		try
		{
			var s = new flixel.util.FlxSave();
			if (s.bind("amber-prefs") && s.data.hints != null)
				hints = s.data.hints == true;
		}
		catch (e:Dynamic) {}
		#end
	}

	public static function save():Void
	{
		#if (js || desktop)
		try
		{
			var s = new flixel.util.FlxSave();
			if (s.bind("amber-prefs"))
			{
				s.data.hints = hints;
				s.flush();
			}
		}
		catch (e:Dynamic) {}
		#end
	}
}
