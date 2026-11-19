package;

/**
 * Lokalizáció nyelvi fájlokból: lang/<kód>.json (beágyazva: assets/lang/). Minden ott lévő fájl választható nyelv
 * (szünet-menü / cheat-menü: LANGUAGE, a böngésző megjegyzi: FlxSave "amber-lang"). A játék szövegei a kódban angolul vannak (forrás);
 * a fordítás kiíráskor történik (LangText), soronként:
 *   1. strings: teljes sor (angol -> fordítás),
 *   2. patterns: változó részeket tartalmazó sor (regex az angol szövegre; a kimenetben $N = csoport, {names:N} = a csoport
 *      név-fordítása, {text:N} = a csoport teljes fordítása),
 *   3. names: nevek (alkatrész, pálya, címke) kifejezésenkénti cseréje a szövegben (a hosszabbakkal kezdve),
 *   majd chars: a fontban hiányzó betűk helyettesítése (pl. ő -> õ).
 * Ami nincs a fájlban, angolul marad; a már lefordított szöveg változatlanul átmegy. Angolul (en) nincs fordítás: a forrás az angol.
 * Új nyelv: az en.json másolata lang/<kód>.json néven, lefordítva, majd új build.
 */
class Lang
{
	/** A választott nyelv kódja ("en", "hu", ...). */
	public static var code(default, null):String = "en";
	/** Kompatibilitás: magyar-e a nyelv. */
	public static var hu(get, never):Bool;

	static function get_hu():Bool
		return code == "hu";

	static var table:LangTable = null;
	static var cache:Map<String, String> = new Map();
	static var langs:Array<{code:String, name:String, id:String}> = null;
	/** Az élő LangText-ek: nyelvváltáskor újrafordítják a szövegüket. */
	public static var live:Array<LangText> = [];

	/** Az elérhető nyelvek (a beágyazott lang/*.json fájlokból), az angol elöl. */
	public static function available():Array<{code:String, name:String, id:String}>
	{
		if (langs != null)
			return langs;
		langs = [];
		for (id in openfl.utils.Assets.list(openfl.utils.AssetType.TEXT))
			if (StringTools.startsWith(id, "assets/lang/") && StringTools.endsWith(id, ".json"))
			{
				try
				{
					var j:Dynamic = haxe.Json.parse(openfl.utils.Assets.getText(id));
					var c = j.code != null ? Std.string(j.code) : id.substring(12, id.length - 5);
					langs.push({code: c, name: j.name != null ? Std.string(j.name) : c.toUpperCase(), id: id});
				}
				catch (e:Dynamic) {}
			}
		if (langs.length == 0)
			langs.push({code: "en", name: "ENGLISH", id: null});
		langs.sort((a, b) -> a.code == "en" ? -1 : (b.code == "en" ? 1 : (a.code < b.code ? -1 : 1)));
		return langs;
	}

	/** A választott nyelv megjelenített neve (pl. "MAGYAR"). */
	public static function displayName():String
	{
		for (l in available())
			if (l.code == code)
				return l.name;
		return code.toUpperCase();
	}

	public static function load():Void
	{
		var c = "en";
		#if (js || desktop)
		try
		{
			var s = new flixel.util.FlxSave();
			if (s.bind("amber-lang"))
			{
				if (s.data.code != null)
					c = Std.string(s.data.code);
				else if (s.data.hu == true)
					c = "hu"; // régi mentés
			}
		}
		catch (e:Dynamic) {}
		#end
		select(c);
	}

	/** Nyelv választása kód szerint (true / false: kompatibilitás, magyar / angol); mentve, az élő szövegek újrafordulnak. */
	public static function set(v:Dynamic):Void
	{
		var c:String = Std.isOfType(v, Bool) ? (v == true ? "hu" : "en") : Std.string(v);
		select(c);
		#if (js || desktop)
		try
		{
			var s = new flixel.util.FlxSave();
			if (s.bind("amber-lang"))
			{
				s.data.code = code;
				s.data.hu = null;
				s.flush();
			}
		}
		catch (e:Dynamic) {}
		#end
		for (t in live.copy())
			t.retranslate();
	}

	/** A következő elérhető nyelvre vált (szünet-menü, cheat-menü). */
	public static function next():Void
	{
		var l = available();
		var i = 0;
		for (k in 0...l.length)
			if (l[k].code == code)
				i = k;
		set(l[(i + 1) % l.length].code);
	}

	static function select(c:String):Void
	{
		cache = new Map();
		table = null;
		code = "en";
		for (l in available())
			if (l.code == c && l.id != null)
			{
				code = c;
				if (c != "en")
					table = LangTable.parse(openfl.utils.Assets.getText(l.id));
			}
	}

	/** Szöveg fordítása (több sor: soronként). Angolul változatlan. */
	public static function t(s:String):String
	{
		if (table == null || s == null || s == "")
			return s;
		var c = cache.get(s);
		if (c != null)
			return c;
		var out = [for (line in s.split("\n")) table.chars(line1(line))].join("\n");
		cache.set(s, out);
		return out;
	}

