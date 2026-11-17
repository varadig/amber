package;

#if (cheats && js)
import haxe.Json;
import haxe.crypto.Base64;
import haxe.io.Bytes;
import openfl.display.BitmapData;
import openfl.display.PNGEncoderOptions;
import openfl.geom.Point;
import openfl.geom.Rectangle;

/**
 * A generált pályák és a Tiled-erőforrások exportja (csak fejlesztői buildben, `?exportlevels=1`): levels/levelN.tmj, tiles.tsj, objects.tsj,
 * tiles.png, sprites/*.png (borostyán árnyalattal, hogy a Tiled-ben a játékhoz hasonlóan látszanak) és az amber.tiled-project.
 * A kimenet: `window.__levelFiles` (fájlnév -> szöveg, a .png-k base64-ben); a `scripts/generate-levels.ps1` ezt menti fájlba.
 * Figyelem: a generált pályák kiindulópontok; a kézzel szerkesztett .tmj-ket a script csak `-Force`-szal írja felül.
 */
class LevelExport
{
	static var nextId:Int = 1;

	static function png(bmd:BitmapData):String
	{
		var ba = bmd.encode(new Rectangle(0, 0, bmd.width, bmd.height), new PNGEncoderOptions());
		return Base64.encode(Bytes.ofData(ba));
	}

	/** Szürke-lépcsős sprite -> borostyán árnyalat (mint a játékban a shader). */
	static function tint(src:BitmapData, sx:Int, sy:Int, w:Int, h:Int):BitmapData
	{
		var out = new BitmapData(w, h, true, 0);
		for (y in 0...h)
			for (x in 0...w)
			{
				if (sx + x >= src.width || sy + y >= src.height)
					continue;
				var c = src.getPixel32(sx + x, sy + y);
				var a = c >>> 24;
				if (a == 0)
					continue;
				var l = (c >> 16) & 0xFF;
				out.setPixel32(x, y, (a << 24) | (Std.int(Math.min(255, l * 1.1)) << 16) | (Std.int(l * 0.66) << 8) | Std.int(l * 0.1));
			}
		return out;
	}

	/** A sprite képe és mérete: a (név) -> (bitmap, képkocka-szélesség, magasság, képkocka sorszáma). */
	static function art(name:String):{b:BitmapData, w:Int, h:Int, f:Int}
	{
		if (StringTools.startsWith(name, "part"))
			return {b: Art.partIcons(), w: 10, h: 10, f: Std.parseInt(name.substr(4))};
		return switch (name)
		{
			case "spawn": {b: Art.player(), w: 12, h: 14, f: 0};
			case "door": {b: Art.door(), w: 16, h: 24, f: 0};
			case "checkpoint": {b: Art.checkpoint(), w: 8, h: 16, f: 0};
			case "gem": {b: Art.gem(), w: 8, h: 8, f: 0};
			case "heart": {b: Art.heart(), w: 8, h: 8, f: 0};
			case "battery": {b: Art.battery(), w: 8, h: 10, f: 0};
			case "spikes": {b: Art.spikes(), w: 16, h: 8, f: 0};
			case "cracked": {b: Art.cracked(), w: 16, h: 16, f: 0};
			case "crumble": {b: Art.crumble(), w: 48, h: 10, f: 0};
			case "mover": {b: Art.mover(), w: 48, h: 8, f: 0};
			case "grate": {b: Art.grate(), w: 16, h: 16, f: 0};
			case "crate": {b: Art.crate(), w: 16, h: 16, f: 0};
			case "gate": {b: Art.gate(), w: 16, h: 16, f: 0};
			case "lockgate": {b: Art.lockGate(), w: 16, h: 16, f: 0};
			case "plate": {b: Art.plate(), w: 16, h: 6, f: 0};
			case "lever": {b: Art.lever(), w: 16, h: 10, f: 0};
			case "switch": {b: Art.switchPad(), w: 12, h: 14, f: 0};
			case "socket": {b: Art.socket(), w: 12, h: 12, f: 0};
			case "key": {b: Art.key(), w: 10, h: 8, f: 0};
			case "powercell": {b: Art.powerCell(), w: 8, h: 12, f: 0};
			case "bench": {b: Art.bench(), w: 24, h: 16, f: 0};
			case "terminal": {b: Art.terminal(), w: 16, h: 16, f: 1};
			case "bdoor": {b: Art.bdoor(), w: 16, h: 24, f: 0};
			case "walker": {b: Art.walker(), w: 14, h: 10, f: 0};
			case "flyer": {b: Art.flyer(), w: 14, h: 8, f: 0};
			case "crawler": {b: Art.crawler(), w: 14, h: 10, f: 0};
			case "cell": {b: Art.partIcons(), w: 10, h: 10, f: Parts.JET};
			default: {b: Art.gem(), w: 8, h: 8, f: 0};
		}
	}

