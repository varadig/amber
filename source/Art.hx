package;

import openfl.display.BitmapData;

/**
 * Kódból generált pixel art (nincsenek képfájlok). A paletta a C64 szürke-lépcsői: a borostyán-shader ezeket színezi át.
 * Karakterek: '.' átlátszó, '0' fekete, '1' sötétszürke, '2' szürke, '3' világosszürke, '4' fehér.
 */
class Art
{
	static var cache:Map<String, BitmapData> = new Map();

	static inline function color(ch:String):Int
	{
		return switch (ch)
		{
			case "0": 0xFF000000;
			case "1": 0xFF444444;
			case "2": 0xFF777777;
			case "3": 0xFFBBBBBB;
			case "4": 0xFFFFFFFF;
			case "5": 0xFF202020;
			case "6": 0xFF303030;
			default: 0x00000000;
		}
	}

	/** Képkockák (azonos méretű sorlisták) egymás mellé, egy sávba; a sorok a legelső sor szélességére igazodnak. */
	public static function strip(frames:Array<Array<String>>):BitmapData
	{
		var w = frames[0][0].length;
		var h = frames[0].length;
		var bd = new BitmapData(w * frames.length, h, true, 0x00000000);
		for (f in 0...frames.length)
			for (y in 0...h)
			{
				var row = y < frames[f].length ? frames[f][y] : "";
				for (x in 0...w)
				{
					var c = color(x < row.length ? row.charAt(x) : ".");
					if (c != 0)
						bd.setPixel32(f * w + x, y, c);
				}
			}
		return bd;
	}

	static function cached(key:String, make:Void->BitmapData):BitmapData
	{
		var b = cache.get(key);
		if (b == null)
		{
			b = make();
			cache.set(key, b);
		}
		// másolatot adunk: a Flixel állapotváltáskor felszabadítja (dispose) a használaton kívüli grafikákat, a mester példány így érintetlen marad
		return b.clone();
	}

	// --- Hős: 12x14, képkockák: 0 állás, 1-4 futás, 5 ugrás, 6 esés, 7 fal, 8 szökellés (dash), 9 sérülés ---
	/** A robot törzse: antenna, szögletes fej (keret + látómező), nyak, vállak, szegecselt törzs mellkas-ablakkal (a CORE fénye), öv. */
	static final BODY = [
		".....44.....",
		"..33333333..",
		"..32222223..",
		"..30400403..",
		"..32222223..",
		"..33333333..",
		".2233333322.",
		".2232442322.",
		".2232332322.",
		"..22222222.."
	];

	/**
	 * A hős: 12x14, képkockák: 0 állás, 1-4 futás, 5 ugrás, 6 esés, 7 fal-kapaszkodás, 8 szökellés (dash), 9 sérülés.
	 * `mask`: a birtokolt alkatrészek bitmaszkja (Parts.mask()). Csupaszon (mask = 0) vak (nincs szem-fény), nincs mag-fény, csak csonk-lábai vannak;
	 * az alkatrészek láthatóan rákerülnek: szem (VISOR), mellkas-fény (CORE), lábak (LEGS), hátsó fúvóka (THRUSTER), karmok (CLAWS), kar-ágyú (BLASTER).
	 */
	public static function player(mask:Int = 0):BitmapData
	{
		return cached("player" + mask, () ->
		{
			function has(id:Int):Bool
				return (mask & (1 << id)) != 0;
			var stand = ["...22..22...", "...32..23...", "...22..22...", "..333..333.."];
			var runA = ["..22....22..", "..32....23..", "...22..22...", "..333..333.."];
			var runB = ["...22..22...", "...32..23...", "...22..22...", "...33..33..."];
			var runC = ["...22..22...", "..32....23..", "..22....22..", ".333....333."];
			var jump = ["..32....23..", "...33..33...", "............", "............"];
			var fall = ["..32....23..", "..22....22..", "..22....22..", "..33....33.."];
			var stub = ["............", "............", "...22..22...", "...22..22..."];
			var legs = [stand, runA, runB, runC, runB, jump, fall, stand, runA, fall, stand];
			if (!has(Parts.LEGS))
				legs = [for (_ in legs) stub];
			var frames:Array<Array<String>> = [];
			for (i in 0...legs.length)
			{
				var body = BODY.copy();
				if (!has(Parts.VISOR))
					body[3] = "..30000003..";
				else if (i == 9)
					body[3] = "..34044043..";
				if (!has(Parts.CORE))
				{
					body[7] = ".2232222322.";
					body[8] = ".2232222322.";
				}
				if (i == 10)
				{
					// kikapcsolt (lemerült akku): sötét szem, lekonyuló antenna, kialudt mag
					body[0] = "............";
					body[3] = "..30000003..";
					body[7] = ".2232222322.";
					body[8] = ".2232222322.";
				}
				var rows = body.concat(legs[i]);
				function setc(r:Int, c:Int, ch:String):Void
				{
					var s = rows[r];
					rows[r] = s.substr(0, c) + ch + s.substr(c + 1);
				}
				if (has(Parts.THRUSTER))
				{
					setc(7, 0, "3");
					setc(7, 1, "3");
					setc(8, 0, "4");
					setc(8, 1, "3");
				}
				if (has(Parts.CLAWS))
				{
					setc(6, 11, "3");
					setc(7, 10, "3");
					setc(7, 11, "3");
					setc(8, 10, "3");
				}
				if (has(Parts.BLASTER))
				{
					setc(8, 10, "4");
					setc(8, 11, "4");
					setc(7, 11, "4");
				}
				if (i == 7)
				{
					// kapaszkodás: a fal felőli (jobb) kar felnyúl és markol, a test a falhoz simul
					setc(1, 10, "4");
					setc(1, 11, "4");
					setc(2, 11, "3");
					setc(3, 11, "3");
					setc(4, 11, "3");
					setc(5, 10, "3");
					setc(5, 11, "3");
					setc(6, 10, "3");
					setc(12, 9, "2");
				}
				frames.push(rows);
			}
			return strip(frames);
		});
	}

