package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import openfl.geom.Rectangle;

/** A házak számítógépei: a terminálon egy kis játék a játékban; a megoldás nyitja a belső terem kapuját. */
class MiniGames
{
	public static inline var SLIDE = 0;
	public static inline var SIMON = 1;
	public static inline var LIGHTS = 2;
	public static inline var TANK = 3;
	public static inline var COUNT = 4;

	public static final TITLES = ["CIRCUIT REPAIR", "DOOR LOCK", "POWER GRID", "DEFENSE SIMULATION"];
	public static final STORY = [
		"A BROKEN CIRCUIT BOARD. SLIDE THE TILES BACK INTO ORDER.",
		"THE LOCK ASKS FOR ITS OLD SEQUENCE. WATCH, THEN REPEAT IT.",
		"EVERY LIGHT IN THE BUILDING IS STUCK ON. SWITCH THEM ALL OFF.",
		"AN OLD TRAINING PROGRAM STILL RUNS. DESTROY ALL THE ENEMY TANKS."
	];
	public static final HINTS = [
		"ARROWS: SLIDE A TILE    ESC: LEAVE",
		"ARROWS: REPEAT THE SEQUENCE    ESC: LEAVE",
		"ARROWS: MOVE    SPACE: TOGGLE (AND NEIGHBOURS)    ESC: LEAVE",
		"ARROWS: DRIVE    SPACE: FIRE    ESC: LEAVE"
	];

	public static function make(game:Int, diff:Int, onDone:Bool->Void):MiniGame
	{
		var g:MiniGame = switch (game % COUNT)
		{
			case SLIDE: new SlideGame();
			case SIMON: new SimonGame();
			case LIGHTS: new LightsGame();
			default: new TankGame();
		}
		g.setup(TITLES[game % COUNT], STORY[game % COUNT], HINTS[game % COUNT], diff, onDone);
		return g;
	}
}

/** Közös keret: sötét háttér, panel, cím, történet, súgó, üzenet; a Esc kilép; a megoldás után "ACCESS GRANTED", majd bezár. */
class MiniGame extends FlxSubState
{
	public var onDone:Bool->Void;
	var titleS:String = "";
	var storyS:String = "";
	var hintS:String = "";
	var diff:Int = 1;
	var msg:FlxText;
	var finished:Bool = false;
	var closed:Bool = false;
	var endT:Float = 0;

	public function new()
	{
		super(0x00000000);
	}

	public function setup(title:String, story:String, hint:String, diff:Int, onDone:Bool->Void):Void
	{
		titleS = title;
		storyS = story;
		hintS = hint;
		this.diff = diff;
		this.onDone = onDone;
	}

	function txt(s:String, x:Float, y:Float, w:Float, size:Int, color:Int, align:String = "left"):FlxText
	{
		var t = new FlxText(x, y, w, s, size);
		t.setFormat(null, size, color, align == "center" ? CENTER : LEFT);
		t.scrollFactor.set(0, 0);
		add(t);
		return t;
	}

	function box(x:Float, y:Float, w:Int, h:Int, color:Int):FlxSprite
	{
		var s = new FlxSprite(x, y);
		s.makeGraphic(w, h, color);
		s.scrollFactor.set(0, 0);
		add(s);
		return s;
	}

	override public function create():Void
	{
		super.create();
		box(0, 0, 480, 270, 0xF2000000);
		var panel = new FlxSprite(50, 14);
		panel.makeGraphic(380, 242, 0xFF777777, true);
		panel.pixels.fillRect(new Rectangle(2, 2, 376, 238), 0xFF080808);
		panel.dirty = true;
		panel.scrollFactor.set(0, 0);
		add(panel);
		txt("> " + titleS, 62, 20, 360, 8, 0xFFFFFFFF);
		txt(storyS, 62, 32, 356, 8, 0xFF999999);
		txt(hintS, 62, 238, 360, 8, 0xFF777777);
		msg = txt("", 62, 218, 356, 8, 0xFFFFFFFF, "center");
		build();
	}

