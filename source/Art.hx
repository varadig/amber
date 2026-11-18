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
		"..34422443..",
		"..34022043..",
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
			// Futás: 6 képkocka, két "lépés" tükrözve. Robotos hatás: dugattyú-combok, világos térdízület, lapos talp;
			// a földet érő (lent) képkockákon a törzs 1 px-szel lejjebb ül (bob: 3 soros láb), a lendítő képkockán fent van.
			var contact = ["..22....22..", ".42.....24..", "33......333."];
			var passing = ["...22..22...", "...22..42...", "...32...33..", "..333......."];
			var reach = ["..22....22..", "..32....24..", ".32.....33..", ".3.........."];
			function mirror(a:Array<String>):Array<String>
				return [for (s in a) [for (k in 0...s.length) s.charAt(s.length - 1 - k)].join("")];
			var jump = ["..32....23..", "...33..33...", "............", "............"];
			var fall = ["..32....23..", "..22....22..", "..22....22..", "..33....33.."];
			var stub = ["............", "............", "...22..22...", "...22..22..."];
			// 0 állás, 1-4 futás (1 és 4 a földet érés), 5 ugrás, 6 esés, 7 fal, 8 dash, 9 sérülés, 10 kikapcsolt, 11-12 a futás vége
			var legs = [stand, contact, passing, reach, mirror(contact), jump, fall, stand, ["..22....22..", "..32....23..", "...22..22...", "..333..333.."], fall, stand, mirror(passing), mirror(reach)];
			var bobs = [false, true, false, false, true, false, false, false, false, false, false, false, false];
			if (!has(Parts.LEGS))
			{
				legs = [for (_ in legs) stub];
				bobs = [for (_ in bobs) false];
			}
			var frames:Array<Array<String>> = [];
			for (i in 0...legs.length)
			{
				var bob = bobs[i];
				var o = bob ? 1 : 0;
				var body = BODY.copy();
				if (!has(Parts.VISOR))
				{
					body[2] = "..30022003..";
					body[3] = "..30022003..";
				}
				else if (i == 9)
					body[3] = "..34422443..";
				if (!has(Parts.CORE))
				{
					body[7] = ".2232222322.";
					body[8] = ".2232222322.";
				}
				if (i == 10)
				{
					// kikapcsolt (lemerült akku): sötét szem, lekonyuló antenna, kialudt mag
					body[0] = "............";
					body[2] = "..30022003..";
					body[3] = "..30022003..";
					body[7] = ".2232222322.";
					body[8] = ".2232222322.";
				}
				var rows = (bob ? ["............"] : []).concat(body).concat(legs[i]);
				function setc(r:Int, c:Int, ch:String):Void
				{
					var s = rows[r + o];
					rows[r + o] = s.substr(0, c) + ch + s.substr(c + 1);
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

	/** Lámpa 8x8 (a fény-shader forrása a LampShader; ez csak a lámpatest). */
	public static function lamp():BitmapData
	{
		return cached("lamp", () -> strip([["...22...", "...22...", "..2222..", ".233332.", "23344332", ".234432.", "..3443..", "...44..."]]));
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
			["...4444...", "..433334..", "..433334..", "..434434..", "..433334..", "..433334..", "...4444...", "...3333...", "....33....", "....3....."],
			// 10: KERET (társ-alkatrész)
			["4444444444", "4........4", "4.44..44.4", "4.44..44.4", "4........4", "4.444444.4", "4........4", "4.44..44.4", "4........4", "4444444444"],
			// 11: MOTOR
			["...4444...", "..433334..", ".43333334.", "4332222334", "4332442334", "4332442334", "4332222334", ".43333334.", "..433334..", "...4444..."],
			// 12: FEJ
			["....44....", "....44....", ".44444444.", ".43333334.", ".43444434.", ".43444434.", ".43333334.", ".44444444.", "..44..44..", ".........."]
		]));
	}

	/** Tolható láda 16x16 (deszkák, rácsos). */
	public static function crate():BitmapData
	{
		return cached("crate", () ->
		{
			var rows:Array<String> = [];
			for (y in 0...16)
			{
				var r = "";
				for (x in 0...16)
				{
					var ch = "2";
					if (x == 0 || y == 0 || x == 15 || y == 15)
						ch = "3";
					else if (x == y || x == 15 - y)
						ch = "1";
					else if ((x == 7 || x == 8) && (y == 7 || y == 8))
						ch = "3";
					r += ch;
				}
				rows.push(r);
			}
			return strip([rows]);
		});
	}

	/** Kar 16x10: 0 lent, 1 átbillentve. */
	public static function lever():BitmapData
	{
		return cached("lever", () ->
		{
			var a = ["....3333........", "....3..3........", "....3..3........", "...33..33.......", "..44...........", ".44.............", "................", "................", "..222222222222..", "..333333333333.."];
			var b = ["........3333....", "........3..3....", "........3..3....", ".......33..33...", "...........44..", "..............44", "................", "................", "..222222222222..", "..333333333333.."];
			return strip([a, b]);
		});
	}

	/** Sorrend-kapcsoló 12x14: 0 fent, 1 lenyomva. */
	public static function switchPad():BitmapData
	{
		return cached("switchpad", () ->
		{
			var a = ["....3333....", "...344443...", "...344443...", "....3333....", "............", "............", "............", "............", "............", "..22222222..", ".2333333332.", ".2333333332.", ".2222222222.", "222222222222"];
			var b = ["............", "............", "............", "............", "............", "............", "............", "....3333....", "...344443...", "..22222222..", ".2333333332.", ".2333333332.", ".2222222222.", "222222222222"];
			return strip([a, b]);
		});
	}

	/** Rács 16x16 (a hős nem fér át, az apró társ igen). */
	public static function grate():BitmapData
	{
		return cached("grate", () ->
		{
			var rows:Array<String> = [];
			for (y in 0...16)
			{
				var r = "";
				for (x in 0...16)
					r += (y == 0 || y == 15) ? "3" : ((x % 5 == 2) ? "3" : (y % 6 == 3 ? "2" : "."));
				rows.push(r);
			}
			return strip([rows]);
		});
	}

	/** Aljzat 12x12: 0 üres, 1-2 áram alatt. */
	public static function socket():BitmapData
	{
		return cached("socket", () ->
		{
			var a = ["444444444444", "422222222224", "423333333324", "423000000324", "423000000324", "423000000324", "423000000324", "423333333324", "422222222224", "444444444444", "............", "............"];
			var b = ["444444444444", "422222222224", "423333333324", "423444444324", "423444444324", "423444444324", "423444444324", "423333333324", "422222222224", "444444444444", "............", "............"];
			var c = ["444444444444", "422222222224", "423333333324", "423433334324", "423344443324", "423344443324", "423433334324", "423333333324", "422222222224", "444444444444", "............", "............"];
			return strip([a, b, c]);
		});
	}

	/** Áramcella 8x12 (hengeres, villám-jellel). */
	public static function powerCell():BitmapData
	{
		return cached("powercell", () -> strip([[".333333.", "34444443", "34444443", "34433443", "34334443", "34443343", "34433443", "34444443", "34444443", "34444443", ".333333.", ".222222."]]));
	}

	/** Zárt kapu-elem (lakat). */
	public static function lockGate():BitmapData
	{
		return cached("lockgate", () ->
		{
			var rows:Array<String> = [];
			for (y in 0...16)
			{
				var r = "";
				for (x in 0...16)
				{
					var ch = y == 0 ? "4" : ((x % 4) >= 2 ? "3" : "0");
					if (x >= 4 && x <= 11 && y >= 6 && y <= 13)
						ch = (x == 4 || x == 11 || y == 6 || y == 13) ? "4" : (x >= 7 && x <= 8 && y >= 8 && y <= 10 ? "0" : "2");
					if (x >= 6 && x <= 9 && y >= 2 && y <= 5 && (x == 6 || x == 9 || y == 2))
						ch = "4";
					r += ch;
				}
				rows.push(r);
			}
			return strip([rows]);
		});
	}

	/** Szerelőasztal 24x16 (a társ összeépítéséhez): lábak, lap, szerszámok. */
	public static function bench():BitmapData
	{
		return cached("bench", () ->
		{
			var rows:Array<String> = [];
			for (y in 0...16)
			{
				var r = "";
				for (x in 0...24)
				{
					var ch = ".";
					if (y >= 8 && y <= 10)
						ch = y == 8 ? "4" : "3";
					else if (y > 10 && (x < 3 || x > 20))
						ch = "2";
					else if (y > 10 && (x == 11 || x == 12))
						ch = "1";
					// szerszámok a lapon
					if (y == 7 && x >= 3 && x <= 8)
						ch = "3";
					if (y >= 4 && y <= 7 && x == 15)
						ch = "4";
					if (y == 4 && x >= 15 && x <= 18)
						ch = "4";
					if (y >= 5 && y <= 7 && x >= 19 && x <= 21)
						ch = "2";
					r += ch;
				}
				rows.push(r);
			}
			return strip([rows]);
		});
	}

	/** Társ-robotok: 0 WHEELIE (10x10), 1 TALL (10x30), 2 ORB (10x10); mindegyik 2 kép. */
	public static function companion(kind:Int):BitmapData
	{
		return cached("companion" + kind, () ->
		{
			if (kind == 1)
			{
				function tall(step:Int):Array<String>
				{
					// vázlat: lekerekített fejű kapszula, álmos szemek, kis száj, két vékony láb
					var rows:Array<String> = [
						"...3333...", "..333333..", ".33333333.", ".30330330.", ".34433443.", ".34033403.", ".33333333.", ".33333333.", ".33300333.",
						".33333333.", ".33333333.", ".33333333.", ".33333333.", ".33333333.", ".33333333.", ".23333332.", ".22222222."
					];
					for (i in 0...13)
					{
						var l = step == 0 ? "...2..2..." : "..2....2..";
						if (i == 12)
							l = step == 0 ? "..33..33.." : ".33....33.";
						rows.push(l);
					}
					return rows;
				}
				return strip([tall(0), tall(1)]);
			}
			if (kind == 2)
			{
				var a = ["...3333...", "..333333..", ".33222233.", "3322222233", "3224444223", "3224004223", "3224004223", "3224444223", ".33222233.", "..333333.."];
			var b = ["...3333...", "..333333..", ".33222233.", "3322222233", "3224444223", "3222404223", "3222404223", "3224444223", ".33222233.", "..333333.."];
			return strip([a, b]);
			}
			// WHEELIE: antennás, széles fejű, két kerekű kis robot
			var a = ["..44......", "...3......", ".33333333.", ".34433443.", ".34033403.", ".33333333.", "...2222...", "...2222...", "..323.323.", "..333.333."];
			var b = ["..44......", "...3......", ".33333333.", ".34433443.", ".34033403.", ".33333333.", "...2222...", "...2222...", "..333.333.", "..323.323."];
			return strip([a, b]);
		});
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
			var a = [".333333333333.", "33333333333333", "33444433444333", "33400433404333", "33400433404333", "33444433444333", "33333333333333", "33333333333333", "22..22..22..22", "22..22..22..22"];
			var b = [".333333333333.", "33333333333333", "33444433444333", "33400433404333", "33400433404333", "33444433444333", "33333333333333", "33333333333333", ".22..22..22..2", "22..22..22..22"];
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
			var a = ["..3...44...3..", "..33..3...33..", "...33333333...", "...34033043...", "...33333333...", "......22......", "......22......", "......33......"];
			var b = ["......44......", "......3.......", "...33333333...", "...34033043...", "33.33333333.33", "3.....22.....3", "......22......", "......33......"];
			return strip([a, b]);
		});
	}

	public static function crawler():BitmapData
	{
		return cached("crawler", () ->
		{
			var a = ["..............", ".333333333333.", "33333333333333", "33344333344333", "33330333303333", "33333000033333", "33333333333333", ".222222222222.", ".232232232232.", ".322322322322."];
			var b = ["..............", ".333333333333.", "33333333333333", "33344333344333", "33330333303333", "33333000033333", "33333333333333", ".222222222222.", ".223223223223.", ".232232232232."];
			return strip([a, b]);
		});
	}

	/** Címképernyő kabala (a vázlat alapján): fogaskerék-haj, négyzetes fej, kerek láb. 14x18. */
	public static function mascot():BitmapData
	{
		return cached("mascot", () -> strip([["....3..3.3....", "..3333333333..", "..3.33333.33..", "..3333333333..", "22222222222222", "2............2", "2..00....00..2", "2..04....04..2", "2............2", "2....0..0....2", "2.....00.....2", "2............2", "22222222222222", ".....3333.....", "....344443....", "....344443....", "....334433....", ".....3333....."]]));
	}

	// --- Tárgyak ---
	public static function atom():BitmapData
	{
		return cached("atom", () ->
		{
			// atom: mag + két keresztező, átlósan döntött pálya; az elektron körbefut (4 kocka)
			var base = [".3....3.", "3.3..3.3", ".3.33.3.", "..3443..", "..3443..", ".3.33.3.", "3.3..3.3", ".3....3."];
			var frames:Array<Array<String>> = [];
			var rowsAt = [0, 1, 7, 6];
			var rowsTxt = [".4....3.", "3.3..3.4", ".3....4.", "4.3..3.3"];
			for (k in 0...4)
			{
				var f = base.copy();
				f[rowsAt[k]] = rowsTxt[k];
				frames.push(f);
			}
			return strip(frames);
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
		// a mennyezeti lámpák már nincsenek a falpapírra festve: Lamp objektumok (Tiled-ben is látszanak és mozgathatók)
		return bd;
	}

	/** Számítógép-terminál 16x16: 0 kikapcsolt, 1 működik (feladat), 2 megoldva (pipa). */
	public static function terminal():BitmapData
	{
		return cached("terminal", () ->
		{
			function make(state:Int):Array<String>
			{
				var rows:Array<String> = [];
				for (y in 0...16)
				{
					var r = "";
					for (x in 0...16)
					{
						var ch = ".";
						if (y >= 1 && y <= 11 && x >= 1 && x <= 14)
							ch = (y == 1 || y == 11 || x == 1 || x == 14) ? "3" : "2";
						if (y >= 3 && y <= 9 && x >= 3 && x <= 12)
							ch = "0";
						if (state == 1 && y >= 4 && y <= 8 && x >= 4 && x <= 11 && y % 2 == 0 && x < 11 - (y == 8 ? 3 : 0))
							ch = "4";
						if (state == 2)
						{
							var on = (x == 5 && y == 6) || (x == 6 && y == 7) || (x == 7 && y == 8) || (x == 8 && y == 7) || (x == 9 && y == 6) || (x == 10 && y == 5);
							if (on)
								ch = "4";
						}
						if (y >= 12 && y <= 13 && x >= 6 && x <= 9)
							ch = "2";
						if (y >= 14 && y <= 15 && x >= 3 && x <= 12)
							ch = y == 14 ? "3" : "2";
						r += ch;
					}
					rows.push(r);
				}
				return rows;
			}
			return strip([make(0), make(1), make(2)]);
		});
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
	public static function backdrop(w:Int, seed0:Int, tone:String, density:Int, style:Int = 0):BitmapData
	{
		var bd = new BitmapData(w, 340, true, 0x00000000);
		var seed = seed0;
		function rnd():Int
		{
			seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF;
			return seed >> 8;
		}
		var col = color(tone);
		// az alacsony sziluettek (gyár, kupolák, hűtőtornyok, fogaskerekek) feljebb ülnek, különben a talaj eltakarja őket
		var lifted = style == 1 || style == 3 || style == 4 || style == 5;
		var H = lifted ? 255 : 340;
		var BLK = 0xFF000000;
		function rect(x:Int, y:Int, rw:Int, rh:Int, c:Int = -1):Void
			bd.fillRect(new openfl.geom.Rectangle(x, y, rw, rh), c == -1 ? col : c);
		/** Átlátszóra vágás (ívek, lyukak). */
		function cut(x:Int, y:Int, rw:Int, rh:Int):Void
			bd.fillRect(new openfl.geom.Rectangle(x, y, rw, rh), 0x00000000);
		function disc(cx:Int, cy:Int, r:Int):Void
		{
			for (dy in -r...r + 1)
			{
				var dx = Std.int(Math.sqrt(r * r - dy * dy));
				rect(cx - dx, cy + dy, 2 * dx + 1, 1);
			}
		}
		var x = 0;
		switch (style)
		{
			case 1: // gyár: fűrészfogas csarnokok és magas kémények
				while (x < w)
				{
					if (rnd() % 4 == 0)
					{
						var cw = 5 + rnd() % 3;
						var ch = 120 + rnd() % 90;
						rect(x, H - ch, cw, ch);
						rect(x - 1, H - ch, cw + 2, 3);
						rect(x + 1, H - ch + 10, cw - 2, 1, BLK);
						x += cw + 6 + rnd() % density;
					}
					else
					{
						var bw = 28 + rnd() % 40;
						var bh = 40 + rnd() % 60;
						rect(x, H - bh, bw, bh);
						var tx = x;
						while (tx + 8 <= x + bw)
						{
							for (k in 0...8)
								rect(tx + k, H - bh - k, 1, k);
							tx += 8;
						}
						for (wx in 0...Std.int(bw / 8))
							rect(x + 3 + wx * 8, H - bh + 10, 4, 3, BLK);
						x += bw + rnd() % density;
					}
				}
			case 2: // rácsos árbocok villogó lámpával
				while (x < w)
				{
					var mh = 110 + rnd() % 130;
					var mw = 12 + rnd() % 6;
					var secH = 14;
					for (yy in 0...mh)
					{
						var half = mw / 2 * (1 - yy / mh) + 1;
						var l = Std.int(x + mw / 2 - half);
						var r = Std.int(x + mw / 2 + half - 1);
						rect(l, H - yy - 1, 1, 1);
						rect(r, H - yy - 1, 1, 1);
						// átlós merevítés: szakaszonként ellenkező irányban
						var sec = Std.int(yy / secH);
						var k = (yy % secH) / secH;
						var px = (sec % 2 == 0) ? l + k * (r - l) : r - k * (r - l);
						rect(Std.int(px), H - yy - 1, 1, 1);
					}
					rect(x + Std.int(mw / 2), H - mh - 16, 1, 16);
					rect(x + Std.int(mw / 2) - 1, H - mh - 18, 3, 2, color("1"));
					x += mw + 18 + rnd() % (density * 2);
				}
			case 3: // kupolák és gömbtartályok
				while (x < w)
				{
					var r = 14 + rnd() % 22;
					if (rnd() % 2 == 0)
					{
						var bh = 10 + rnd() % 16;
						rect(x, H - bh, 2 * r + 1, bh);
						disc(x + r, H - bh, r);
						rect(x + r - 1, H - bh - r - 8, 2, 8);
					}
					else
					{
						var legH = 40 + rnd() % 50;
						var cy = H - legH - r;
						disc(x + r, cy, r);
						rect(x + 3, cy + Std.int(r / 2), 3, H - cy - Std.int(r / 2));
						rect(x + 2 * r - 5, cy + Std.int(r / 2), 3, H - cy - Std.int(r / 2));
						rect(x + r - 1, cy + r, 3, H - cy - r);
						rect(x + 3, H - Std.int(legH / 2), 2 * r - 5, 2);
					}
					x += 2 * r + 6 + rnd() % density;
				}
			case 4: // hűtőtornyok
				while (x < w)
				{
					var th = 100 + rnd() % 70;
					var bw = 44 + rnd() % 28;
					var neck = bw * 0.62;
					for (yy in 0...th)
					{
						var t = yy / th;
						var wd = neck + (bw - neck) * ((t - 0.65) * (t - 0.65)) / (0.65 * 0.65);
						rect(x + Std.int((bw - wd) / 2), H - yy - 1, Std.int(wd), 1);
					}
					x += bw + 6 + rnd() % density;
				}
			case 5: // félig a földbe süllyedt fogaskerekek
				while (x < w)
				{
					var r = 22 + rnd() % 26;
					var cx = x + r;
					var cy = H - 10 - Std.int(r / 2) - rnd() % 20;
					var teeth = 10 + Std.int(r / 4);
					for (dy in -r - 5...r + 6)
						for (dx in -r - 5...r + 6)
						{
							var d = Math.sqrt(dx * dx + dy * dy);
							var rt = r + (Math.sin(Math.atan2(dy, dx) * teeth) > 0 ? 4 : 0);
							if (d <= rt && (d > r * 0.62 || d < r * 0.16 || Math.abs(dx) <= 1 || Math.abs(dy) <= 1) && cx + dx >= 0 && cx + dx < w && cy + dy >= 0 && cy + dy < H)
								bd.setPixel32(cx + dx, cy + dy, col);
						}
					x += r + rnd() % (density + r);
				}
			case 6: // barlang: mennyezet cseppkövekkel, a talajon függő kövek
				rect(0, 0, w, 78);
				while (x < w)
				{
					var sw = 10 + rnd() % 18;
					var sl = 20 + rnd() % 90;
					for (yy in 0...sl)
					{
						var wd = Std.int(Math.max(1, sw * (1 - yy / sl)));
						rect(x + Std.int((sw - wd) / 2), 78 + yy, wd, 1);
					}
					x += sw + 2 + rnd() % density;
				}
				x = 0;
				while (x < w)
				{
					var sw = 10 + rnd() % 16;
					var sh = 40 + rnd() % 110;
					for (yy in 0...sh)
					{
						var wd = Std.int(Math.max(1, sw * (1 - yy / sh)));
						rect(x + Std.int((sw - wd) / 2), H - yy - 1, wd, 1);
					}
					x += sw + 4 + rnd() % (density * 2);
				}
			case 7: // akvadukt: ívsorok
				while (x < w)
				{
					var ph = 90 + rnd() % 50;
					var run = 3 + rnd() % 4;
					var aw = 28;
					rect(x, H - ph, run * aw + 6, ph);
					for (k in 0...run)
					{
						var r = Std.int((aw - 6) / 2);
						var cx = x + k * aw + 6 + r;
						var cy = H - ph + 8 + r;
						for (dy in -r...1)
						{
							var dx = Std.int(Math.sqrt(r * r - dy * dy));
							cut(cx - dx, cy + dy, 2 * dx + 1, 1);
						}
						cut(cx - r, cy, 2 * r + 1, H - cy);
					}
					x += run * aw + 6 + 24 + rnd() % (density * 2);
				}
			case 8: // villanyoszlopok kábelekkel
				var prevX = -1;
				var prevTop = 0;
				while (x < w + 80)
				{
					var ph = 150 + rnd() % 70;
					var top = H - ph;
					rect(x, top, 5, ph);
					rect(x - 8, top + 6, 21, 3);
					rect(x - 5, top + 26, 15, 2);
					if (prevX >= 0)
						for (arm in 0...2)
						{
							var ox0 = arm == 0 ? 8 : 5;
							var oy = arm == 0 ? 7 : 27;
							var x0 = prevX + (arm == 0 ? 10 : 8);
							var x1 = x - (arm == 0 ? 8 : 5);
							for (px in x0...x1 + 1)
							{
								var t = (px - x0) / Math.max(1, x1 - x0);
								var yy = prevTop + oy + (top - prevTop) * t + 14 * 4 * t * (1 - t);
								if (px >= 0 && px < w)
									bd.setPixel32(px, Std.int(yy), col);
							}
						}
					prevX = x;
					prevTop = top;
					x += 70 + rnd() % (density * 2);
				}
			case 9: // felhőkarcolók: lépcsős tetők, antennák
				while (x < w)
				{
					var bw = 14 + rnd() % 26;
					var bh = 110 + rnd() % 130;
					rect(x, H - bh, bw, bh);
					if (bw > 18)
					{
						rect(x + 3, H - bh - 12, bw - 6, 12);
						if (bw > 28)
							rect(x + 7, H - bh - 20, bw - 14, 8);
					}
					if (rnd() % 3 == 0)
						rect(x + Std.int(bw / 2), H - bh - 34, 1, 34);
					for (wy in 0...Std.int(bh / 10) - 1)
						for (wx in 0...Std.int((bw - 4) / 6))
							if (rnd() % 4 != 0)
								rect(x + 3 + wx * 6, H - bh + 6 + wy * 10, 2, 3, BLK);
					x += bw + rnd() % Std.int(density / 2 + 1);
				}
			default: // romok
				while (x < w)
				{
					var pw = 8 + rnd() % 22;
					var ph = 90 + rnd() % 140;
					var broken = rnd() % 3 == 0 ? rnd() % 20 : 0;
					for (px in x...Std.int(Math.min(w, x + pw)))
						for (py in 340 - ph + broken...340)
							bd.setPixel32(px, py, col);
					// ablakok / rések
					if (pw > 12)
						for (wy in 0...Std.int(ph / 16))
							if (rnd() % 3 != 0)
								bd.fillRect(new openfl.geom.Rectangle(x + 3, 340 - ph + broken + 8 + wy * 16, 3, 5), 0xFF000000);
					x += pw + rnd() % density;
				}
		}
		// a feljebb ültetett sziluettek alatt tömör sáv, hogy a szakadékokban ne látsszon át
		if (lifted)
			rect(0, H, w, 340 - H);
		return bd;
	}

	/** Csillagpontok (halvány) a legtávolabbi rétegre. */
	public static function stars(w:Int, seed0:Int, celestial:Int = 0):BitmapData
	{
		var bd = new BitmapData(w, 340, true, 0x00000000);
		var seed = seed0;
		// égitest: 1 hold (sarlóval árnyékolva), 2 gyűrűs bolygó, 3 napfogyatkozás
		if (celestial > 0)
		{
			var cx = 90 + (seed0 * 37) % 260;
			var cy = 112 + (seed0 * 13) % 40;
			var R = celestial == 1 ? 26 : (celestial == 2 ? 22 : 34);
			for (dy in -R - 50...R + 51)
				for (dx in -R - 50...R + 51)
				{
					var d = Math.sqrt(dx * dx + dy * dy);
					var px = cx + dx;
					var py = cy + dy;
					if (px < 0 || px >= w || py < 0 || py >= 340)
						continue;
					switch (celestial)
					{
						case 1:
							var d2 = Math.sqrt((dx - 9) * (dx - 9) + (dy + 3) * (dy + 3));
							if (d <= R && d2 > R - 2)
								bd.setPixel32(px, py, (dx + dy) % 7 == 0 && d < R - 4 ? 0xFF282828 : 0xFF383838);
						case 2:
							var ring = (dx / 46.0) * (dx / 46.0) + (dy / 9.0) * (dy / 9.0);
							var onRing = ring > 0.74 && ring < 1;
							if (d <= R)
								bd.setPixel32(px, py, (dy % 6 == 0) ? 0xFF282828 : 0xFF303030);
							if (onRing && (dy > 0 || d > R))
								bd.setPixel32(px, py, 0xFF454545);
						default:
							if (d <= R - 1)
								bd.setPixel32(px, py, 0xFF0E0E0E);
							else if (d <= R + 1)
								bd.setPixel32(px, py, 0xFF606060);
							else if (d <= R + 7 && (Std.int(Math.atan2(dy, dx) * 9 / Math.PI * 2) % 2 == 0))
								bd.setPixel32(px, py, 0xFF2A2A2A);
					}
				}
		}
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
