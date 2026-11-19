package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxText;

/**
 * Alkatrész-bemutató: egy alkatrész felvétele után a sarokban egy kis "képernyő" játssza le (hurokban), mire jó az új képesség
 * (ugrás a szakadék fölött, karmos falmászás, szökellés az ellenségbe, falbontó lövés, radar-pásztázás, repülés...).
 * A hős a valódi, aktuális kinézetével (Art.player) szerepel, a díszlet sima téglalapokból áll. A HUD-rétegre kerül (PlayState.startShowcase).
 * Színek: a szürke-lépcsők, a borostyán árnyalatot a kamera-shader adja.
 */
class Showcase extends FlxGroup
{
	static inline var SW = 120;
	static inline var SH = 64;
	static inline var LOOP = 3.6;
	static inline var FLOOR = 56;
	/** A futás képkockái (Art.player: 1-4 és 11-12). */
	static final RUN = [1, 2, 3, 4, 11, 12];

	var id:Int;
	var sx:Float;
	var sy:Float;
	var t:Float = 0;
	var delay:Float;
	var life:Float;
	/** Átlátszóság-szorzó (be- és kiúszás). */
	var ga:Float = 0;
	var rects:Array<FlxSprite> = [];
	var nr:Int = 0;
	var hero:FlxSprite;
	var ghosts:Array<FlxSprite> = [];
	var enemy:FlxSprite;
	var heart:FlxSprite;
	var icon:FlxSprite;
	var ring:FlxSprite;
	var sweep:FlxSprite;
	var caption:FlxText;

	public function new(id:Int, tier:Int, delay:Float = 2.0)
	{
		super();
		this.id = id;
		this.delay = delay;
		life = LOOP * 2 + 0.6;
		sx = 480 - SW - 18;
		sy = 22;
		for (i in 0...70)
		{
			var r = new FlxSprite(0, 0);
			r.makeGraphic(1, 1, 0xFFFFFFFF);
			r.origin.set(0, 0);
			r.scrollFactor.set(0, 0);
			r.visible = false;
			add(r);
			rects.push(r);
		}
		hero = makeHero();
		for (i in 0...3)
			ghosts.push(makeHero());
		if (id == 3)
		{
			enemy = new FlxSprite(0, 0);
			enemy.loadGraphic(Art.crawler(), true, 14, 10, false, "crawler");
			enemy.origin.set(0, 0);
			enemy.scale.set(2, 2);
			enemy.scrollFactor.set(0, 0);
			add(enemy);
		}
		if (id == 1)
		{
			heart = new FlxSprite(0, 0);
			heart.loadGraphic(Art.heart(), false, 8, 8, false, "heart");
			heart.origin.set(0, 0);
			heart.scrollFactor.set(0, 0);
			add(heart);
		}
		if (id == 7)
		{
			icon = new FlxSprite(0, 0);
			icon.loadGraphic(Art.partIcons(), true, 10, 10, false, "parts");
			icon.animation.frameIndex = Parts.GEAR;
			icon.scale.set(2, 2);
			icon.scrollFactor.set(0, 0);
			add(icon);
		}
		if (id == 8)
		{
			ring = new FlxSprite(sx + 30, sy + 2);
			ring.makeGraphic(61, 61, 0x00000000, true);
			for (dy in 0...61)
				for (dx in 0...61)
				{
					var d = Math.sqrt((dx - 30) * (dx - 30) + (dy - 30) * (dy - 30));
					if ((d > 29 && d <= 30) || (d > 14.5 && d <= 15.5 && (dx + dy) % 2 == 0) || ((dx == 30 || dy == 30) && d < 30 && (dx + dy) % 3 == 0))
						ring.pixels.setPixel32(dx, dy, 0xFF777777);
				}
			ring.dirty = true;
			ring.scrollFactor.set(0, 0);
			add(ring);
			sweep = new FlxSprite(sx + 60, sy + 32);
			sweep.makeGraphic(30, 1, 0xFFFFFFFF);
			sweep.origin.set(0, 0);
			sweep.scrollFactor.set(0, 0);
			add(sweep);
		}
		var name = Parts.NAMES[id];
		var info = tier >= 2 ? "UPGRADED: " + Parts.upInfo(id, tier) : Parts.INFO[id];
		caption = new LangText(sx - 12, sy + SH + 3, SW + 24, name + "\n" + info, 8);
		caption.setFormat(null, 8, 0xFFFFFFFF, CENTER);
		caption.scrollFactor.set(0, 0);
		add(caption);
		visible = false;
	}

