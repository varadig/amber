package;

import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import flixel.util.FlxDirectionFlags;

/**
 * Egy társ-robot. Módok: 0 követ, 1 vár (a helyén marad), 2 elküldve (egy irányba halad, amíg el nem akad, vagy el nem éri a távolságot),
 * 3 az ajtóhoz megy és belép. A `command` vált: követő társnál irányt tartva elküldi, irány nélkül megállítja; álló / elküldött társat visszahív.
 *
 * Ügyes követés (a földön járóknál): előre néz a pályán: a falra / lépcsőre rááll vagy ráugrik (legfeljebb 3 csempe), a szakadékot átugorja
 * (ha átugorható), különben a peremen vár; lefelé csak akkor lép le, ha a hős lent van és lent talaj is van. Ha elakad, vagy leesett,
 * a hős mellé kerül ("beszáll" a hős mögé).
 */
class Companion extends FlxSprite
{
	public var kind:Int;
	public var mode:Int = 0;
	public var target:Player;
	var level:LevelData;
	var sendX:Int = 0;
	var sendY:Int = 0;
	var sendFrom:Float = 0;
	var bobT:Float = Math.random() * 6;
	var face:Int = 1;
	var stuckT:Float = 0;
	var doorX:Float = 0;
	var doorY:Float = 0;
	var enterT:Float = 0;
	var fading:Bool = false;

	public function new(kind:Int, x:Float, y:Float, level:LevelData, target:Player)
	{
		super(x, y);
		this.kind = kind;
		this.level = level;
		this.target = target;
		switch (kind)
		{
			case Companions.TALL:
				loadGraphic(Art.companion(kind), true, 10, 30, false, "comp" + kind);
				width = 8;
				height = 30;
				offset.set(1, 0);
			case Companions.ORB:
				loadGraphic(Art.companion(kind), true, 10, 10, false, "comp" + kind);
				width = 8;
				height = 8;
				offset.set(1, 1);
			default:
				loadGraphic(Art.companion(kind), true, 10, 10, false, "comp" + kind);
				width = 8;
				height = 9;
				offset.set(1, 1);
		}
		animation.add("a", [0, 1], kind == Companions.ORB ? 14 : 6);
		animation.play("a");
		allowCollisions = kind == Companions.ORB ? FlxDirectionFlags.NONE : FlxDirectionFlags.ANY;
		if (kind != Companions.ORB)
			acceleration.y = 900;
		maxVelocity.set(190, 360);
	}

	/** Parancs: irány nélkül áll / követ (váltás); iránnyal elküldi. */
	public function command(dx:Int, dy:Int):Void
	{
		if (mode == 3)
			return;
		if (mode == 0)
		{
			if (kind == Companions.ORB && dx == 0 && dy == 0)
				dy = -1;
			if (dx != 0 || dy != 0)
			{
				mode = 2;
				sendX = dx;
				sendY = kind == Companions.ORB ? dy : 0;
				sendFrom = sendY != 0 ? y : x;
			}
			else
				mode = 1;
		}
		else
			mode = 0;
	}

	public function setStay():Void
	{
		mode = 1;
	}

	/** Az ajtóhoz megy és belép (a pálya végén); `dx` az ajtó közepe, `dy` az ajtó alja. */
	public function enterDoor(dx:Float, dy:Float):Void
	{
		mode = 3;
		doorX = dx;
		doorY = dy;
		enterT = 0;
		setSolidRole(false);
	}

	override public function update(elapsed:Float):Void
	{
		if (fading)
		{
			super.update(elapsed);
			return;
		}
		bobT += elapsed;
		var t = touching;
		var onFloor = t.has(FlxDirectionFlags.FLOOR);
		var hitWall = t.has(FlxDirectionFlags.LEFT) || t.has(FlxDirectionFlags.RIGHT);
		var tx = target.x + target.width / 2;
		var ty = target.y + target.height / 2;
		var cx = x + width / 2;

		if (kind == Companions.ORB)
		{
			switch (mode)
			{
				case 0:
					var gx = tx - target.faceDir * 16 - 4;
					var gy = ty - 22 + Math.sin(bobT * 3) * 3;
					velocity.x = clamp((gx - x) * 4, 150);
					velocity.y = clamp((gy - y) * 4, 150);
					face = velocity.x >= 0 ? 1 : -1;
					if (Math.abs(tx - x) > 300 || Math.abs(ty - y) > 220)
						reset(tx - 16, ty - 24);
				case 1:
					velocity.x = 0;
					velocity.y = Math.cos(bobT * 3) * 4;
				case 3:
					enterT += elapsed;
					velocity.x = clamp((doorX - cx) * 4, 160);
					velocity.y = clamp((doorY - 12 - (y + 4)) * 4, 160);
					face = velocity.x >= 0 ? 1 : -1;
					if ((Math.abs(doorX - cx) < 5 && Math.abs(doorY - 12 - (y + 4)) < 6) || enterT > 3.5)
						beginFade();
				default:
					velocity.set(sendX * 130, sendY * 130);
					var ahead = level.isSolid(Std.int((x + 4 + sendX * 9) / LevelData.T), Std.int((y + 4 + sendY * 9) / LevelData.T));
					var dist = sendY != 0 ? Math.abs(y - sendFrom) : Math.abs(x - sendFrom);
					if (ahead || dist > 300)
						mode = 1;
			}
		}
		else
		{
			switch (mode)
			{
				case 0:
					walkToward(tx, kind == Companions.TALL ? 30 : 22, onFloor, hitWall, ty > y + height + 20);
					setSolidRole(false);
					// elakadás / lemaradás / leesés: a hős mellé kerül
					var dx = tx - cx;
					if (onFloor && Math.abs(dx) > 100 && Math.abs(velocity.x) < 4)
						stuckT += elapsed;
					else
						stuckT = 0;
					if (stuckT > 1.5 || Math.abs(dx) > 300 || ty < y - 130 || y > (level.killRow + 3) * LevelData.T && ty < (level.killRow + 2) * LevelData.T)
					{
						stuckT = 0;
						reset(tx - face * 18 - 4, ty - (kind == Companions.TALL ? 24 : 10));
						velocity.set(0, 0);
					}
				case 1:
					velocity.x = 0;
					setSolidRole(true);
				case 3:
					enterT += elapsed;
					walkToward(doorX, 3, onFloor, hitWall, true);
					if ((Math.abs(doorX - cx) < 6 && Math.abs(doorY - (y + height)) < 26) || enterT > 3.5)
						beginFade();
				default:
					velocity.x = sendX * 110;
					face = sendX;
					var ahead = Std.int((cx + sendX * (width / 2 + 3)) / LevelData.T);
					var foot = Std.int((y + height + 2) / LevelData.T);
					if (hitWall || (onFloor && !level.isStandable(ahead, foot)) || Math.abs(x - sendFrom) > 380)
						mode = 1;
					setSolidRole(false);
			}
		}
		flipX = face < 0;
		super.update(elapsed);
	}