	/** Akkupakk 8x10, 2 kép (töltés-villanás). */
	public static function battery():BitmapData
	{
		return cached("battery", () ->
		{
			var a = ["..4444..", ".433334.", ".432234.", ".432234.", ".433334.", ".432234.", ".432234.", ".433334.", ".444444.", "........"];
			var b = ["..4444..", ".433334.", ".434434.", ".434434.", ".433334.", ".434434.", ".434434.", ".433334.", ".444444.", "........"];
			return strip([a, b]);
		});
	}

	/** Alkatrész-ikonok 10x10: LEGS, CORE, VISOR, THRUSTER, CLAWS, BLASTER, CHIP, GEAR, ANTENNA, JET CELL. */
	public static function partIcons():BitmapData
	{
		return cached("partIcons", () -> strip([
			["..444444..", "..4....4..", "...4444...", "..4....4..", "...4444...", "..4....4..", "...4444...", "..444444..", "..4....4..", ".44....44."],
			["...4444...", "..433334..", ".43444434.", ".43422434.", ".43422434.", ".43444434.", "..433334..", "...4444...", "..........", ".........."],
			["..........", "..444444..", ".43333334.", "4332442334", "4332442334", ".43333334.", "..444444..", "..........", "..........", ".........."],
			["..444444..", "..433334..", "...4334...", "...4334...", "..433334..", "..444444..", "...3333...", "....33....", "....3.....", ".........."],
			["4444......", "4..44.....", "4....44...", ".....44...", "....44....", "...44.....", "..44......", "..4.......", ".44.......", ".4........"],
			["..........", "..........", ".44444444.", "4333333344", ".4444433..", "....4334..", "....4334..", "....444...", "..........", ".........."],
			["..4.4.4.4.", ".44444444.", "4433333344", ".43444434.", "4433333344", ".43444434.", "4433333344", ".44444444.", "..4.4.4.4.", ".........."],
			["...4444...", ".44.44.44.", "..444444..", "4443333444", "4443443444", "4443333444", "..444444..", ".44.44.44.", "...4444...", ".........."],
			["....4.....", "...4.4....", "..4...4...", "....4.....", "....4.....", "....4.....", "...444....", "..43334...", "..44444...", ".........."],
			["...4444...", "..433334..", "..433334..", "..434434..", "..433334..", "..433334..", "...4444...", "...3333...", "....33....", "....3....."]
		]));
	}

	/** Repedezett blokk 16x16 (blaszterrel kilőhető). */
	public static function cracked():BitmapData
	{
		return cached("cracked", () ->
		{
			var rows:Array<String> = [];
			for (y in 0...16)
			{
				var r = "";
				for (x in 0...16)
				{
					var ch = "2";
					if (x == 0 || y == 0)
						ch = "3";
					else if (x == 15 || y == 15)
						ch = "1";
					else if ((x == y + 1 && y > 2 && y < 12) || (x == 15 - y && y > 4) || (y == 8 && x > 5 && x < 11))
						ch = "0";
					r += ch;
				}
				rows.push(r);
			}
			return strip([rows]);
		});
	}

