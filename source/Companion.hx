package;

import flixel.FlxSprite;
import flixel.util.FlxDirectionFlags;

/**
 * Egy társ-robot. Módok: 0 követ, 1 áll (a helyén marad), 2 elküldve (egy irányba halad, amíg el nem akad, vagy el nem éri a távolságot).
 * A `command` vált: követő társnál irányt tartva elküldi, irány nélkül megállítja; álló / elküldött társat visszahív.
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
		maxVelocity.set(160, 360);
	}

	/** Parancs: irány nélkül áll / követ (váltás); iránnyal elküldi. */
	public function command(dx:Int, dy:Int):Void
	{
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

	override public function update(elapsed:Float):Void
	{
		bobT += elapsed;
		var t = touching;
		var onFloor = t.has(FlxDirectionFlags.FLOOR);
		var hitWall = t.has(FlxDirectionFlags.LEFT) || t.has(FlxDirectionFlags.RIGHT);
		var tx = target.x + target.width / 2;
		var ty = target.y + target.height / 2;

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
			var spd = kind == Companions.TALL ? 70.0 : 92.0;
			switch (mode)
			{
				case 0:
					var dx = tx - (x + width / 2);
					var near = kind == Companions.TALL ? 30.0 : 22.0;
					velocity.x = Math.abs(dx) > near ? (dx > 0 ? spd : -spd) : 0;
					if (velocity.x != 0)
						face = velocity.x > 0 ? 1 : -1;
					if (onFloor && (hitWall || (ty < y - 26 && Math.abs(dx) < 56)) && kind != Companions.TALL)
						velocity.y = -270;
					if (Math.abs(dx) > 300 || Math.abs(ty - y) > 200)
						reset(tx - face * 18, ty - 10);
					setSolidRole(false);
				case 1:
					velocity.x = 0;
					setSolidRole(true);
				default:
					velocity.x = sendX * 110;
					face = sendX;
					var ahead = Std.int((x + width / 2 + sendX * (width / 2 + 3)) / LevelData.T);
					var foot = Std.int((y + height + 2) / LevelData.T);
					if (hitWall || (onFloor && !level.isStandable(ahead, foot)) || Math.abs(x - sendFrom) > 380)
						mode = 1;
					setSolidRole(false);
			}
		}
		flipX = face < 0;
		super.update(elapsed);
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
