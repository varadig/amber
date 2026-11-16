package;

typedef Pt =
{
	x:Float,
	y:Float
}

typedef EnemySpawn =
{
	kind:Int,
	x:Float,
	y:Float
}

/**
 * Egy pálya adatai (csempe-koordináták: 16 px). A pályát szegmensekből építi egy determinisztikus generátor (a pálya sorszáma a mag),
 * és minden szegmens a hős képességeire van méretezve: ugrás ~3,6 csempe magas, ~4 csempe széles; fal-ugrás, szökellés (dash) extra.
 */
class LevelData
{
	public static inline var T = 16;
	public static inline var H = 30;
	public static inline var COUNT = 5;
	public static inline var WALKER = 0;
	public static inline var FLYER = 1;
	public static inline var CRAWLER = 2;

	public static final NAMES = ["RUSTED CAVES", "COPPER WELLS", "NEON RUINS", "DEEP STATIC", "THE AMBER CORE"];

	public var level:Int;
	public var name:String;
	public var w:Int = 0;
	/** Oszloponként a talaj teteje (a csempesor); 99 = szakadék. */
	public var top:Array<Int> = [];
	/** Szilárd csempék (1 talaj teteje, 2 talaj, 3 tégla). */
	public var solid:Array<Int> = [];
	/** Egyirányú platformok (csempe 4). */
	public var plats:Array<Int> = [];
	public var gems:Array<Pt> = [];
	public var hearts:Array<Pt> = [];
	public var enemies:Array<EnemySpawn> = [];
	public var spikes:Array<Pt> = [];
	public var checkpoints:Array<Pt> = [];
	public var key:Pt;
	public var door:Pt;
	public var spawn:Pt;

	var seed:Int;
	var cur:Int = 18;
	var platList:Array<{x:Int, y:Int, w:Int}> = [];
	var tilePlats:Array<{x:Int, y:Int}> = [];

	function new(level:Int)
	{
		this.level = level;
		name = NAMES[level % NAMES.length];
		seed = level * 7919 + 4243;
	}

	function rnd():Float
	{
		seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF;
		return (seed >> 8) / 8388608.0;
	}

	function ri(a:Int, b:Int):Int
		return a + Std.int(rnd() * (b - a + 1));

	inline function flat(len:Int, h:Int):Void
	{
		for (i in 0...len)
			top.push(h);
	}

	function gem(col:Float, row:Float):Void
		gems.push({x: col * T + 4, y: row * T + 4});

	/** Szilárd csempe-e a (tx, ty) (az ellenségek éldetektálásához; az egyirányú platform is számít). */
	public function isSolid(tx:Int, ty:Int):Bool
	{
		if (tx < 0 || tx >= w || ty < 0 || ty >= H)
			return false;
		var i = ty * w + tx;
		return solid[i] != 0 || plats[i] != 0;
	}

	public static function generate(level:Int):LevelData
	{
		var d = new LevelData(level);
		d.build();
		return d;
	}

	function build():Void
	{
		var L = level;
		flat(8, cur);
		spawn = {x: 3 * T + 2, y: cur * T - 14};
		var nSeg = 9 + 2 * L;
		var climbAt = Std.int(nSeg * 0.5);
		var enemyChance = 0.55 + 0.08 * L;
		for (s in 0...nSeg)
		{
			if (s == climbAt)
			{
				climb();
				continue;
			}
			// minden harmadik szegmens nyugodt, ellenőrzőpontos sík szakasz
			if (s % 3 == 2)
			{
				var c0 = top.length;
				flat(ri(6, 8), cur);
				checkpoints.push({x: (c0 + 1) * T + 4, y: cur * T - 16});
				gem(c0 + 3, cur - 2);
				gem(c0 + 4, cur - 2);
				if (L >= 1 && rnd() < 0.25)
					hearts.push({x: (c0 + 5) * T + 4, y: cur * T - 12});
				continue;
			}
			var wells = L >= 2 ? 1 : 0;
			var pick = rnd() * (3 + 3 + 3 + (L >= 1 ? 2 : 0) + 2 + 2 + wells);
			if (pick < 3)
				segFlat(enemyChance, enemies.length < 2 + L);
			else if (pick < 6)
				segStep();
			else if (pick < 9)
				segPit(L);
			else if (pick < 9 + (L >= 1 ? 2 : 0))
				segIslands();
			else if (pick < 11 + (L >= 1 ? 2 : 0))
				segSpikes(L);
			else if (pick < 13 + (L >= 1 ? 2 : 0))
				segArena(L);
			else
				segWell();
		}
		// vég: sík szakasz az ajtóval
		var c0 = top.length;
		flat(12, cur);
		door = {x: (c0 + 8) * T, y: cur * T - 24};
		w = top.length;
		fill();
	}