	function build():Void {}

	function tick(dt:Float):Void {}

	function win():Void
	{
		if (finished)
			return;
		finished = true;
		msg.text = "ACCESS GRANTED";
		Audio.play("door", 1);
	}

	function leave(ok:Bool):Void
	{
		if (closed)
			return;
		closed = true;
		close();
		if (onDone != null)
			onDone(ok);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (closed)
			return;
		if (FlxG.keys.justPressed.ESCAPE && !finished)
		{
			leave(false);
			return;
		}
		if (finished)
		{
			endT += elapsed;
			if (endT > 1.1)
				leave(true);
			return;
		}
		tick(elapsed);
	}
}

/** Csúszó-kirakó: 3x3, a csempéket a helyükre kell csúsztatni. */
class SlideGame extends MiniGame
{
	var tiles:Array<Int> = [];
	var sp:Array<FlxSprite> = [];
	var lb:Array<FlxText> = [];

	override function build():Void
	{
		tiles = [1, 2, 3, 4, 5, 6, 7, 8, 0];
		var blank = 8, last = -1;
		for (i in 0...(50 + diff * 20))
		{
			var r = Std.int(blank / 3), c = blank % 3;
			var opts:Array<Int> = [];
			if (r > 0)
				opts.push(blank - 3);
			if (r < 2)
				opts.push(blank + 3);
			if (c > 0)
				opts.push(blank - 1);
			if (c < 2)
				opts.push(blank + 1);
			opts = opts.filter(o -> o != last);
			var n = opts[Std.random(opts.length)];
			tiles[blank] = tiles[n];
			tiles[n] = 0;
			last = blank;
			blank = n;
		}
		for (i in 0...9)
		{
			var s = box(150 + (i % 3) * 62, 66 + Std.int(i / 3) * 52, 58, 48, 0xFFBBBBBB);
			sp.push(s);
			lb.push(txt("", 150 + (i % 3) * 62, 74 + Std.int(i / 3) * 52, 58, 16, 0xFF000000, "center"));
		}
		refresh();
	}

	function refresh():Void
	{
		for (i in 0...9)
		{
			sp[i].visible = tiles[i] != 0;
			lb[i].text = tiles[i] != 0 ? Std.string(tiles[i]) : "";
		}
	}

	override function tick(dt:Float):Void
	{
		var blank = tiles.indexOf(0);
		var from = -1;
		if (FlxG.keys.justPressed.LEFT && blank % 3 < 2)
			from = blank + 1;
		else if (FlxG.keys.justPressed.RIGHT && blank % 3 > 0)
			from = blank - 1;
		else if (FlxG.keys.justPressed.UP && blank < 6)
			from = blank + 3;
		else if (FlxG.keys.justPressed.DOWN && blank >= 3)
			from = blank - 3;
		if (from < 0)
			return;
		tiles[blank] = tiles[from];
		tiles[from] = 0;
		Audio.play("blip", 0.8);
		refresh();
		var ok = true;
		for (i in 0...8)
			if (tiles[i] != i + 1)
				ok = false;
		if (ok)
			win();
	}
}

/** Sorrend-ismétlő: a négy mező felvillan, a nyilakkal kell megismételni. */
class SimonGame extends MiniGame
{
	var seq:Array<Int> = [];
	var pads:Array<FlxSprite> = [];
	var state:Int = 0;
	var idx:Int = 0;
	var t:Float = 0;
	var inPos:Int = 0;
	var lit:Int = -1;
	var litT:Float = 0;

	override function build():Void
	{
		var len = 4 + Std.int(Math.min(3, diff / 2));
		seq = [for (i in 0...len) Std.random(4)];
		var pos = [[210, 56], [290, 108], [210, 160], [130, 108]];
		for (p in pos)
		{
			var s = box(p[0], p[1], 60, 44, 0xFFFFFFFF);
			pads.push(s);
		}
		msg.text = "WATCH...";
	}

