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
	/** Látás-köd (0..1): a VISOR tiszta körén kívül láthatatlan, az átmeneti sávban halványul (PlayState.updateFog). */
	public var fog:Float = 1;

	override public function draw():Void
	{
		if (fog >= 0.999)
		{
			super.draw();
			return;
		}
		if (fog <= 0.01)
			return;
		var a = alpha;
		alpha = a * fog;
		super.draw();
		alpha = a;
	}

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
			case LevelData.HUNTER:
				loadGraphic(Art.hunter(), true, 14, 12, false, "hunter");
				animation.add("walk", [0, 1], 5);
				animation.add("alert", [2], 1);
				animation.add("dead", [3], 1);
				animation.play("walk");
				width = 10;
				height = 11;
				offset.set(2, 1);
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
			case LevelData.HUNTER:
				updateHunter(elapsed, blockedBefore);
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

	/** A célpont (az éppen irányított robot): a PlayState állítja minden képkockán; az üldöző ezt követi. */
	public static var chase:FlxSprite = null;

	var hState:Int = 0;
	var hT:Float = 0;
	var alertCd:Float = 0;

	/**
	 * HUNTER: őrjárat; ha a célpont ~120 px-en belül és közel egy szinten van, riadó (megáll, a szeme tágra nyílik), majd rárohan (gyors, az
	 * alacsony falat átugorja); szakadék szélén megáll, és ha a célpont elszakad (190 px) vagy 6 mp telik el, feladja és újra őrjáratozik.
	 */
	function updateHunter(elapsed:Float, touch:FlxDirectionFlags):Void
	{
		var onGround = touch.has(FlxDirectionFlags.FLOOR);
		var hitWall = (dir < 0 && touch.has(FlxDirectionFlags.LEFT)) || (dir > 0 && touch.has(FlxDirectionFlags.RIGHT));
		var tgt = chase;
		var dx = tgt != null ? (tgt.x + tgt.width / 2) - (x + width / 2) : 9999.0;
		var dy = tgt != null ? (tgt.y + tgt.height / 2) - (y + height / 2) : 9999.0;
		if (alertCd > 0)
			alertCd -= elapsed;
		var ahead = Std.int((x + width / 2 + dir * (width / 2 + 3)) / LevelData.T);
		var footRow = Std.int((y + height + 2) / LevelData.T);
		var ledge = onGround && !level.isStandable(ahead, footRow);
		switch (hState)
		{
			case 1:
				// riadó
				velocity.x = 0;
				dir = dx > 0 ? 1 : -1;
				hT -= elapsed;
				animation.play("alert");
				if (hT <= 0)
				{
					hState = 2;
					hT = 0;
				}
			case 2:
				// üldözés
				hT += elapsed;
				dir = dx > 0 ? 1 : -1;
				animation.play("walk");
				animation.timeScale = 2;
				if (ledge)
					velocity.x = 0;
				else
					velocity.x = dir * 80;
				if (onGround && hitWall)
					velocity.y = -200; // az alacsony falat átugorja
				if (Math.abs(dx) > 190 || Math.abs(dy) > 90 || hT > 6)
				{
					hState = 0;
					alertCd = 2.0;
				}
			default:
				// őrjárat (mint a WALKER)
				animation.play("walk");
				animation.timeScale = 1;
				if (onGround && (hitWall || ledge))
					dir = -dir;
				velocity.x = dir * 30;
				if (onGround && alertCd <= 0 && Math.abs(dx) < 120 && Math.abs(dy) < 36)
				{
					hState = 1;
					hT = 0.45;
					Audio.play("blip", 0.8);
				}
		}
		flipX = dir > 0;
	}

	/** Legyőzés: lelapul (walker) vagy azonnal eltűnik. */
	public function defeat():Void
	{
		dying = 0;
		velocity.set(0, 0);
		if (kind == LevelData.WALKER || kind == LevelData.HUNTER)
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