	/** Kapu-elem 16x16 (rács). */
	public static function gate():BitmapData
	{
		return cached("gate", () ->
		{
			var rows:Array<String> = [];
			for (y in 0...16)
			{
				var r = "";
				for (x in 0...16)
					r += y == 0 ? "4" : ((x % 4) >= 2 ? "3" : "0");
				rows.push(r);
			}
			return strip([rows]);
		});
	}

	/** Nyomólap 16x6: 0 felemelve, 1 lenyomva. */
	public static function plate():BitmapData
	{
		return cached("plate", () ->
		{
			function make(down:Bool):Array<String>
			{
				var rows:Array<String> = [];
				for (y in 0...6)
				{
					var r = "";
					for (x in 0...16)
					{
						var top = down ? 3 : 0;
						var ch = ".";
						if (y >= top)
						{
							var k = y - top;
							ch = k == 0 ? (x >= 2 && x <= 13 ? "4" : ".") : (k == 1 ? (x >= 1 && x <= 14 ? "3" : ".") : "2");
						}
						r += ch;
					}
					rows.push(r);
				}
				return rows;
			}
			return strip([make(false), make(true)]);
		});
	}

	/** Leszakadó platform 48x10 (repedezett). */
	public static function crumble():BitmapData
	{
		return cached("crumble", () ->
		{
			var rows:Array<String> = [];
			for (y in 0...10)
			{
				var r = "";
				for (x in 0...48)
				{
					var ch = y == 0 ? "4" : (y == 1 ? "3" : (y < 8 ? "2" : "1"));
					if (y >= 2 && y < 8 && ((x + y * 5) % 11 == 0 || (x % 16 == 8 && y % 2 == 0)))
						ch = "0";
					r += ch;
				}
				rows.push(r);
			}
			return strip([rows]);
		});
	}

	/** Mozgó platform 48x8 (fényjelzőkkel). */
	public static function mover():BitmapData
	{
		return cached("mover", () ->
		{
			var rows:Array<String> = [];
			for (y in 0...8)
			{
				var r = "";
				for (x in 0...48)
				{
					var ch = y == 0 ? "4" : (y < 2 ? "3" : (y < 7 ? "2" : "1"));
					if (y >= 2 && y < 6 && (x % 8 == 3 || x % 8 == 4) && y % 2 == 0)
						ch = "4";
					if (x < 2 || x > 45)
						ch = y < 7 ? "3" : "1";
					r += ch;
				}
				rows.push(r);
			}
			return strip([rows]);
		});
	}

	// --- Ellenségek ---
	public static function walker():BitmapData
	{
		return cached("walker", () ->
		{
			var a = [
				"....333333....",
				"..3333333333..",
				".333333333333.",
				".330433330433.",
				".333333333333.",
				"33333333333333",
				"33333333333333",
				".222222222222.",
				"..2222222222..",
				"..22......22.."
			];
			var b = a.copy();
			b[9] = "...22....22...";
			var dead = [
				"..............",
				"..............",
				"..............",
				"..............",
				"..............",
				"..............",
				"..............",
				"..333333333333",
				".330333333033.",
				"22222222222222"
			];
			return strip([a, b, dead]);
		});
	}

	public static function flyer():BitmapData
	{
		return cached("flyer", () ->
		{
			var a = [
				"33..........33",
				".333.3333.333.",
				"..3334444333..",
				"....304403....",
				".....3333.....",
				"......33......",
				"..............",
				".............."
			];
			var b = [
				"..............",
				"..............",
				"..3334444333..",
				".33.304403.33.",
				"33..333333..33",
				"3....3333....3",
				"......33......",
				".............."
			];
			return strip([a, b]);
		});
	}

	public static function crawler():BitmapData
	{
		return cached("crawler", () ->
		{
			var a = [
				"..4..4..4..4..",
				"..3..3..3..3..",
				".333333333333.",
				"33333333333333",
				"33304333330433",
				"33333333333333",
				".222222222222.",
				"..2222222222..",
				"..22......22..",
				".............."
			];
			var b = a.copy();
			b[8] = "...22....22...";
			return strip([a, b]);
		});
	}

	// --- Tárgyak ---
	public static function gem():BitmapData
	{
		return cached("gem", () ->
		{
			var a = ["...44...", "..4334..", ".433334.", "43333334", ".433334.", "..4334..", "...44...", "........"];
			var b = ["...44...", "..4334..", ".434434.", "43344334", ".434434.", "..4334..", "...44...", "........"];
			return strip([a, a, b, a]);
		});
	}

