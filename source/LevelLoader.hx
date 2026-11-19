package;

import LevelData.DoorDef;
import LevelData.PartSpawn;
import LevelData.Pt;
import haxe.Json;

/** A Tiled JSON (levels/levelN.tmj) beolvasása LevelData-vá (a formátum: LevelFormat, docs/LEVELS.md). Hibánál null: a játék a generátort használja. */
class LevelLoader
{
	/** A pálya betöltése: a beágyazott Tiled-térkép, ennek hiányában / hibájában a generátor. */
	public static function load(level:Int):LevelData
	{
		#if test
		// teszt: a pálya szövegének felülírása (window.__LevelLoader.testText[szint] = "...")
		if (testText.exists(level))
		{
			var t = parse(level, testText.get(level));
			if (t != null)
				return t;
		}
		#end
		var id = "assets/levels/level" + (level + 1) + ".tmj";
		if (openfl.utils.Assets.exists(id))
		{
			var d = parse(level, openfl.utils.Assets.getText(id));
			if (d != null)
				return d;
		}
		return LevelData.generate(level);
	}

	#if test
	public static var testText:Map<Int, String> = new Map();
	#end

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
		var roomWalls:Map<Int, {walls:Bool, clear:Bool}> = new Map();
		// ajtók: az egyedi azonosító (id), a célajtó (target) és a régi "room + inside" párosítás
		var rawDoors:Array<{pt:Pt, id:Int, target:Int, room:Int, inside:Bool}> = [];
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
					// a régi feliratok (VISOR, PROCESSOR) az új névre (GPU, CPU) képezve
					var ps:PartSpawn = {icon: Std.int(num(p.icon, 0)), label: p.label != null ? Parts.canonical(Std.string(p.label)) : "", x: x, y: y};
					if (p.friend != null && Std.int(p.friend) >= 0)
						ps.friend = Std.int(p.friend);
					// Tiled-ben kézzel letett / átnevezett alkatrész: ha az objektumnak nincs saját "icon" tulajdonsága (csak a csempe alapértéke),
					// a felirat (label) dönt: "VISOR" feliratú objektum VISOR-t ad, bármelyik alkatrész-csempéről is jött
					var explicitIcon = false;
					if (o.properties != null)
						for (q in (o.properties : Array<Dynamic>))
							if (q.name == "icon")
								explicitIcon = true;
					if (ps.friend == null && !explicitIcon)
					{
						var li = Parts.NAMES.indexOf(StringTools.trim(ps.label).toUpperCase());
						if (li >= 0)
							ps.icon = li;
					}
					d.parts.push(ps);
				case "Lamp":
					d.lamps.push({
						x: x + num(o.width, 8) / 2,
						y: y + num(o.height, 8) / 2,
						radius: Math.max(8, num(p.radius, 110)),
						intensity: num(p.intensity, 1.0),
						flicker: p.flicker != false,
						angle: num(p.angle, 90),
						spread: Math.max(5, Math.min(170, num(p.spread, 50)))
					});
				case "Text":
					var t:Dynamic = o.text;
					d.texts.push({x: x, y: y, text: t != null ? Std.string(t.text) : ""});
				case "BuildingRoom":
					roomWalls.set(id, {walls: p.walls != false, clear: p.clear != false});
					rooms.set(id, {
						x: Std.int(o.x / LevelData.T),
						y: Std.int(o.y / LevelData.T),
						w: Std.int(Math.round(num(o.width, 0) / LevelData.T)),
						h: Std.int(Math.round(num(o.height, 0) / LevelData.T))
					});
				case "BuildingDoor":
					rawDoors.push({
						pt: pt,
						id: Std.int(num(p.id, 0)),
						target: Std.int(num(p.target, 0)),
						room: Std.int(num(p.room, 0)),
						inside: p.inside == true
					});
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
		// az épületek falai: a BuildingRoom köré téglakeret kerül, a belseje kiürül (walls=false / clear=false: kézi fal / belső szerkezet)
		for (id => r in rooms)
		{
			var rw = roomWalls.get(id);
			for (y in r.y - 1...r.y + r.h + 1)
				for (x in r.x - 1...r.x + r.w + 1)
				{
					if (x < 0 || x >= d.w || y < 0 || y >= LevelData.H)
						continue;
					var edge = y == r.y - 1 || y == r.y + r.h || x == r.x - 1 || x == r.x + r.w;
					if (edge && rw.walls)
						d.solid[y * d.w + x] = 3;
					else if (!edge && rw.clear)
						d.solid[y * d.w + x] = 0;
				}
		}
		// ajtók: egyedi azonosító (üresen automatikus), a cél (target) vagy a régi páros (azonos room, másik inside)
		var nextAuto = 100000;
		for (rd in rawDoors)
			if (rd.id <= 0)
				rd.id = nextAuto++;
		for (rd in rawDoors)
		{
			var tgt = rd.target;
			if (tgt <= 0)
				for (o2 in rawDoors)
					if (o2 != rd && rd.room > 0 && o2.room == rd.room && o2.inside != rd.inside)
						tgt = o2.id;
			if (tgt <= 0)
			{
				trace("LevelLoader: " + 'a(z) ' + rd.id + '. ajtónak nincs célja (target) és párja sincs, kihagyva');
				continue;
			}
			d.doors.push({x: rd.pt.x, y: rd.pt.y, id: rd.id, target: tgt, inside: rd.pt.y > d.killRow * LevelData.T - 40});
		}
		for (dd in d.doors)
		{
			var ok2 = false;
			for (o2 in d.doors)
				if (o2.id == dd.target)
					ok2 = true;
			if (!ok2)
				trace("LevelLoader: " + 'a(z) ' + dd.id + '. ajtó célja (' + dd.target + ') nem létezik');
		}
		// a régi "buildings" lista (belső terem + külső / belső ajtó) a generátor-kompatibilitáshoz: a szobák téglalapjai
		for (id => r in rooms)
			d.buildings.push({sx: 0, sy: 0, ix: 0, iy: 0, x0: r.x, y0: r.y, w: r.w, h: r.h});
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