	function makeHero():FlxSprite
	{
		var h = new FlxSprite(0, 0);
		var m = Parts.mask();
		h.loadGraphic(Art.player(m), true, 12, 14, false, "player" + m);
		h.origin.set(0, 0);
		h.scale.set(2, 2);
		h.scrollFactor.set(0, 0);
		h.visible = false;
		add(h);
		return h;
	}

	// --- rajz-segédek (a színpad koordinátái: 0..119 x 0..63) ---

	function rc(x:Float, y:Float, w:Float, h:Float, c:Int, a:Float = 1):Void
	{
		if (nr >= rects.length)
			return;
		var r = rects[nr++];
		r.visible = true;
		r.x = sx + x;
		r.y = sy + y;
		r.scale.set(w, h);
		r.color = c;
		r.alpha = a * ga;
	}

	function place(s:FlxSprite, x:Float, y:Float, f:Int, flip:Bool = false, a:Float = 1):Void
	{
		s.visible = true;
		s.x = sx + x;
		s.y = sy + y;
		s.animation.frameIndex = f;
		s.flipX = flip;
		s.alpha = a * ga;
	}

	function floorRect(x0:Float, x1:Float):Void
	{
		rc(x0, FLOOR, x1 - x0, SH - FLOOR, 0xFF444444);
		rc(x0, FLOOR, x1 - x0, 1, 0xFFBBBBBB);
	}

	static inline function seg(p:Float, a:Float, b:Float):Float
		return p <= a ? 0 : (p >= b ? 1 : (p - a) / (b - a));

	static inline function lerp(a:Float, b:Float, u:Float):Float
		return a + (b - a) * u;

	/** Parabola-ív: 0 → h → 0, u = 0..1. */
	static inline function arc(u:Float, h:Float):Float
		return 4 * h * u * (1 - u);

	inline function runFrame():Int
		return RUN[Std.int(t * 14) % 6];

	function sparks(cx:Float, cy:Float, p:Float, n:Int = 8):Void
	{
		for (i in 0...n)
		{
			var a = i * Math.PI * 2 / n;
			var d = 3 + 16 * p;
			rc(cx + Math.cos(a) * d - 1, cy + Math.sin(a) * d - 1, 2, 2, 0xFFFFFFFF, 1 - p);
		}
	}

	// --- a jelenetek ---