	public static function key():BitmapData
	{
		return cached("key", () ->
		{
			var a = [".444......", "4...4.....", "4...444444", "4...4.4.4.", ".444......", "..........", "..........", ".........."];
			return strip([a]);
		});
	}

	public static function heart():BitmapData
	{
		return cached("heart", () -> strip([[".33..33.", "33333333", "33333333", ".333333.", "..3333..", "...33...", "........", "........"]]));
	}

	public static function heartEmpty():BitmapData
	{
		return cached("heartEmpty", () -> strip([[".11..11.", "1..11..1", "1......1", ".1....1.", "..1..1..", "...11...", "........", "........"]]));
	}

	public static function spikes():BitmapData
	{
		return cached("spikes", () ->
		{
			var rows:Array<String> = [];
			for (r in 0...8)
			{
				var line = "";
				for (s in 0...4)
					line += r < 2 ? ".44." : (r < 4 ? "3333" : "2222");
				rows.push(line);
			}
			return strip([rows]);
		});
	}

	public static function checkpoint():BitmapData
	{
		return cached("checkpoint", () ->
		{
			function flag(c:String):Array<String>
			{
				var rows:Array<String> = [];
				for (y in 0...16)
				{
					var r = "";
					for (x in 0...8)
					{
						var ch = ".";
						if (x == 1)
							ch = "3";
						else if (y >= 1 && y <= 5 && x >= 2 && x <= 7 - (y > 3 ? y - 3 : 0))
							ch = c;
						else if (y == 15 && x >= 0 && x <= 3)
							ch = "2";
						r += ch;
					}
					rows.push(r);
				}
				return rows;
			}
			return strip([flag("1"), flag("4")]);
		});
	}

	/** Ajtó 16x24: 0 zárt (kőív), 1 nyitva (fekete kapu, kavargó pontokkal), 2 nyitva (másik fázis). */
	public static function door():BitmapData
	{
		return cached("door", () ->
		{
			function make(open:Int):Array<String>
			{
				var rows:Array<String> = [];
				for (y in 0...24)
				{
					var r = "";
					for (x in 0...16)
					{
						var edge = x < 2 || x > 13 || y < 2;
						var arch = y < 6 && ((x - 7.5) * (x - 7.5) + (y - 6) * (y - 6) > 56);
						var ch = "2";
						if (arch)
							ch = ".";
						else if (edge)
							ch = "3";
						else if (open == 0)
							ch = (x == 7 || x == 8) && y > 10 && y < 15 ? "0" : "1";
						else
						{
							ch = "0";
							var ph = open == 1 ? 0 : 3;
							if ((x * 3 + y * 5 + ph) % 7 == 0)
								ch = "4";
							else if ((x * 5 + y * 3 + ph) % 11 == 0)
								ch = "2";
						}
						r += ch;
					}
					rows.push(r);
				}
				return rows;
			}
			return strip([make(0), make(1), make(2)]);
		});
	}

	// --- Csempék: 0 üres, 1 talaj teteje, 2 talaj, 3 tégla, 4 egyirányú platform ---
	public static function tiles():BitmapData
	{
		return cached("tiles", () ->
		{
			var bd = new BitmapData(16 * 5, 16, true, 0x00000000);
			function px(t:Int, x:Int, y:Int, ch:String)
				bd.setPixel32(t * 16 + x, y, color(ch));
			var seed = 12345;
			function rnd():Int
			{
				seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF;
				return seed >> 8;
			}
			for (y in 0...16)
				for (x in 0...16)
				{
					// 1: talaj teteje (fényes él + szemcsés)
					var top = y == 0 ? "4" : (y == 1 ? "3" : (y == 2 ? "2" : "1"));
					if (y > 2 && rnd() % 16 == 0)
						top = "2";
					px(1, x, y, top);
					// 2: talaj
					var fill = "1";
					var r = rnd() % 26;
					if (r == 0)
						fill = "2";
					else if (r == 1)
						fill = "0";
					px(2, x, y, fill);
					// 3: tégla
					var brick = (y % 8 == 7 || (x + (y / 8 >= 1 ? 8 : 0)) % 16 == 15) ? "0" : (y % 8 == 0 ? "3" : "2");
					px(3, x, y, brick);
					// 4: egyirányú platform (vékony deszka)
					if (y < 4)
						px(4, x, y, y == 0 ? "4" : (y == 1 ? "3" : (y == 2 ? "2" : "1")));
				}
			return bd;
		});
	}