	/** Belépés az ajtón: a társ beleolvad (elhalványul és összement). */
	function beginFade():Void
	{
		fading = true;
		velocity.set(0, 0);
		acceleration.set(0, 0);
		moves = false;
		if (kind != Companions.ORB)
			reset(doorX - width / 2, doorY - height);
		FlxTween.tween(this, {alpha: 0}, 0.4);
		FlxTween.tween(scale, {x: 0.2, y: 0.2}, 0.4, {onComplete: _ -> kill()});
	}

	/**
	 * A földön járó társ haladása a cél (gx) felé: lépcső / fal (≤ 3 csempe) ugrás, szakadék átugrás (ha átugorható), különben vár a peremen;
	 * lefelé csak akkor lép le, ha a cél lent van (wantDown) és lent talaj is van.
	 */
	function walkToward(gx:Float, near:Float, onFloor:Bool, hitWall:Bool, wantDown:Bool):Void
	{
		var cx = x + width / 2;
		var dx = gx - cx;
		var spd = kind == Companions.TALL ? 74.0 : 96.0;
		var jumpV = kind == Companions.TALL ? 250.0 : 300.0;
		var maxGap = kind == Companions.TALL ? 3 : 4;
		if (Math.abs(dx) <= near)
		{
			if (onFloor)
				velocity.x = 0;
			return;
		}
		var dir = dx > 0 ? 1 : -1;
		face = dir;
		if (!onFloor)
			return; // a levegőben megmarad a lendület
		var T = LevelData.T;
		var colAhead = Std.int((cx + dir * (width / 2 + 5)) / T);
		var footRow = Std.int((y + height + 2) / T);
		var bodyRow = Std.int((y + height - 5) / T);
		velocity.x = dir * spd;
		if (level.isSolid(colAhead, bodyRow))
		{
			// fal / lépcső: a tetejére ugrik, ha legfeljebb 3 csempe magas és fölötte szabad
			var h = 1;
			while (h <= 3 && level.isSolid(colAhead, bodyRow - h))
				h++;
			if (h <= 3 && !level.isSolid(colAhead, bodyRow - h - 1))
			{
				velocity.y = -jumpV;
				velocity.x = dir * spd * 1.2;
			}
			else
				velocity.x = 0;
			return;
		}
		if (!level.isStandable(colAhead, footRow))
		{
			// van-e talaj a közelben lent? (lelépés)
			var below = false;
			for (k in 1...7)
				if (level.isStandable(colAhead, footRow + k))
				{
					below = true;
					break;
				}
			if (below && wantDown)
				return; // lelép
			// átugorható-e a rés: talaj 1..maxGap+1 oszloppal odébb, hasonló magasságban
			var ok = false;
			for (k in 1...maxGap + 2)
			{
				var c = colAhead + dir * k;
				for (r in -2...3)
					if (level.isStandable(c, footRow + r) && !level.isSolid(c, footRow + r - 1) && !level.isSolid(c, footRow + r - 2))
						ok = true;
				if (ok)
					break;
			}
			if (ok)
			{
				velocity.y = -jumpV;
				velocity.x = dir * spd * 1.5;
			}
			else
				velocity.x = 0; // a peremen vár
		}
	}

	/** A magas társ álló helyzetben platform (a feje): a hős rá tud állni. */
	function setSolidRole(stand:Bool):Void
	{
		if (kind != Companions.TALL)
			return;
		if (stand)
		{
			acceleration.y = 0;
			velocity.y = 0;
			immovable = true;
			allowCollisions = FlxDirectionFlags.UP;
		}
		else
		{
			acceleration.y = 900;
			immovable = false;
			allowCollisions = FlxDirectionFlags.ANY;
		}
	}

	static inline function clamp(v:Float, m:Float):Float
		return v > m ? m : (v < -m ? -m : v);
}
