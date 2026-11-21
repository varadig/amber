package;

import flixel.util.FlxSave;
import haxe.Http;
import haxe.Json;

/** Egy ranglista-sor. */
typedef LbEntry =
{
	name:String,
	score:Int,
	level:Int,
	atoms:Int,
	completed:Bool
}

/**
 * Globális ranglista (Supabase REST, mint a Moonshardban): `assets/config/leaderboard.json` (url / key / table; az anon / publishable kulcs
 * nyilvános, a védelmet a táblán a Row Level Security adja; lásd docs/LEADERBOARD.md). Ha az url vagy a kulcs üres, a funkció nem látszik.
 *
 * - `submit`: egy futás beküldése (3 betűs név, pont, elért pálya, atomok, végigjátszotta-e).
 * - `fetch`: a legjobb 10; a munkamenetben gyorsítótárazott, a beküldés érvényteleníti.
 * Cheat-buildben (-debug / -Dtest / -Dcheats) nem lehet beküldeni (a tesztelés ne szennyezze a listát), kivéve a `?lburl=` teszt-paraméterrel
 * (a scripts/devserver.js mock-jára: `?lburl=http://127.0.0.1:<port>&lbkey=x`).
 */
class Leaderboard
{
	public static inline var NAME_LEN:Int = 3;
	public static inline var LIMIT:Int = 10;
	static inline var CONFIG:String = "assets/config/leaderboard.json";

	static var url:String = "";
	static var key:String = "";
	static var table:String = "amber_scores";
	static var loaded:Bool = false;
	/** Teszt-mód (cheat-build, ?lburl=): ilyenkor a beküldés is engedett. */
	static var testMode:Bool = false;

	static var save:FlxSave;
	static var cache:Array<LbEntry> = null;

	/** A legutóbb beküldött sor (a lista kiemeléséhez). */
	public static var lastName:String = "";
	public static var lastScore:Int = -1;

	static function load():Void
	{
		if (loaded)
			return;
		loaded = true;
		try
		{
			if (openfl.utils.Assets.exists(CONFIG))
			{
				var c:Dynamic = Json.parse(openfl.utils.Assets.getText(CONFIG));
				url = c.url != null ? StringTools.trim(Std.string(c.url)) : "";
				key = c.key != null ? StringTools.trim(Std.string(c.key)) : "";
				if (c.table != null && Std.string(c.table) != "")
					table = StringTools.trim(Std.string(c.table));
			}
		}
		catch (e:Dynamic)
			trace("Leaderboard: hibás " + CONFIG + ": " + e);
		while (StringTools.endsWith(url, "/"))
			url = url.substr(0, url.length - 1);
		#if (cheats && js)
		// teszteléshez: ?lburl=...&lbkey=... felülírja a beállítást (csak cheat-buildben), és engedi a beküldést
		var q = js.Browser.location.search;
		var mu = ~/lburl=([^&]+)/;
		if (mu.match(q))
		{
			url = StringTools.urlDecode(mu.matched(1));
			testMode = true;
		}
		var mk = ~/lbkey=([^&]+)/;
		if (mk.match(q))
			key = StringTools.urlDecode(mk.matched(1));
		#end
	}

	/** Be van-e állítva a szolgáltatás (URL + kulcs). */
	public static function configured():Bool
	{
		load();
		return url != "" && key != "";
	}

	/** Lehet-e pontot beküldeni (cheat-buildben csak a teszt-paraméterrel). */
	public static function canSubmit():Bool
	{
		#if cheats
		return configured() && testMode;
		#else
		return configured();
		#end
	}

	static function bind():FlxSave
	{
		if (save == null)
		{
			save = new FlxSave();
			save.bind("amber-leaderboard");
		}
		return save;
	}

	/** A játékos mentett neve (3 nagybetű), alapból "AMB". */
	public static function savedName():String
	{
		var v:Null<String> = Reflect.field(bind().data, "name");
		return v != null && v.length == NAME_LEN ? v : "AMB";
	}

	public static function saveName(name:String):Void
	{
		var s = bind();
		Reflect.setField(s.data, "name", name);
		s.flush();
	}

	/** Eszközönként egyszer generált véletlen azonosító (visszaélés-szűréshez), nem személyes adat. */
	static function device():String
	{
		var s = bind();
		var v:Null<String> = Reflect.field(s.data, "device");
		if (v == null)
		{
			v = "";
			for (i in 0...16)
				v += StringTools.hex(Std.random(16)).toLowerCase();
			Reflect.setField(s.data, "device", v);
			s.flush();
		}
		return v;
	}

	static function request(path:String, post:Null<String>, onOk:String->Void, onFail:String->Void):Void
	{
		var h = new Http(url + "/rest/v1/" + path);
		h.setHeader("apikey", key);
		h.setHeader("Authorization", "Bearer " + key);
		if (post != null)
		{
			h.setHeader("Content-Type", "application/json");
			h.setHeader("Prefer", "return=minimal");
			h.setPostData(post);
		}
		h.onData = onOk;
		h.onError = onFail;
		try
			h.request(post != null)
		catch (e:Dynamic)
			onFail(Std.string(e));
	}

	/** Egy futás beküldése; `level` = az elért pálya (1-től), `done(true)` siker esetén. */
	public static function submit(name:String, score:Int, level:Int, atoms:Int, completed:Bool, done:Bool->Void):Void
	{
		if (!canSubmit())
		{
			done(false);
			return;
		}
		var body = Json.stringify({
			name: name,
			score: score,
			level: level,
			atoms: atoms,
			completed: completed,
			device: device()
		});
		request(table, body, _ ->
		{
			lastName = name;
			lastScore = score;
			cache = null;
			saveName(name);
			done(true);
		}, _ -> done(false));
	}

	/** A legjobb `LIMIT` sor; `done(null)` hiba esetén. */
	public static function fetch(done:Null<Array<LbEntry>>->Void):Void
	{
		if (cache != null)
		{
			done(cache);
			return;
		}
		if (!configured())
		{
			done(null);
			return;
		}
		var path = table + "?select=name,score,level,atoms,completed&order=score.desc&limit=" + LIMIT;
		request(path, null, text ->
		{
			try
			{
				var rows:Array<Dynamic> = Json.parse(text);
				var out:Array<LbEntry> = [
					for (r in rows)
						{
							name: Std.string(r.name),
							score: Std.int(r.score),
							level: Std.int(r.level),
							atoms: r.atoms != null ? Std.int(r.atoms) : 0,
							completed: r.completed == true
						}
				];
				cache = out;
				done(out);
			}
			catch (e:Dynamic)
				done(null);
		}, _ -> done(null));
	}
}