	/** Épület-homlokzat (px): sötétszürke fal, tető-perem, világító ablakok. */
	public static function facade(w:Int, h:Int):BitmapData
	{
		var bd = new BitmapData(w, h, true, 0x00000000);
		bd.fillRect(new openfl.geom.Rectangle(0, 0, w, h), 0xFF2A2A2A);
		bd.fillRect(new openfl.geom.Rectangle(0, 0, w, 4), 0xFF555555);
		bd.fillRect(new openfl.geom.Rectangle(0, 4, w, 2), 0xFF3A3A3A);
		bd.fillRect(new openfl.geom.Rectangle(0, 0, 2, h), 0xFF444444);
		bd.fillRect(new openfl.geom.Rectangle(w - 2, 0, 2, h), 0xFF1A1A1A);
		var seed = w * 31 + h;
		var x = 10;
		while (x + 10 < w - 6)
		{
			var y = 14;
			while (y + 12 < h - 6)
			{
				seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF;
				var lit = ((seed >> 8) % 3) != 0;
				bd.fillRect(new openfl.geom.Rectangle(x, y, 10, 12), lit ? 0xFF777777 : 0xFF111111);
				bd.fillRect(new openfl.geom.Rectangle(x, y, 10, 2), 0xFF444444);
				y += 24;
			}
			x += 20;
		}
		return bd;
	}

	/** A belső terem falpapírja (px): sötét, finom rácsos. */
	public static function wallpaper(w:Int, h:Int):BitmapData
	{
		var bd = new BitmapData(w, h, true, 0xFF161616);
		var x = 0;
		while (x < w)
		{
			bd.fillRect(new openfl.geom.Rectangle(x, 0, 1, h), 0xFF222222);
			x += 16;
		}
		var y = 0;
		while (y < h)
		{
			bd.fillRect(new openfl.geom.Rectangle(0, y, w, 1), 0xFF222222);
			y += 16;
		}
		var lx = 40;
		while (lx < w - 20)
		{
			// mennyezeti lámpák
			bd.fillRect(new openfl.geom.Rectangle(lx, 0, 2, 8), 0xFF444444);
			bd.fillRect(new openfl.geom.Rectangle(lx - 4, 8, 10, 4), 0xFF999999);
			lx += 90;
		}
		return bd;
	}

	/** Épület-ajtó 16x24 (barna-szürke, kilincs). */
	public static function bdoor():BitmapData
	{
		return cached("bdoor", () ->
		{
			var rows:Array<String> = [];
			for (y in 0...24)
			{
				var r = "";
				for (x in 0...16)
				{
					var ch = "2";
					if (x < 2 || x > 13 || y < 2)
						ch = "3";
					else if (x == 11 && y > 11 && y < 15)
						ch = "4";
					else if ((x == 4 || x == 5 || x == 9 || x == 10) && y > 4 && y < 20)
						ch = "1";
					r += ch;
				}
				rows.push(r);
			}
			return strip([rows]);
		});
	}

	/** Háttér-sziluett (távoli romok, csillagpontok): `w` x 340, a paralaxishoz. */
	public static function backdrop(w:Int, seed0:Int, tone:String, density:Int):BitmapData
	{
		var bd = new BitmapData(w, 340, true, 0x00000000);
		var seed = seed0;
		function rnd():Int
		{
			seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF;
			return seed >> 8;
		}
		var x = 0;
		while (x < w)
		{
			var pw = 8 + rnd() % 22;
			var ph = 90 + rnd() % 140;
			var broken = rnd() % 3 == 0 ? rnd() % 20 : 0;
			for (px in x...Std.int(Math.min(w, x + pw)))
				for (py in 340 - ph + broken...340)
					bd.setPixel32(px, py, color(tone));
			// ablakok / rések
			if (pw > 12)
				for (wy in 0...Std.int(ph / 16))
					if (rnd() % 3 != 0)
						bd.fillRect(new openfl.geom.Rectangle(x + 3, 340 - ph + broken + 8 + wy * 16, 3, 5), 0xFF000000);
			x += pw + rnd() % density;
		}
		return bd;
	}

	/** Csillagpontok (halvány) a legtávolabbi rétegre. */
	public static function stars(w:Int, seed0:Int):BitmapData
	{
		var bd = new BitmapData(w, 340, true, 0x00000000);
		var seed = seed0;
		for (i in 0...Std.int(w / 9))
		{
			seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF;
			var x = (seed >> 8) % w;
			seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF;
			var y = (seed >> 8) % 170;
			bd.setPixel32(x, y, (i % 5 == 0) ? 0xFF777777 : 0xFF444444);
		}
		return bd;
	}
}