	override function tick(dt:Float):Void
	{
		if (litT > 0)
		{
			litT -= dt;
			if (litT <= 0)
				lit = -1;
		}
		switch (state)
		{
			case 0:
				t += dt;
				if (t < 0.45)
					lit = seq[idx];
				else if (lit == seq[idx] && t < 0.7)
					lit = -1;
				if (t >= 0.7)
				{
					t = 0;
					lit = -1;
					idx++;
					if (idx >= seq.length)
					{
						state = 1;
						inPos = 0;
						msg.text = "YOUR TURN";
					}
				}
			case 1:
				var p = FlxG.keys.justPressed.UP ? 0 : (FlxG.keys.justPressed.RIGHT ? 1 : (FlxG.keys.justPressed.DOWN ? 2 : (FlxG.keys.justPressed.LEFT ? 3 : -1)));
				if (p < 0)
					return;
				lit = p;
				litT = 0.25;
				Audio.play("blip", 0.8);
				if (seq[inPos] == p)
				{
					inPos++;
					if (inPos >= seq.length)
						win();
				}
				else
				{
					msg.text = "WRONG: WATCH AGAIN";
					Audio.play("hurt", 0.5);
					state = 2;
					t = 0;
				}
			default:
				t += dt;
				if (t > 1.0)
				{
					msg.text = "WATCH...";
					state = 0;
					idx = 0;
					t = 0;
				}
		}
		for (i in 0...4)
			pads[i].color = lit == i ? 0xFFFFFFFF : 0xFF3A3A3A;
	}
}

/** Lámpa-kapcsolgató (Lights Out): egy kapcsolás a szomszédokat is átbillenti; mindet ki kell kapcsolni. */
class LightsGame extends MiniGame
{
	var g:Array<Bool> = [for (i in 0...16) false];
	var cells:Array<FlxSprite> = [];
	var cursor:FlxSprite;
	var cx:Int = 0;
	var cy:Int = 0;

	override function build():Void
	{
		for (i in 0...(5 + diff))
			toggle(Std.random(4), Std.random(4));
		if (!g.contains(true))
			toggle(1, 1);
		for (i in 0...16)
			cells.push(box(152 + (i % 4) * 46, 62 + Std.int(i / 4) * 40, 42, 36, 0xFFFFFFFF));
		cursor = new FlxSprite(0, 0);
		cursor.makeGraphic(46, 40, 0xFFFFFFFF, true);
		cursor.pixels.fillRect(new Rectangle(3, 3, 40, 34), 0x00000000);
		cursor.dirty = true;
		cursor.scrollFactor.set(0, 0);
		add(cursor);
		refresh();
	}

	function toggle(x:Int, y:Int):Void
	{
		for (d in [[0, 0], [1, 0], [-1, 0], [0, 1], [0, -1]])
		{
			var nx = x + d[0], ny = y + d[1];
			if (nx >= 0 && nx < 4 && ny >= 0 && ny < 4)
				g[ny * 4 + nx] = !g[ny * 4 + nx];
		}
	}

	function refresh():Void
	{
		for (i in 0...16)
			cells[i].color = g[i] ? 0xFFFFFFFF : 0xFF262626;
		cursor.x = 150 + cx * 46;
		cursor.y = 60 + cy * 40;
	}

	override function tick(dt:Float):Void
	{
		var k = FlxG.keys.justPressed;
		var moved = false;
		if (k.LEFT && cx > 0)
		{
			cx--;
			moved = true;
		}
		else if (k.RIGHT && cx < 3)
		{
			cx++;
			moved = true;
		}
		else if (k.UP && cy > 0)
		{
			cy--;
			moved = true;
		}
		else if (k.DOWN && cy < 3)
		{
			cy++;
			moved = true;
		}
		if (k.SPACE || k.Z || k.ENTER)
		{
			toggle(cx, cy);
			Audio.play("blip", 0.9);
			moved = true;
			if (!g.contains(true))
				win();
		}
		if (moved)
			refresh();
	}
}

