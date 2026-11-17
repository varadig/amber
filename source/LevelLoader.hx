package;

import LevelData.PartSpawn;
import LevelData.Pt;
import haxe.Json;

/** A Tiled JSON (levels/levelN.tmj) beolvasása LevelData-vá (a formátum: LevelFormat, docs/LEVELS.md). Hibánál null: a játék a generátort használja. */
class LevelLoader
{
	/** A pálya betöltése: a beágyazott Tiled-térkép, ennek hiányában / hibájában a generátor. */
	public static function load(level:Int):LevelData
	{
		var id = "assets/levels/level" + (level + 1) + ".tmj";
		if (openfl.utils.Assets.exists(id))
		{
			var d = parse(level, openfl.utils.Assets.getText(id));
			if (d != null)
				return d;
		}
		return LevelData.generate(level);
	}

	static function propsOf(arr:Dynamic, base:Dynamic = null):Dynamic
	{
		var r:Dynamic = {};
		if (base != null)
			for (f in Reflect.fields(base))
				Reflect.setField(r, f, Reflect.field(base, f));
		if (arr != null)
			for (p in (arr : Array<Dynamic>))
				Reflect.setField(r, p.name, p.value);
		return r;
	}

	static inline function num(v:Dynamic, def:Float):Float
		return v == null ? def : (v : Float);

	static function err(msg:String):LevelData
	{
		trace("LevelLoader: " + msg);
		return null;
	}