	function segFlat(chance:Float, force:Bool):Void
	{
		var c0 = top.length;
		var len = ri(5, 9);
		flat(len, cur);
		var n = ri(2, 4);
		for (i in 0...n)
			gem(c0 + 1 + i * 1.5, cur - 2);
		if (force || rnd() < chance)
			enemies.push({kind: WALKER, x: (c0 + len / 2) * T, y: cur * T - 10});
	}

	function segStep():Void
	{
		var opts = [];
		for (dy in [-2, -1, 1, 2])
			if (cur + dy >= 15 && cur + dy <= 20)
				opts.push(dy);
		var dy = opts[ri(0, opts.length - 1)];
		cur += dy;
		var c0 = top.length;
		flat(4, cur);
		gem(c0 + 1, cur - 2);
		gem(c0 + 2, cur - 2);
	}

	function segPit(L:Int):Void
	{
		var len = ri(2, 3 + (L >= 2 ? 1 : 0));
		var c0 = top.length;
		for (i in 0...len)
			top.push(99);
		for (i in 0...len)
			gem(c0 + i, cur - 3 - ((i == Std.int(len / 2)) ? 1 : 0));
		if (len >= 4)
			platList.push({x: c0 + 1, y: cur + 1, w: 2});
		flat(3, cur);
	}

	function segIslands():Void
	{
		var n = ri(2, 3);
		var c0 = top.length;
		var rowPrev = cur;
		for (i in 0...n)
		{
			for (k in 0...2)
				top.push(99);
			for (k in 0...3)
				top.push(99);
			var row = Std.int(Math.max(cur - 3, Math.min(cur + 1, rowPrev + ri(-1, 1))));
			rowPrev = row;
			var px = c0 + i * 5 + 2;
			platList.push({x: px, y: row, w: 3});
			gem(px + 1, row - 2);
		}
		top.push(99);
		top.push(99);
		flat(3, cur);
		if (rnd() < 0.6)
			enemies.push({kind: FLYER, x: (c0 + n * 2.5) * T, y: (cur - 5) * T});
	}

	function segSpikes(L:Int):Void
	{
		var len = L >= 2 ? ri(2, 3) : 2;
		flat(2, cur);
		var c0 = top.length;
		flat(len, cur);
		for (i in 0...len)
			spikes.push({x: (c0 + i) * T, y: cur * T - 8});
		for (i in 0...len)
			gem(c0 + i, cur - 3 - ((i == 1) ? 1 : 0));
		flat(3, cur);
	}

	function segArena(L:Int):Void
	{
		var c0 = top.length;
		var len = ri(10, 12);
		flat(len, cur);
		var nw = ri(1, 2) + (L >= 2 ? 1 : 0);
		for (i in 0...nw)
			enemies.push({kind: WALKER, x: (c0 + 2 + i * 3) * T, y: cur * T - 10});
		if (L >= 1)
			enemies.push({kind: FLYER, x: (c0 + len / 2) * T, y: (cur - 5) * T});
		if (L >= 2 && rnd() < 0.7)
			enemies.push({kind: CRAWLER, x: (c0 + len - 3) * T, y: cur * T - 10});
		for (i in 0...4)
			gem(c0 + 2 + i * 2, cur - 2 - (i % 2));
	}

	function segWell():Void
	{
		flat(2, cur);
		var c0 = top.length;
		for (i in 0...3)
			top.push(cur + 6);
		gem(c0 + 1, cur + 2);
		gem(c0 + 1, cur + 4);
		gems.push({x: c0 * T + 4 - 4, y: (cur + 3) * T + 4});
		flat(3, cur);
	}

	function climb():Void
	{
		// a torony alatt a talaj 15..20 sorban legyen
		if (cur < 15)
			cur = 15;
		var c0 = top.length;
		flat(14, cur);
		for (k in 1...5)
		{
			var row = cur - 3 * k;
			var px = k % 2 == 1 ? c0 + 2 : c0 + 8;
			platList.push({x: px, y: row, w: 4});
			if (k < 4)
			{
				gem(px + 1, row - 2);
				gem(px + 2, row - 2);
			}
			else
				key = {x: (px + 1) * T + 3, y: (row - 1) * T + 4};
		}
		gem(c0 + 5, cur - 2);
	}

	/** A talaj- és platform-csempék feltöltése. */
	function fill():Void
	{
		solid = [for (i in 0...(w * H)) 0];
		plats = [for (i in 0...(w * H)) 0];
		for (x in 0...w)
		{
			var t = top[x];
			if (t >= H)
				continue;
			for (y in t...H)
				solid[y * w + x] = (y == t) ? 1 : 2;
		}
		for (p in platList)
			for (i in 0...p.w)
			{
				var x = p.x + i;
				if (x >= 0 && x < w && p.y >= 0 && p.y < H && solid[p.y * w + x] == 0)
					plats[p.y * w + x] = 4;
			}
	}
}