/** Mini tank-játék: az ellenséges tankokat kell lelőni (3 élet, a téglafal lőhető). */
class TankGame extends MiniGame
{
	static inline var W = 15;
	static inline var HH = 9;
	static inline var CS = 22;
	var walls:Array<Bool> = [];
	var px:Int = 7;
	var py:Int = HH - 1;
	var pd:Int = 0;
	var lives:Int = 3;
	var enemies:Array<{x:Int, y:Int, d:Int, t:Float, s:Float}> = [];
	var bullets:Array<{x:Float, y:Float, d:Int, own:Bool}> = [];
	var canvas:FlxSprite;
	var moveCd:Float = 0;
	var shootCd:Float = 0;
	var tickT:Float = 0;
	var livesT:FlxText;
	var retryT:Float = 0;

	override function build():Void
	{
		canvas = new FlxSprite(75, 52);
		canvas.makeGraphic(W * CS, HH * CS, 0xFF000000, true);
		canvas.scrollFactor.set(0, 0);
		add(canvas);
		livesT = txt("", 62, 44, 120, 8, 0xFFFFFFFF);
		reset();
	}

	function reset():Void
	{
		walls = [for (i in 0...(W * HH)) false];
		for (k in 0...24)
			walls[(1 + Std.random(HH - 3)) * W + Std.random(W)] = true;
		px = 7;
		py = HH - 1;
		pd = 0;
		lives = 3;
		bullets = [];
		enemies = [];
		var n = 3 + (diff >= 3 ? 1 : 0);
		for (i in 0...n)
		{
			var ex = 1 + Std.int((W - 2) * i / Math.max(1, n - 1));
			walls[ex] = false;
			enemies.push({x: ex, y: 0, d: 2, t: Math.random() * 0.4, s: 0.8 + Math.random()});
		}
		for (dx in -1...2)
			walls[(HH - 1) * W + px + dx] = false;
		walls[(HH - 2) * W + px] = false;
		retryT = 0;
		msg.text = "";
	}

	function freeCell(x:Int, y:Int):Bool
	{
		if (x < 0 || y < 0 || x >= W || y >= HH || walls[y * W + x])
			return false;
		if (x == px && y == py)
			return false;
		for (e in enemies)
			if (e.x == x && e.y == y)
				return false;
		return true;
	}

	static function dx(d:Int):Int
		return d == 1 ? 1 : (d == 3 ? -1 : 0);

	static function dy(d:Int):Int
		return d == 2 ? 1 : (d == 0 ? -1 : 0);

	override function tick(dt:Float):Void
	{
		if (retryT > 0)
		{
			retryT -= dt;
			if (retryT <= 0)
				reset();
			render();
			return;
		}
		moveCd -= dt;
		shootCd -= dt;
		var k = FlxG.keys.pressed;
		var nd = k.LEFT ? 3 : (k.RIGHT ? 1 : (k.UP ? 0 : (k.DOWN ? 2 : -1)));
		if (nd >= 0 && moveCd <= 0)
		{
			pd = nd;
			if (freeCell(px + dx(nd), py + dy(nd)))
			{
				px += dx(nd);
				py += dy(nd);
			}
			moveCd = 0.13;
		}
		var j = FlxG.keys.justPressed;
		if ((j.SPACE || j.Z || j.ENTER) && shootCd <= 0)
		{
			bullets.push({x: px + dx(pd) * 0.6, y: py + dy(pd) * 0.6, d: pd, own: true});
			shootCd = 0.4;
			Audio.play("shoot", 0.6);
		}
		tickT += dt;
		while (tickT >= 0.05)
		{
			tickT -= 0.05;
			stepBullets();
			enemiesAct(0.05);
		}
		if (enemies.length == 0)
			win();
		livesT.text = "LIVES " + lives + "  ENEMIES " + enemies.length;
		render();
	}

