package;

#if cheats
import flixel.FlxG;

/**
 * Fejlesztői mentés (csak cheat-build; release-ben nincs): bármikor onnan folytatható a játék, ahol abbahagytuk.
 * - "latest": a PlayState 5 mp-enként és az oldal elhagyásakor (frissítés, bezárás) elmenti a pillanatnyi állapotot.
 * - Minden betöltéskor (böngésző-frissítés, élő újratöltés) a "latest"-ből egy dátummal / idővel jelölt mentés lesz (legfeljebb MAX).
 * - A cheat-menü SAVE STATES lapja listázza (legújabb elöl); kiválasztva betöltődik (PlayState.devLoad).
 * Tárolás: localStorage (JSON). A teszt-build nem ment automatikusan (a tesztek ne szemeteljék tele a listát).
 */
class DevSave
{
	static inline var KEY_LIST = "amber-devsaves";
	static inline var KEY_LATEST = "amber-devsave-latest";
	static inline var MAX = 30;

	/** A betöltendő pillanatkép: a PlayState.create a végén alkalmazza (devApply). */
	public static var pending:Dynamic = null;

	static function store():Dynamic
	{
		#if js
		try
		{
			return js.Browser.window.localStorage;
		}
		catch (e:Dynamic) {}
		#end
		return null;
	}

	public static function list():Array<Dynamic>
	{
		var s = store();
		if (s == null)
			return [];
		try
		{
			var raw:String = s.getItem(KEY_LIST);
			var a:Array<Dynamic> = raw != null ? haxe.Json.parse(raw) : [];
			return a != null ? a : [];
		}
		catch (e:Dynamic)
		{
			return [];
		}
	}

	static function writeList(a:Array<Dynamic>):Void
	{
		var s = store();
		if (s == null)
			return;
		while (a.length > MAX)
			a.pop();
		try
		{
			s.setItem(KEY_LIST, haxe.Json.stringify(a));
		}
		catch (e:Dynamic) {}
	}

	/** Helyi dátum + idő: "2026-11-19 10:42:13". */
	public static function stamp():String
	{
		var d = Date.now();
		inline function p(n:Int):String
			return (n < 10 ? "0" : "") + n;
		return d.getFullYear() + "-" + p(d.getMonth() + 1) + "-" + p(d.getDate()) + " " + p(d.getHours()) + ":" + p(d.getMinutes()) + ":" + p(d.getSeconds());
	}

	/** A pillanatnyi állapot mentése "latest"-ként (automatikus, 5 mp-enként és kilépéskor). */
	public static function saveLatest(snap:Dynamic):Void
	{
		#if !test
		var s = store();
		if (s == null || snap == null)
			return;
		snap.when = stamp();
		try
		{
			s.setItem(KEY_LATEST, haxe.Json.stringify(snap));
		}
		catch (e:Dynamic) {}
		#end
	}

	public static function latest():Dynamic
	{
		var s = store();
		if (s == null)
			return null;
		try
		{
			var raw:String = s.getItem(KEY_LATEST);
			return raw != null ? haxe.Json.parse(raw) : null;
		}
		catch (e:Dynamic)
		{
			return null;
		}
	}

	/** Betöltéskor: az előző munkamenet utolsó állapota (latest) bekerül a listába a saját dátumával (ha még nincs benne). */
	public static function snapshotOnLoad():Void
	{
		#if !test
		var l = latest();
		if (l == null || l.when == null)
			return;
		var a = list();
		if (a.length > 0 && a[0].when == l.when)
			return;
		a.unshift(l);
		writeList(a);
		#end
	}

	/** Kézi mentés (cheat-menü: SAVE NOW): azonnal a lista elejére. */
	public static function saveNow(snap:Dynamic):Void
	{
		snap.when = stamp();
		var a = list();
		a.unshift(snap);
		writeList(a);
	}

	/** A lista egy sora a menühöz: "2026-11-19 10:42:13  L2 COPPER WELLS  (3 PARTS)". */
	public static function describe(s:Dynamic):String
	{
		var n = 0;
		var f:Array<Dynamic> = s.found;
		if (f != null)
			for (x in f)
				if (x == true)
					n++;
		return s.when + "  L" + (Std.int(s.level) + 1) + " " + (s.name != null ? s.name : "") + "  (" + n + "P " + s.atoms + "A)";
	}
}
#end