	public static function parse(level:Int, text:String):LevelData
	{
		var m:Dynamic;
		try
			m = Json.parse(text)
		catch (e:Dynamic)
			return err("érvénytelen JSON: " + e);
		var d = new LevelData(level);
		d.fromTiled = true;
		d.w = m.width;
		if (m.height != LevelData.H || m.tilewidth != LevelData.T)
			return err("a térkép mérete / csempemérete nem egyezik (" + m.width + "x" + m.height + ", csempe " + m.tilewidth + ")");
		var mp = propsOf(m.properties);
		if (mp.name != null)
			d.name = mp.name;
		d.killRow = mp.killRow != null ? Std.int(mp.killRow) : LevelData.H - 8;
		d.solid = [for (_ in 0...(d.w * LevelData.H)) 0];
		d.plats = [for (_ in 0...(d.w * LevelData.H)) 0];
		for (f in Reflect.fields(mp))
			if (StringTools.startsWith(f, "seq"))
				d.seqs.set(Std.parseInt(f.substr(3)), [for (s in Std.string(Reflect.field(mp, f)).split(",")) Std.parseInt(StringTools.trim(s))]);

		var rooms:Map<Int, {x:Int, y:Int, w:Int, h:Int}> = new Map();
		var outer:Map<Int, Pt> = new Map();
		var inner:Map<Int, Pt> = new Map();
		var ok = true;
		var objFirst = LevelFormat.OBJ_FIRST;
		if (m.tilesets != null)
			for (ts in (m.tilesets : Array<Dynamic>))
				if (ts.source != null && Std.string(ts.source).indexOf("objects") >= 0)
					objFirst = ts.firstgid;

		function object(o:Dynamic):Void
		{
			if (o.visible == false)
				return;
			var cls:String = Reflect.field(o, "class");
			if (cls == null || cls == "")
				cls = Reflect.field(o, "type");
			var def:Dynamic = null;
			var x:Float = o.x;
			var y:Float = o.y;
			if (o.gid != null)
			{
				var idx = ((o.gid : Int) & 0x0FFFFFFF) - objFirst;
				if (idx >= 0 && idx < LevelFormat.SPRITES.length)
				{
					var sd = LevelFormat.SPRITES[idx];
					if (cls == null || cls == "")
						cls = sd.cls;
					def = sd.def;
				}
				y -= num(o.height, 0); // a csempe-objektum origója a bal alsó sarok
			}
			if (cls == null)
				return;
			var p = propsOf(o.properties, def);
			var pt:Pt = {x: x, y: y};
			var id:Int = p.id != null ? Std.int(p.id) : 0;
			switch (cls)
			{
				case "Spawn": d.spawn = pt;
				case "Door": d.door = pt;
				case "Checkpoint": d.checkpoints.push(pt);
				case "Gem": d.gems.push(pt);
				case "Heart": d.hearts.push(pt);
				case "Battery": d.batteries.push(pt);
				case "Spike": d.spikes.push(pt);
				case "Cracked": d.crackeds.push(pt);
				case "Crumble": d.crumbles.push(pt);
				case "Grate": d.grates.push(pt);
				case "Crate": d.crates.push(pt);
				case "Cell": d.cells.push(pt);
				case "Gate": d.gates.push({x: x, y: y, id: id, lock: p.lock == true});
				case "Plate": d.plates.push({x: x, y: y, id: id, hold: p.hold == true});
				case "Lever": d.levers.push({x: x, y: y, id: id});
				case "Switch": d.switches.push({x: x, y: y, id: id, idx: Std.int(num(p.idx, 0)), label: Std.string(p.label)});
				case "Socket": d.sockets.push({x: x, y: y, id: id});
				case "Key": d.keys.push({x: x, y: y, id: id});
				case "PowerCell": d.powerCells.push({x: x, y: y, id: id});
				case "Bench": d.benches.push({x: x, y: y, comp: Std.int(num(p.comp, 0))});
				case "Terminal": d.terminals.push({x: x, y: y, id: id, game: Std.int(num(p.game, 0))});
				case "Mover":
					d.movers.push({
						x: x,
						y: y,
						w: Std.int(num(p.w, 3)),
						axis: p.axis == "y" ? "y" : "x",
						range: num(p.range, 64),
						speed: num(p.speed, 40),
						id: p.id != null && Std.int(p.id) >= 0 ? Std.int(p.id) : null,
						active: p.active != false
					});
				case "Enemy":
					var k = LevelFormat.ENEMY_KINDS.indexOf(Std.string(p.kind));
					d.enemies.push({kind: k < 0 ? 0 : k, x: x, y: y});
				case "Part":
					var ps:PartSpawn = {icon: Std.int(num(p.icon, 0)), label: p.label != null ? Std.string(p.label) : "", x: x, y: y};
					if (p.friend != null && Std.int(p.friend) >= 0)
						ps.friend = Std.int(p.friend);
					d.parts.push(ps);
				case "Text":
					var t:Dynamic = o.text;
					d.texts.push({x: x, y: y, text: t != null ? Std.string(t.text) : ""});
				case "BuildingRoom":
					rooms.set(id, {
						x: Std.int(o.x / LevelData.T),
						y: Std.int(o.y / LevelData.T),
						w: Std.int(Math.round(num(o.width, 0) / LevelData.T)),
						h: Std.int(Math.round(num(o.height, 0) / LevelData.T))
					});
				case "BuildingDoor":
					var r = Std.int(num(p.room, 0));
					(p.inside == true ? inner : outer).set(r, pt);
				case "Decor":
					d.decor.push({
						x: Std.int(o.x / LevelData.T),
						y: Std.int(o.y / LevelData.T),
						w: Std.int(Math.round(num(o.width, 0) / LevelData.T)),
						h: Std.int(Math.round(num(o.height, 0) / LevelData.T))
					});
				default:
					trace("LevelLoader: ismeretlen objektumosztály: " + cls);
			}
		}

		function layer(l:Dynamic):Void
		{
			if (l.visible == false)
				return;
			switch (l.type)
			{
				case "group":
					for (c in (l.layers : Array<Dynamic>))
						layer(c);
				case "tilelayer":
					if (!Std.isOfType(l.data, Array))
					{
						trace("LevelLoader: a csemperéteg nem CSV / tömb kódolású (Tiled: Tile Layer Format = CSV): " + l.name);
						ok = false;
						return;
					}
					var data:Array<Int> = l.data;
					var plat = l.name == "platforms";
					for (i in 0...data.length)
					{
						var g = data[i] & 0x0FFFFFFF;
						if (g == 0 || i >= d.solid.length)
							continue;
						if (plat)
							d.plats[i] = 4;
						else
							d.solid[i] = g >= 1 && g <= 3 ? g : 2;
					}
				case "objectgroup":
					for (o in (l.objects : Array<Dynamic>))
						object(o);
			}
		}

		for (l in (m.layers : Array<Dynamic>))
			layer(l);
		if (!ok)
			return null;
		for (id => r in rooms)
		{
			var a = outer.get(id);
			var b = inner.get(id);
			if (a == null || b == null)
			{
				trace("LevelLoader: a(z) " + id + ". épületnek hiányzik a külső vagy a belső ajtaja");
				continue;
			}
			d.buildings.push({sx: a.x, sy: a.y, ix: b.x, iy: b.y, x0: r.x, y0: r.y, w: r.w, h: r.h});
		}
		if (d.spawn == null || d.door == null)
			return err("hiányzik a Spawn vagy a Door objektum");
		// oszloponként a talaj teteje (csak a tesztekhez / eszközökhöz)
		for (x in 0...d.w)
		{
			var t = 99;
			for (y in 0...LevelData.H)
				if (d.solid[y * d.w + x] == 1)
				{
					t = y;
					break;
				}
			d.top.push(t);
		}
		return d;
	}
}