	function stepBullets():Void
	{
		var i = bullets.length;
		while (i-- > 0)
		{
			var b = bullets[i];
			b.x += dx(b.d) * 0.45;
			b.y += dy(b.d) * 0.45;
			var cx = Math.round(b.x), cy = Math.round(b.y);
			if (cx < 0 || cy < 0 || cx >= W || cy >= HH)
			{
				bullets.splice(i, 1);
				continue;
			}
			if (walls[cy * W + cx])
			{
				walls[cy * W + cx] = false;
				bullets.splice(i, 1);
				continue;
			}
			if (b.own)
			{
				var hit = -1;
				for (e in 0...enemies.length)
					if (enemies[e].x == cx && enemies[e].y == cy)
						hit = e;
				if (hit >= 0)
				{
					enemies.splice(hit, 1);
					bullets.splice(i, 1);
					Audio.play("kill", 0.7);
				}
			}
			else if (cx == px && cy == py)
			{
				bullets.splice(i, 1);
				lives--;
				Audio.play("hurt", 0.6);
				if (lives <= 0)
				{
					msg.text = "TANK DESTROYED: RESTARTING";
					retryT = 1.2;
				}
			}
		}
	}

	function enemiesAct(dt:Float):Void
	{
		for (e in enemies)
		{
			e.t -= dt;
			e.s -= dt;
			if (e.t <= 0)
			{
				e.t = 0.45;
				var d = e.d;
				if (Math.random() < 0.55)
				{
					var ddx = px - e.x, ddy = py - e.y;
					d = Math.abs(ddy) >= Math.abs(ddx) ? (ddy > 0 ? 2 : 0) : (ddx > 0 ? 1 : 3);
				}
				else if (Math.random() < 0.5)
					d = Std.random(4);
				e.d = d;
				if (freeCell(e.x + dx(d), e.y + dy(d)))
				{
					e.x += dx(d);
					e.y += dy(d);
				}
			}
			if (e.s <= 0)
			{
				var aligned = e.x == px || e.y == py;
				e.s = aligned ? 0.9 + Math.random() * 0.6 : 1.4 + Math.random() * 1.6;
				if (aligned)
					e.d = e.x == px ? (py > e.y ? 2 : 0) : (px > e.x ? 1 : 3);
				bullets.push({x: e.x + dx(e.d) * 0.6, y: e.y + dy(e.d) * 0.6, d: e.d, own: false});
			}
		}
	}

	function tank(bd:openfl.display.BitmapData, x:Int, y:Int, d:Int, color:Int):Void
	{
		var ox = x * CS, oy = y * CS;
		bd.fillRect(new Rectangle(ox + 4, oy + 4, CS - 8, CS - 8), color);
		var bx = ox + CS / 2 - 2, by = oy + CS / 2 - 2;
		switch (d)
		{
			case 0:
				bd.fillRect(new Rectangle(bx, oy, 4, CS / 2), color);
			case 1:
				bd.fillRect(new Rectangle(ox + CS / 2, by, CS / 2, 4), color);
			case 2:
				bd.fillRect(new Rectangle(bx, oy + CS / 2, 4, CS / 2), color);
			default:
				bd.fillRect(new Rectangle(ox, by, CS / 2, 4), color);
		}
	}

	function render():Void
	{
		var bd = canvas.pixels;
		bd.lock();
		bd.fillRect(new Rectangle(0, 0, W * CS, HH * CS), 0xFF050505);
		for (i in 0...(W * HH))
			if (walls[i])
				bd.fillRect(new Rectangle((i % W) * CS + 1, Std.int(i / W) * CS + 1, CS - 2, CS - 2), 0xFF777777);
		for (e in enemies)
			tank(bd, e.x, e.y, e.d, 0xFF999999);
		tank(bd, px, py, pd, 0xFFFFFFFF);
		for (b in bullets)
			bd.fillRect(new Rectangle(b.x * CS + CS / 2 - 2, b.y * CS + CS / 2 - 2, 4, 4), b.own ? 0xFFFFFFFF : 0xFFBBBBBB);
		bd.unlock();
		canvas.dirty = true;
	}
}
