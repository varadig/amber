package;

import box2D.collision.shapes.B2PolygonShape;
import box2D.common.math.B2Vec2;
import box2D.dynamics.B2Body;
import box2D.dynamics.B2BodyDef;
import box2D.dynamics.B2FixtureDef;
import box2D.dynamics.B2World;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import openfl.display.BitmapData;
import openfl.geom.Point;
import openfl.geom.Rectangle;

/**
 * Leomló fal: a fal-csempék (kapuk, repedezett falak) Box2D-vel szétesnek (haxelib box2d). Minden csempe 4 különböző méretű,
 * a csempe képéből kivágott darabra törik; a darabok forognak, pattognak, egymáson és a talajon megállnak, ~5 mp múlva
 * elhalványulnak és törlődnek (csak látvány: a robotokkal nem ütköznek). A pálya szilárd csempéiből a fal környékén
 * statikus testek készülnek (csak a felszíniek).
 */
class Rubble extends FlxTypedGroup<FlxSprite>
{
	/** Pixel / méter: egy 16 px-es csempe 1 méter (a Box2D 0,1..10 m-es testekre van hangolva). */
	static inline var PPM = 16.0;

	var world:B2World;
	var level:LevelData;
	/** age: a darab kora; fade: ekkortól halványul el (FADE alatt), utána a test és a kép is törlődik. */
	var pieces:Array<{body:B2Body, spr:FlxSprite, w:Float, h:Float, age:Float, fade:Float}> = [];

	static inline var FADE = 0.8;
	var statics:Map<Int, Bool> = new Map();
	/** Ennyi ideje nem mozdult egyik darab sem: utána a szimuláció leáll (nincs fölösleges számolás). */
	var restT:Float = 0;

	public function new(level:LevelData)
	{
		super();
		this.level = level;
		world = new B2World(new B2Vec2(0, 28), true);
	}

	/** A pálya szilárd csempéi a megadott tartományban statikus testként (csak azok, amelyeknek van szabad szomszédja). */
	function addStatics(tx0:Int, ty0:Int, tx1:Int, ty1:Int):Void
	{
		for (ty in ty0...ty1 + 1)
			for (tx in tx0...tx1 + 1)
			{
				if (tx < 0 || ty < 0 || tx >= level.w || ty >= LevelData.H || !level.isSolid(tx, ty))
					continue;
				var key = ty * 100000 + tx;
				if (statics.exists(key))
					continue;
				if (level.isSolid(tx - 1, ty) && level.isSolid(tx + 1, ty) && level.isSolid(tx, ty - 1) && level.isSolid(tx, ty + 1))
					continue;
				statics.set(key, true);
				var bd = new B2BodyDef();
				bd.type = STATIC_BODY;
				bd.position = new B2Vec2(tx + 0.5, ty + 0.5);
				var b = world.createBody(bd);
				var sh = new B2PolygonShape();
				sh.setAsBox(0.5, 0.5);
				var fd = new B2FixtureDef();
				fd.shape = sh;
				fd.friction = 0.8;
				b.createFixture(fd);
			}
	}

	/**
		Egy 16x16-os fal-csempe szétesése: (px, py) a csempe bal felső sarka, bmp a csempe képe, dir a lökés iránya (-1 / 1).
		A darabok a csempe képéből vágott, változó méretű téglalapok (két oszlop, oszloponként eltérő vágással).
	**/
	public function shatter(px:Float, py:Float, bmp:BitmapData, dir:Float):Void
	{
		var tx = Std.int(px / PPM);
		var ty = Std.int(py / PPM);
		// a széteső csempe helyén sosem lehet statikus test (a darabok benne születnének)
		statics.set(ty * 100000 + tx, true);
		addStatics(tx - 10, ty - 6, tx + 10, ty + 10);
		var cx = 5 + Std.random(7);
		var rects = [];
		for (col in 0...2)
		{
			var x0 = col == 0 ? 0 : cx;
			var w = col == 0 ? cx : 16 - cx;
			var cy = 4 + Std.random(9);
			rects.push(new Rectangle(x0, 0, w, cy));
			rects.push(new Rectangle(x0, cy, w, 16 - cy));
		}
		for (r in rects)
		{
			var pb = new BitmapData(Std.int(r.width), Std.int(r.height), true, 0);
			pb.copyPixels(bmp, r, new Point(0, 0));
			var s = new FlxSprite(px + r.x, py + r.y);
			s.loadGraphic(pb);
			s.solid = false;
			s.moves = false;
			add(s);
			var bd = new B2BodyDef();
			bd.type = DYNAMIC_BODY;
			bd.position = new B2Vec2((px + r.x + r.width / 2) / PPM, (py + r.y + r.height / 2) / PPM);
			bd.angularDamping = 0.4;
			var b = world.createBody(bd);
			// a fizikai test kicsit kisebb a képnél: így a darabok között rés van, és egy csempényi járatban (alagút) sem szorulnak be
			var sh = new B2PolygonShape();
			sh.setAsBox(r.width / 2 / PPM * 0.82, r.height / 2 / PPM * 0.82);
			var fd = new B2FixtureDef();
			fd.shape = sh;
			fd.density = 1.0;
			fd.friction = 0.45;
			fd.restitution = 0.25;
			b.createFixture(fd);
			// lökés: a láda felőli oldalról el, kicsit felfelé; a felső darabok messzebb repülnek
			var up = 1 - (py + r.y) / (py + 96);
			b.setLinearVelocity(new B2Vec2(dir * (1.0 + Math.random() * 3.5), -(1.5 + Math.random() * 4.5) * Math.max(0.4, up)));
			b.setAngularVelocity((Math.random() - 0.5) * 14);
			// a darabok kicsit eltérő időben tűnnek el (ne egyszerre)
			pieces.push({body: b, spr: s, w: r.width, h: r.height, age: 0, fade: 4.5 + Math.random() * 1.5});
		}
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (pieces.length == 0)
			return;
		world.step(Math.min(elapsed, 1 / 30), 8, 3);
		world.clearForces();
		var i = pieces.length;
		while (i-- > 0)
		{
			var p = pieces[i];
			p.age += elapsed;
			var pos = p.body.getPosition();
			p.spr.x = pos.x * PPM - p.w / 2;
			p.spr.y = pos.y * PPM - p.h / 2;
			p.spr.angle = p.body.getAngle() * 180 / Math.PI;
			if (p.age > p.fade)
				p.spr.alpha = Math.max(0, 1 - (p.age - p.fade) / FADE);
			// elhalványult (vagy a pálya alá esett) darab: a test és a kép is törlődik
			if (p.age > p.fade + FADE || pos.y > LevelData.H + 2)
			{
				world.destroyBody(p.body);
				remove(p.spr, true);
				p.spr.destroy();
				pieces.splice(i, 1);
			}
		}
	}

	/** Teszthez: hány darab mozog még. */
	public function awakeCount():Int
	{
		var n = 0;
		for (p in pieces)
			if (p.body.isAwake())
				n++;
		return n;
	}

	public function count():Int
		return pieces.length;
}