	/** Objektum-literál kulcs-érték párokból (a "class" nem írható mezőnévként). */
	static function o(pairs:Array<Dynamic>):Dynamic
	{
		var r:Dynamic = {};
		var i = 0;
		while (i < pairs.length)
		{
			Reflect.setField(r, pairs[i], pairs[i + 1]);
			i += 2;
		}
		return r;
	}

	static function propType(v:Dynamic):String
		return Std.isOfType(v, Bool) ? "bool" : (Std.isOfType(v, Int) ? "int" : (Std.isOfType(v, Float) ? "float" : "string"));

	static function propList(def:Dynamic, over:Dynamic):Array<Dynamic>
	{
		var r:Dynamic = {};
		if (def != null)
			for (f in Reflect.fields(def))
				Reflect.setField(r, f, Reflect.field(def, f));
		if (over != null)
			for (f in Reflect.fields(over))
				Reflect.setField(r, f, Reflect.field(over, f));
		return [for (f in Reflect.fields(r)) o(["name", f, "type", propType(Reflect.field(r, f)), "value", Reflect.field(r, f)])];
	}

	static function tileSetJson():String
	{
		var tiles:Array<Dynamic> = [];
		var mw = 0, mh = 0;
		for (i in 0...LevelFormat.SPRITES.length)
		{
			var sd = LevelFormat.SPRITES[i];
			var a = art(sd.name);
			if (a.w > mw)
				mw = a.w;
			if (a.h > mh)
				mh = a.h;
			tiles.push(o([
				"id", i, "image", "sprites/" + sd.name + ".png", "imagewidth", a.w, "imageheight", a.h, "class", sd.cls, "properties", propList(sd.def, null)
			]));
		}
		return Json.stringify(o([
			"type", "tileset", "name", "objects", "version", "1.10", "tiledversion", "1.10.2", "tilewidth", mw, "tileheight", mh, "tilecount",
			tiles.length, "columns", 0, "margin", 0, "spacing", 0, "objectalignment", "bottomleft", "grid",
			o(["height", 1, "orientation", "orthogonal", "width", 1]), "tiles", tiles
		]), null, "\t");
	}

	static function tilesTsj():String
		return Json.stringify(o([
			"type", "tileset", "name", "terrain", "version", "1.10", "tiledversion", "1.10.2", "tilewidth", 16, "tileheight", 16, "tilecount", 4, "columns", 4,
			"image", "tiles.png", "imagewidth", 64, "imageheight", 16, "margin", 0, "spacing", 0,
			"tiles", [
				o(["id", 0, "properties", [o(["name", "kind", "type", "string", "value", "GROUND TOP"])]]),
				o(["id", 1, "properties", [o(["name", "kind", "type", "string", "value", "GROUND"])]]),
				o(["id", 2, "properties", [o(["name", "kind", "type", "string", "value", "BRICK"])]]),
				o(["id", 3, "properties", [o(["name", "kind", "type", "string", "value", "ONE-WAY PLATFORM"])]])
			]
		]), null, "\t");