	function scene(p:Float):Void
	{
		var hy = FLOOR - 28; // a földön álló hős tetejének y-ja
		switch (id)
		{
			case Parts.LEGS: // futás és ugrás a szakadék fölött
				floorRect(0, 46);
				floorRect(76, SW);
				for (k in 0...6)
					rc(48 + k * 5, 60, 3, 3, 0xFF777777); // tüskék a mélyben
				if (p < 0.3)
					place(hero, lerp(4, 36, seg(p, 0, 0.3)), hy, runFrame());
				else if (p < 0.75)
				{
					var u = seg(p, 0.3, 0.75);
					place(hero, lerp(36, 84, u), hy - arc(u, 22), u < 0.5 ? 5 : 6);
				}
				else
					place(hero, lerp(84, 94, seg(p, 0.75, 1)), hy, runFrame());
			case Parts.CORE: // +1 szív
				floorRect(0, SW);
				var pop = seg(p, 0.25, 0.5);
				place(hero, 48, hy, 0, false, p > 0.25 && p < 0.7 && Std.int(p * 20) % 2 == 0 ? 0.5 : 1);
				// két meglévő szív (kis négyzetek), a harmadik kipattan a hős mellkasából
				rc(36, 11, 8, 7, 0xFFBBBBBB);
				rc(48, 11, 8, 7, 0xFFBBBBBB);
				var s = pop <= 0 ? 0.0 : 2.0 * pop + 0.8 * Math.sin(pop * Math.PI);
				heart.visible = pop > 0;
				heart.scale.set(s, s);
				heart.x = sx + 68 - 4 * s;
				heart.y = sy + 14 - 4 * s;
				heart.alpha = ga;
				if (pop > 0 && pop < 1)
					sparks(68, 14, pop, 10);
			case Parts.VISOR: // a pásztázó fény felfedi a rejtett dolgokat
				floorRect(0, SW);
				var bx = lerp(24, 118, seg(p, 0.12, 0.85));
				var objs = [[38.0, 40.0, 26.0, 3.0], [72.0, 30.0, 22.0, 3.0], [64.0, 52.0, 8.0, 4.0], [100.0, 22.0, 14.0, 3.0]];
				for (o in objs)
					rc(o[0], o[1], o[2], o[3], 0xFFBBBBBB, o[0] < bx ? 1 : 0.15);
				rc(bx, 0, 2, FLOOR, 0xFFFFFFFF, p > 0.1 && p < 0.9 ? 0.9 : 0);
				rc(bx - 6, 0, 6, FLOOR, 0xFFFFFFFF, p > 0.1 && p < 0.9 ? 0.2 : 0);
				place(hero, 6, hy, 0);
			case Parts.THRUSTER: // szökellés az ellenségbe
				floorRect(0, SW);
				var hit = p >= 0.43;
				var hx = p < 0.3 ? 6.0 : (p < 0.43 ? lerp(6, 74, seg(p, 0.3, 0.43)) : lerp(74, 96, seg(p, 0.43, 0.7)));
				if (!hit || p > 0.9)
				{
					enemy.visible = true;
					enemy.x = sx + 84;
					enemy.y = sy + FLOOR - 20;
					enemy.animation.frameIndex = 0;
					enemy.alpha = ga * (p > 0.9 ? (p - 0.9) * 10 : 1);
				}
				else
					enemy.visible = false;
				if (p >= 0.3 && p < 0.43)
					for (k in 0...3)
						place(ghosts[k], hx - (k + 1) * 9, hy, 8, false, 0.45 - k * 0.12);
				place(hero, hx, hy, p >= 0.3 && p < 0.43 ? 8 : 0);
				if (hit && p < 0.65)
					sparks(88, FLOOR - 10, seg(p, 0.43, 0.65), 10);
				if (p >= 0.3 && p < 0.34)
					rc(0, 0, SW, SH, 0xFFFFFFFF, 0.12);
			case Parts.CLAWS: // fal-ugrással felfelé a szűk aknában
				rc(0, 0, 14, SH, 0xFF444444);
				rc(13, 0, 1, SH, 0xFFBBBBBB);
				rc(106, 0, 14, SH, 0xFF444444);
				rc(106, 0, 1, SH, 0xFFBBBBBB);
				rc(14, FLOOR, 92, SH - FLOOR, 0xFF444444);
				rc(14, FLOOR, 92, 1, 0xFFBBBBBB);
				if (p < 0.12)
					place(hero, 14, hy, 0);
				else if (p < 0.4)
				{
					var u = seg(p, 0.12, 0.4);
					place(hero, lerp(14, 82, u), lerp(hy, 14, u) - arc(u, 8), u < 0.5 ? 5 : 6);
				}
				else if (p < 0.55)
					place(hero, 82, 14 + seg(p, 0.4, 0.55) * 4, 7, false);
				else if (p < 0.8)
				{
					var u = seg(p, 0.55, 0.8);
					place(hero, lerp(82, 14, u), lerp(18, 2, u) - arc(u, 8), u < 0.5 ? 5 : 6, true);
				}
				else
					place(hero, 14, 2 + seg(p, 0.8, 1) * 3, 7, true);
			case Parts.BLASTER: // lövés a repedezett falra
				floorRect(0, SW);
				var shots = [0.12, 0.27, 0.42];
				var bricks = 0;
				for (i in 0...3)
				{
					var ts = shots[i];
					var alive = p < ts + 0.12 || p > 0.97;
					if (alive)
					{
						rc(84, 24 + i * 11, 16, 10, 0xFF777777);
						rc(84, 24 + i * 11, 16, 1, 0xFFBBBBBB);
						rc(90, 26 + i * 11, 1, 5, 0xFF0A0A0A); // repedés
					}
					if (p >= ts && p < ts + 0.12)
					{
						var u = seg(p, ts, ts + 0.12);
						rc(lerp(34, 82, u), 40, 5, 2, 0xFFFFFFFF);
						if (u < 0.3)
							rc(32, 38, 4, 5, 0xFFFFFFFF, 0.8);
					}
					if (p >= ts + 0.12 && p < ts + 0.24)
						sparks(90, 29 + i * 11, seg(p, ts + 0.12, ts + 0.24), 6);
				}
				var recoil = 0.0;
				for (ts in shots)
					if (p >= ts && p < ts + 0.04)
						recoil = -2;
				if (p < 0.6)
					place(hero, 8 + recoil, hy, 0);
				else if (p < 0.95)
					place(hero, lerp(8, 98, seg(p, 0.6, 0.95)), hy, runFrame());
				else
					place(hero, 8, hy, 0);
			case Parts.CHIP: // azonnali irányváltás
				floorRect(0, SW);
				var q = Std.int(p * 4) % 4;
				var u = (p * 4) % 1;
				var right = q % 2 == 0;
				var hx = right ? lerp(20, 84, u) : lerp(84, 20, u);
				place(hero, hx, hy, runFrame(), !right);
				rc(6, 6, 12, 12, right ? 0xFF444444 : 0xFFFFFFFF);
				rc(22, 6, 12, 12, right ? 0xFFFFFFFF : 0xFF444444);
				rc(9, 11, 6, 2, right ? 0xFF777777 : 0xFF0A0A0A);
				rc(25, 11, 6, 2, right ? 0xFF0A0A0A : 0xFF777777);
			case Parts.GEAR: // légi irányítás és rugós pattanás
				floorRect(0, SW);
				rc(38, FLOOR - 4, 14, 4, 0xFFBBBBBB);
				if (p < 0.05)
					place(hero, 10, hy, 0);
				else if (p < 0.45)
				{
					var u = seg(p, 0.05, 0.45);
					var x = u < 0.5 ? lerp(10, 62, u * 2) : lerp(62, 44, (u - 0.5) * 2);
					place(hero, x, hy - arc(u, 24), u < 0.5 ? 5 : 6);
					icon.visible = true;
					icon.x = sx + x + 2;
					icon.y = sy + hy - arc(u, 24) - 22;
					icon.angle = t * 240;
					icon.alpha = ga;
					if (u > 0.4 && u < 0.7)
						rc(x - 6, hy + 10, 4, 2, 0xFFFFFFFF); // a levegőben átirányít: oldalfúvóka
				}
				else if (p < 0.95)
				{
					var u = seg(p, 0.45, 0.95);
					place(hero, lerp(44, 50, u), hy - arc(u, 36), u < 0.5 ? 5 : 6);
					if (u < 0.15)
						sparks(45, FLOOR - 3, u / 0.15, 6);
				}
				else
					place(hero, 50, hy, 0);
			case Parts.ANTENNA: // radar
				var ang = (p * 360 * 1.0) % 360;
				sweep.visible = true;
				ring.visible = true;
				sweep.angle = ang - 90;
				sweep.alpha = ga;
				ring.alpha = ga;
				rc(59, 31, 3, 3, 0xFFFFFFFF);
				var blips = [[40.0, 18.0], [150.0, 24.0], [230.0, 12.0], [310.0, 22.0]];
				for (b in blips)
				{
					var rad = (b[0] - 90) * Math.PI / 180;
					var since = (ang - b[0] + 360) % 360;
					rc(60 + Math.cos(rad) * b[1] - 1, 32 + Math.sin(rad) * b[1] - 1, 3, 3, 0xFFFFFFFF, Math.max(0.1, 1 - since / 200));
				}
			case Parts.JET: // repülés a magas fal fölött
				floorRect(0, SW);
				rc(56, 14, 14, FLOOR - 14, 0xFF444444);
				rc(56, 14, 14, 1, 0xFFBBBBBB);
				var x:Float;
				var y:Float;
				var f = 0;
				if (p < 0.15)
				{
					x = 10;
					y = hy;
				}
				else if (p < 0.4)
				{
					var u = seg(p, 0.15, 0.4);
					x = lerp(10, 40, u);
					y = lerp(hy, 2, u);
					f = 5;
				}
				else if (p < 0.65)
				{
					var u = seg(p, 0.4, 0.65);
					x = lerp(40, 84, u);
					y = 2 + Math.sin(u * 9) * 2;
					f = 5;
				}
				else if (p < 0.85)
				{
					var u = seg(p, 0.65, 0.85);
					x = lerp(84, 94, u);
					y = lerp(2, hy, u);
					f = 6;
				}
				else
				{
					x = 94;
					y = hy;
				}
				place(hero, x, y, f);
				if (f != 0 && p < 0.85)
				{
					var fl = 3 + Std.int(Math.random() * 4);
					rc(x + 8, y + 28, 3, fl, 0xFFFFFFFF, 0.9);
					rc(x + 13, y + 28, 3, fl + 2, 0xFFBBBBBB, 0.8);
				}
			default:
		}
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		t += elapsed;
		var lt = t - delay;
		if (lt < 0)
		{
			visible = false;
			return;
		}
		if (lt > life)
		{
			kill();
			return;
		}
		visible = true;
		ga = Math.min(1, Math.min(lt / 0.3, (life - lt) / 0.5));
		for (i in 0...nr)
			rects[i].visible = false;
		nr = 0;
		hero.visible = false;
		for (g in ghosts)
			g.visible = false;
		if (enemy != null)
			enemy.visible = false;
		if (heart != null)
			heart.visible = false;
		if (icon != null)
			icon.visible = false;
		if (sweep != null)
		{
			sweep.visible = false;
			ring.visible = false;
		}
		// háttér és keret
		rc(-2, -2, SW + 4, SH + 4, 0xFF777777);
		rc(0, 0, SW, SH, 0xFF0A0A0A);
		scene((lt % LOOP) / LOOP);
		caption.alpha = ga;
	}
}
