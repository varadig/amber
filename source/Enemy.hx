package;

import flixel.util.FlxDirectionFlags;
import flixel.FlxSprite;

/**
 * Ellenségek: WALKER (a talajon őrjárat, a szakadék szélén megfordul, rálépéssel legyőzhető), FLYER (hullámzó repülés, rálépéssel legyőzhető),
 * CRAWLER (tüskés hátú: nem lehet rálépni, csak szökellés / dash tudja kiütni).
 */
class Enemy extends FlxSprite
{
	public var kind:Int;
	public var stompable(get, never):Bool;
	public var dying:Float = -1;

	var level:LevelData;
	var dir:Int = -1;
	var baseY:Float;
	var t:Float = 0;
	var range:Float;
	var originX:Float;

	function get_stompable():Bool
		return kind != LevelData.CRAWLER;

	public function new(kind:Int, x:Float, y:Float, level:LevelData)
	{
		super(x, y);
		this.kind = kind;
		this.level = level;
		baseY = y;
		originX = x;
		range = 44;
		switch (kind)
		{
			case LevelData.FLYER:
				loadGraphic(Art.flyer(), true, 14, 8, false, "flyer");
				animation.add("fly", [0, 1], 6);
				animation.play("fly");
				width = 12;
				height = 7;
				offset.set(1, 1);
				immovable = true;
			case LevelData.CRAWLER:
				loadGraphic(Art.crawler(), true, 14, 10, false, "crawler");
				animation.add("walk", [0, 1], 4);
				animation.play("walk");
				width = 12;
				height = 8;
				offset.set(1, 2);
				acceleration.y = 900;
			default:
				loadGraphic(Art.walker(), true, 14, 10, false, "walker");
				animation.add("walk", [0, 1], 5);
				animation.add("dead", [2], 1);
				animation.play("walk");
				width = 12;
				height = 8;
				offset.set(1, 2);
				acceleration.y = 900;
		}
		if (kind != LevelData.FLYER)
			y -= 0; // a PlayState a talajra helyezi (a spawn y a talajon)
		t = Math.random() * 6;
		dir = Math.random() < 0.5 ? -1 : 1;
	}

	override public function update(elapsed:Float):Void
	{
		if (dying >= 0)
		{
			dying += elapsed;
			velocity.x = 0;
			if (dying > 0.35)
				kill();
			super.update(elapsed);
			return;
		}
		t += elapsed;
		var blockedBefore = touching;
		switch (kind)
		{
			case LevelData.FLYER:
				velocity.x = 0;
				x = originX + Math.sin(t * 0.9) * range;
				y = baseY + Math.sin(t * 2.3) * 7;
				flipX = Math.cos(t * 0.9) < 0;
			default:
				var speed = kind == LevelData.CRAWLER ? 22.0 : 34.0;
				// fal vagy szakadék előtt megfordul
				var hitWall = (dir < 0 && blockedBefore.has(FlxDirectionFlags.LEFT)) || (dir > 0 && blockedBefore.has(FlxDirectionFlags.RIGHT));
				var onGround = blockedBefore.has(FlxDirectionFlags.FLOOR);
				if (onGround)
				{
					var ahead = Std.int((x + width / 2 + dir * (width / 2 + 3)) / LevelData.T);
					var footRow = Std.int((y + height + 2) / LevelData.T);
					if (hitWall || !level.isStandable(ahead, footRow))
						dir = -dir;
				}
				velocity.x = dir * speed;
				flipX = dir > 0;
		}
		super.update(elapsed);
	}

	/** Legyőzés: lelapul (walker) vagy azonnal eltűnik. */
	public function defeat():Void
	{
		dying = 0;
		velocity.set(0, 0);
		if (kind == LevelData.WALKER)
		{
			animation.play("dead");
			y += 3;
		}
		else
			kill();
		solid = false;
		moves = false;
	}
}