	static function projectJson():String
	{
		var types:Array<Dynamic> = [
			o(["id", 1, "name", "EnemyKind", "storageType", "string", "type", "enum", "values", LevelFormat.ENEMY_KINDS, "valuesAsFlags", false])
		];
		var seen:Map<String, Bool> = new Map();
		var nid = 2;
		function cls(name:String, color:String, members:Array<Dynamic>, ?fill:Bool = true):Void
		{
			if (seen.exists(name))
				return;
			seen.set(name, true);
			types.push(o(["id", nid++, "name", name, "type", "class", "color", color, "drawFill", fill, "members", members, "useAs", ["object", "tile"]]));
		}
		var colors = [
			"Enemy" => "#ffd04040", "Part" => "#fff0b030", "Gem" => "#ff40c0c0", "Heart" => "#ffe05080", "Terminal" => "#ff40a0f0", "Gate" => "#ff909090",
			"Spawn" => "#ff40f040", "Door" => "#ff40f040"
		];
		for (sd in LevelFormat.SPRITES)
		{
			var members:Array<Dynamic> = [];
			if (sd.def != null)
				for (f in Reflect.fields(sd.def))
				{
					var v = Reflect.field(sd.def, f);
					var m = o(["name", f, "type", propType(v), "value", v]);
					if (sd.cls == "Enemy" && f == "kind")
						m = o(["name", f, "type", "string", "propertyType", "EnemyKind", "value", v]);
					members.push(m);
				}
			cls(sd.cls, colors.exists(sd.cls) ? colors.get(sd.cls) : "#ffc08020", members);
		}
		cls("BuildingRoom", "#ff8060c0", [o(["name", "id", "type", "int", "value", 1])]);
		cls("Decor", "#ff505050", []);
		cls("Text", "#ffffffff", [], false);
		return Json.stringify(o([
			"automappingRulesFile", "", "commands", [], "compatibilityVersion", 1100, "extensionsPath", "extensions", "folders", ["."], "properties", [],
			"propertyTypes", types
		]), null, "    ");
	}