	/** Egy sor: a bal oldali kijelölő ("> " / "  ") és a szélső szóközök megmaradnak. */
	static function line1(line:String):String
	{
		if (line == "")
			return line;
		var lead = "";
		while (lead.length < line.length && line.charAt(lead.length) == " ")
			lead += " ";
		var core = line.substr(lead.length);
		if (StringTools.startsWith(core, "> "))
		{
			lead += "> ";
			core = core.substr(2);
		}
		var tail = "";
		while (core.length > 0 && core.charAt(core.length - 1) == " ")
		{
			tail += " ";
			core = core.substr(0, core.length - 1);
		}
		return lead + table.tr(core) + tail;
	}

	/** Nevek cseréje a szövegben (a választott nyelven). */
	public static function names(s:String):String
		return table == null ? s : table.names(s);
}

/** Egy nyelvi fájl betöltve: teljes sorok, minták, nevek, betű-helyettesítések. */
class LangTable
{
	var strings:Map<String, String> = new Map();
	var nameMap:Map<String, String> = new Map();
	var nameKeys:Array<String> = [];
	var patterns:Array<{re:EReg, out:String}> = [];
	var charMap:Map<String, String> = new Map();

	public function new() {}

	public static function parse(text:String):LangTable
	{
		var t = new LangTable();
		try
		{
			var j:Dynamic = haxe.Json.parse(text);
			if (j.strings != null)
				for (k in Reflect.fields(j.strings))
					t.strings.set(k, Std.string(Reflect.field(j.strings, k)));
			if (j.names != null)
				for (k in Reflect.fields(j.names))
					t.nameMap.set(k, Std.string(Reflect.field(j.names, k)));
			if (j.chars != null)
				for (k in Reflect.fields(j.chars))
					t.charMap.set(k, Std.string(Reflect.field(j.chars, k)));
			if (j.patterns != null)
				for (p in (j.patterns : Array<Dynamic>))
					try
					{
						t.patterns.push({re: new EReg(Std.string(p.match), ""), out: Std.string(p.out)});
					}
					catch (e:Dynamic) {}
		}
		catch (e:Dynamic) {}
		t.nameKeys = [for (k in t.nameMap.keys()) k];
		t.nameKeys.sort((a, b) -> b.length - a.length);
		return t;
	}

	public function tr(s:String):String
	{
		var d = strings.get(s);
		if (d != null)
			return d;
		for (p in patterns)
			if (p.re.match(s))
				return expand(p.re, p.out);
		return names(s);
	}

	/** A minta kimenete: $N = csoport, {names:N} = a csoport név-fordítása, {text:N} = a csoport teljes fordítása. */
	function expand(re:EReg, out:String):String
	{
		var b = new StringBuf();
		var i = 0;
		while (i < out.length)
		{
			var c = out.charAt(i);
			if (c == "$" && i + 1 < out.length && out.charCodeAt(i + 1) >= "0".code && out.charCodeAt(i + 1) <= "9".code)
			{
				var g = re.matched(out.charCodeAt(i + 1) - "0".code);
				b.add(g != null ? g : "");
				i += 2;
				continue;
			}
			if (c == "{")
			{
				var end = out.indexOf("}", i);
				var parts = end > i ? out.substring(i + 1, end).split(":") : [];
				if (parts.length == 2 && (parts[0] == "names" || parts[0] == "text"))
				{
					var g = re.matched(Std.parseInt(parts[1]));
					if (g == null)
						g = "";
					b.add(parts[0] == "names" ? names(g) : full(g));
					i = end + 1;
					continue;
				}
			}
			b.add(c);
			i++;
		}
		return b.toString();
	}

	/** Teljes fordítás (pl. egy fejlesztés-leírás): pontos sor, különben névcsere. */
	function full(s:String):String
	{
		var d = strings.get(s);
		return d != null ? d : names(s);
	}

	/** A nevek kifejezésenkénti cseréje (egész szavakra, a hosszabbakkal kezdve). */
	public function names(s:String):String
	{
		var out = s;
		for (k in nameKeys)
		{
			var v = nameMap.get(k);
			if (v == k)
				continue;
			var i = out.indexOf(k);
			while (i >= 0)
			{
				var before = i == 0 ? " " : out.charAt(i - 1);
				var after = i + k.length >= out.length ? " " : out.charAt(i + k.length);
				if (isSep(before) && isSep(after))
				{
					out = out.substr(0, i) + v + out.substr(i + k.length);
					i = out.indexOf(k, i + v.length);
				}
				else
					i = out.indexOf(k, i + 1);
			}
		}
		return out;
	}

	static inline function isSep(c:String):Bool
		return c == " " || c == "(" || c == ")" || c == "," || c == ":" || c == "\n";

	/** A fontban hiányzó betűk helyettesítése. */
	public function chars(s:String):String
	{
		var out = s;
		for (k in charMap.keys())
			if (out.indexOf(k) >= 0)
				out = out.split(k).join(charMap.get(k));
		return out;
	}
}