	static function mapJson(d:LevelData):String
	{
		nextId = 1;
		var T = LevelData.T;
		var groups:Map<String, Array<Dynamic>> = [
			"markers" => [], "items" => [], "enemies" => [], "hazards" => [], "puzzle" => [], "buildings" => []
		];
		function tile(cat:String, sprite:String, x:Float, y:Float, ?props:Dynamic, ?w:Float):Void
		{
			var idx = LevelFormat.spriteIndex(sprite);
			var sd = LevelFormat.SPRITES[idx];
			var a = art(sprite);
			var ow = w != null ? w : a.w;
			groups.get(cat).push(o([
				"id", nextId++, "name", "", "class", sd.cls, "x", x, "y", y + a.h, "width", ow, "height", a.h, "gid", LevelFormat.OBJ_FIRST + idx, "rotation", 0,
				"visible", true, "properties", propList(sd.def, props)
			]));
		}
		function rect(cat:String, cls:String, x:Float, y:Float, w:Float, h:Float, ?props:Dynamic):Void
			groups.get(cat).push(o([
				"id", nextId++, "name", "", "class", cls, "x", x, "y", y, "width", w, "height", h, "rotation", 0, "visible", true, "properties",
				propList(null, props)
			]));

		tile("markers", "spawn", d.spawn.x, d.spawn.y);
		tile("markers", "door", d.door.x, d.door.y);
		for (p in d.checkpoints)
			tile("markers", "checkpoint", p.x, p.y);
		for (t in d.texts)
			groups.get("markers").push(o([
				"id", nextId++, "name", "", "class", "Text", "x", t.x, "y", t.y, "width", 140, "height", 16, "rotation", 0, "visible", true, "text",
				o(["text", t.text, "wrap", true, "pixelsize", 8, "color", "#ffc08020"])
			]));
		for (p in d.gems)
			tile("items", "gem", p.x, p.y);
		for (p in d.hearts)
			tile("items", "heart", p.x, p.y);
		for (p in d.batteries)
			tile("items", "battery", p.x, p.y);
		for (p in d.cells)
			tile("items", "cell", p.x, p.y);
		for (p in d.parts)
			tile("items", "part" + (p.icon >= 0 && p.icon < LevelFormat.PART_FRAMES ? p.icon : 0), p.x, p.y, {icon: p.icon, label: p.label, friend: p.friend != null ? p.friend : -1});
		for (p in d.keys)
			tile("items", "key", p.x, p.y, {id: p.id});
		for (p in d.powerCells)
			tile("items", "powercell", p.x, p.y, {id: p.id});
		for (e in d.enemies)
			tile("enemies", ["walker", "flyer", "crawler"][e.kind], e.x, e.y);
		for (p in d.spikes)
			tile("hazards", "spikes", p.x, p.y);
		for (p in d.crackeds)
			tile("hazards", "cracked", p.x, p.y);
		for (p in d.crumbles)
			tile("hazards", "crumble", p.x, p.y);
		for (m in d.movers)
			tile("hazards", "mover", m.x, m.y, {w: m.w, axis: m.axis, range: m.range, speed: m.speed, id: m.id != null ? m.id : -1, active: m.active != false}, m.w * T);
		for (g in d.gates)
			tile("puzzle", g.lock ? "lockgate" : "gate", g.x, g.y, {id: g.id, lock: g.lock});
		for (p in d.plates)
			tile("puzzle", "plate", p.x, p.y, {id: p.id, hold: p.hold});
		for (p in d.levers)
			tile("puzzle", "lever", p.x, p.y, {id: p.id});
		for (s in d.switches)
			tile("puzzle", "switch", s.x, s.y, {id: s.id, idx: s.idx, label: s.label});
		for (p in d.sockets)
			tile("puzzle", "socket", p.x, p.y, {id: p.id});
		for (p in d.crates)
			tile("puzzle", "crate", p.x, p.y);
		for (p in d.grates)
			tile("puzzle", "grate", p.x, p.y);
		for (b in d.benches)
			tile("puzzle", "bench", b.x, b.y, {comp: b.comp});
		for (t in d.terminals)
			tile("puzzle", "terminal", t.x, t.y, {id: t.id, game: t.game});
		for (i in 0...d.buildings.length)
		{
			var b = d.buildings[i];
			rect("buildings", "BuildingRoom", b.x0 * T, b.y0 * T, b.w * T, b.h * T, {id: i + 1});
			tile("buildings", "bdoor", b.sx, b.sy, {room: i + 1, inside: false});
			tile("buildings", "bdoor", b.ix, b.iy, {room: i + 1, inside: true});
		}
		for (c in d.decor)
			rect("buildings", "Decor", c.x * T, c.y * T, c.w * T, c.h * T);

		var layers:Array<Dynamic> = [];
		var lid = 1;
		function tileLayer(name:String, f:Int->Int):Void
			layers.push(o([
				"id", lid++, "name", name, "type", "tilelayer", "x", 0, "y", 0, "width", d.w, "height", LevelData.H, "opacity", 1, "visible", true, "data",
				[for (i in 0...(d.w * LevelData.H)) f(i)]
			]));
		tileLayer("solid", i -> d.solid[i]);
		tileLayer("platforms", i -> d.plats[i] != 0 ? 4 : 0);
		for (cat in ["buildings", "hazards", "puzzle", "items", "enemies", "markers"])
			layers.push(o([
				"id", lid++, "name", cat, "type", "objectgroup", "x", 0, "y", 0, "opacity", 1, "visible", true, "draworder", "topdown", "objects", groups.get(cat)
			]));

		var props:Array<Dynamic> = [
			o(["name", "name", "type", "string", "value", d.name]),
			o(["name", "killRow", "type", "int", "value", d.killRow])
		];
		for (id => seq in d.seqs)
			props.push(o(["name", "seq" + id, "type", "string", "value", seq.join(",")]));
		return Json.stringify(o([
			"type", "map", "version", "1.10", "tiledversion", "1.10.2", "orientation", "orthogonal", "renderorder", "right-down", "width", d.w, "height",
			LevelData.H, "tilewidth", T, "tileheight", T, "infinite", false, "compressionlevel", -1, "nextlayerid", lid, "nextobjectid", nextId, "properties",
			props, "tilesets", [o(["firstgid", 1, "source", "tiles.tsj"]), o(["firstgid", LevelFormat.OBJ_FIRST, "source", "objects.tsj"])], "layers", layers
		]));
	}

	/** Összehasonlítás: a Tiled-JSON visszaolvasása ugyanazt adja-e, mint a generátor (a körút ellenőrzése). */
	static function parity(d:LevelData, json:String):String
	{
		var b = LevelLoader.parse(d.level, json);
		if (b == null)
			return "LOAD FAILED";
		var diffs:Array<String> = [];
		function cmp(n:String, x:Int, y:Int):Void
		{
			if (x != y)
				diffs.push(n + " " + x + "!=" + y);
		}
		cmp("w", d.w, b.w);
		cmp("killRow", d.killRow, b.killRow);
		var sd = 0;
		for (i in 0...d.solid.length)
			if (d.solid[i] != b.solid[i] || (d.plats[i] != 0) != (b.plats[i] != 0))
				sd++;
		cmp("tilediff", 0, sd);
		cmp("gems", d.gems.length, b.gems.length);
		cmp("hearts", d.hearts.length, b.hearts.length);
		cmp("enemies", d.enemies.length, b.enemies.length);
		cmp("spikes", d.spikes.length, b.spikes.length);
		cmp("parts", d.parts.length, b.parts.length);
		cmp("cells", d.cells.length, b.cells.length);
		cmp("gates", d.gates.length, b.gates.length);
		cmp("plates", d.plates.length, b.plates.length);
		cmp("levers", d.levers.length, b.levers.length);
		cmp("switches", d.switches.length, b.switches.length);
		cmp("keys", d.keys.length, b.keys.length);
		cmp("sockets", d.sockets.length, b.sockets.length);
		cmp("powerCells", d.powerCells.length, b.powerCells.length);
		cmp("crates", d.crates.length, b.crates.length);
		cmp("grates", d.grates.length, b.grates.length);
		cmp("benches", d.benches.length, b.benches.length);
		cmp("terminals", d.terminals.length, b.terminals.length);
		cmp("texts", d.texts.length, b.texts.length);
		cmp("crumbles", d.crumbles.length, b.crumbles.length);
		cmp("movers", d.movers.length, b.movers.length);
		cmp("batteries", d.batteries.length, b.batteries.length);
		cmp("buildings", d.buildings.length, b.buildings.length);
		cmp("decor", d.decor.length, b.decor.length);
		cmp("checkpoints", d.checkpoints.length, b.checkpoints.length);
		cmp("crackeds", d.crackeds.length, b.crackeds.length);
		cmp("seqs", Lambda.count({iterator: () -> d.seqs.keys()}), Lambda.count({iterator: () -> b.seqs.keys()}));
		if (d.spawn.x != b.spawn.x || d.spawn.y != b.spawn.y)
			diffs.push("spawn");
		if (d.door.x != b.door.x || d.door.y != b.door.y)
			diffs.push("door");
		for (i in 0...d.parts.length)
			if (b.parts[i] != null && (d.parts[i].x != b.parts[i].x || d.parts[i].y != b.parts[i].y || d.parts[i].icon != b.parts[i].icon))
				diffs.push("part" + i);
		return diffs.length == 0 ? "OK" : diffs.join(", ");
	}

	public static function run():Void
	{
		var files:Dynamic = {};
		var report:Array<String> = [];
		for (lv in 0...LevelData.COUNT)
		{
			var d = LevelData.generate(lv);
			var json = mapJson(d);
			Reflect.setField(files, "level" + (lv + 1) + ".tmj", json);
			report.push("level" + (lv + 1) + ": " + parity(d, json));
		}
		Reflect.setField(files, "tiles.tsj", tilesTsj());
		Reflect.setField(files, "objects.tsj", tileSetJson());
		Reflect.setField(files, "amber.tiled-project", projectJson());
		var t = Art.tiles();
		Reflect.setField(files, "tiles.png", png(tint(t, 16, 0, 64, 16)));
		for (sd in LevelFormat.SPRITES)
		{
			var a = art(sd.name);
			Reflect.setField(files, "sprites/" + sd.name + ".png", png(tint(a.b, a.f * a.w, 0, a.w, a.h)));
		}
		js.Syntax.code("window.__levelFiles = {0}; window.__levelParity = {1}", files, report.join("\n"));
	}
}
#end
