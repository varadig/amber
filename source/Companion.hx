package;

import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import flixel.util.FlxDirectionFlags;
import Puzzle;

/**
 * Egy társ-robot (a Lost Vikings mintájára: a három robot között váltani lehet, mindegyiket el kell juttatni az ajtóhoz).
 * Módok: 0 követ (a kiválasztott robotot követi), 1 vár (a helyén marad; a TALL ilyenkor platform), 3 az ajtóhoz megy és belép,
 * 4 irányított (a játékos vezérli: bal / jobb, ugrás; az ORB négy irányba lebeg).
 *
 * Ügyes követés (a földön járóknál): előre néz a pályán: a falra / lépcsőre (legfeljebb 3 csempe) rááll, a szakadékot átugorja
 * (ha átugorható), különben a peremen vár; lefelé csak akkor lép le, ha a cél lent van és lent talaj is van. Ha elakad, vagy leesett,
 * a célhoz kerül.
 */
class Companion extends FlxSprite
{
	public var kind:Int;
	public var mode:Int = 1;
	public var target:FlxSprite;
	public var face:Int = 1;
	public var exited:Bool = false;
	/** Mindegyik társnak saját élete van, és ugyanúgy sérül, mint a hős. */
	public var hearts:Int = 3;
	public var maxHearts:Int = 3;
	public var invuln:Float = 0;
	/** WHEELIE: turbó-gurulás hátralévő ideje (áttöri a repedezett falat, kiüti az ellenséget). */
	public var turboT:Float = 0;
	var specialCd:Float = 0;
	/** A különleges képesség gombja (X / Shift / V / J): a PlayState kezeli (WHEELIE turbó, TALL láda-emelés, ORB szikra). */
	public var onSpecial:Companion->Void;
	public var carrying:Crate = null;
	var level:LevelData;
	var bobT:Float = Math.random() * 6;
	var stuckT:Float = 0;
	var doorX:Float = 0;
	var doorY:Float = 0;
	var enterT:Float = 0;
	var fading:Bool = false;
	var coyote:Float = 0;
	var jumpBuf:Float = 0;

	public function new(kind:Int, x:Float, y:Float, level:LevelData, target:FlxSprite)
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
		allowCollisions = FlxDirectionFlags.ANY;
		if (kind != Companions.ORB)
			acceleration.y = 900;
		maxVelocity.set(190, 360);
	}

	/** Sérülés: elveszít egy szívet, rövid sérthetetlenség, hátralökődés. */
	public function takeHit(fromX:Float):Bool
	{
		if (invuln > 0 || turboT > 0 || mode == 3 || fading)
			return false;
		hearts--;
		invuln = 1.4;
		velocity.x = (x + width / 2 < fromX ? -1 : 1) * 130;
		if (kind != Companions.ORB)
			velocity.y = -180;
		return true;
	}

	public function enterDoor(dx:Float, dy:Float):Void
	{
		mode = 3;
		doorX = dx;
		doorY = dy;
		enterT = 0;
		setSolidRole(false);
	}

	function targetFace():Int
	{
		if (Std.isOfType(target, Player))
			return cast(target, Player).faceDir;
		if (Std.isOfType(target, Companion))
			return cast(target, Companion).face;
		return 1;
	}

	override public function update(elapsed:Float):Void
	{
		if (fading)
		{
			super.update(elapsed);
			return;
		}
		bobT += elapsed;
		if (invuln > 0)
		{
			invuln -= elapsed;
			visible = invuln <= 0 || Std.int(invuln * 18) % 2 == 0;
		}
		else
			visible = true;
		if (specialCd > 0)
			specialCd -= elapsed;
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
				case 4:
					// irányított: négy irányba lebeg
					var dx = (Input.right() ? 1 : 0) - (Input.left() ? 1 : 0);
					var dy = (Input.down() ? 1 : 0) - (Input.up() ? 1 : 0);
					velocity.x += (dx * 105 - velocity.x) * Math.min(1, 9 * elapsed);
					velocity.y += (dy * 105 - velocity.y) * Math.min(1, 9 * elapsed);
					if (dx != 0)
						face = dx;
					if (specialCd <= 0 && onSpecial != null && (Input.dashPressed() || Input.shootPressed()))
					{
						specialCd = 0.35;
						onSpecial(this);
					}
				case 0:
					var gx = tx - targetFace() * 16 - 4;
					var gy = ty - 22 + Math.sin(bobT * 3) * 3;
					velocity.x = clamp((gx - x) * 4, 150);
					velocity.y = clamp((gy - y) * 4, 150);
					face = velocity.x >= 0 ? 1 : -1;
					if (Math.abs(tx - x) > 300 || Math.abs(ty - y) > 220)
						reset(tx - 16, ty - 24);
				case 3:
					enterT += elapsed;
					velocity.x = clamp((doorX - cx) * 4, 160);
					velocity.y = clamp((doorY - 12 - (y + 4)) * 4, 160);
					face = velocity.x >= 0 ? 1 : -1;
					if ((Math.abs(doorX - cx) < 5 && Math.abs(doorY - 12 - (y + 4)) < 6) || enterT > 3.5)
						beginFade();
				default:
					velocity.x *= Math.max(0, 1 - 6 * elapsed);
					velocity.y = Math.cos(bobT * 3) * 4;
			}
		}
		else
		{
			switch (mode)
			{
				case 4:
					control(elapsed, onFloor);
					setSolidRole(false);
				case 0:
					walkToward(tx, kind == Companions.TALL ? 30 : 22, onFloor, hitWall, ty > y + height + 20);
					setSolidRole(false);
					// elakadás / lemaradás / leesés: a célhoz kerül
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
				case 3:
					enterT += elapsed;
					walkToward(doorX, 3, onFloor, hitWall, true);
					if ((Math.abs(doorX - cx) < 6 && Math.abs(doorY - (y + height)) < 26) || enterT > 3.5)
						beginFade();
				default:
					// vár: a földön megáll; a magas társ ilyenkor platform
					if (onFloor)
						velocity.x = 0;
					setSolidRole(onFloor);
			}
		}
		flipX = face < 0;
		super.update(elapsed);
	}

	/** Irányított mozgás (a földön járó társak): gyorsulás, ugrás (coyote idő, bufferelt gomb, változó magasság). */
	function control(elapsed:Float, onFloor:Bool):Void
	{
		if (specialCd <= 0 && onSpecial != null && (Input.dashPressed() || Input.shootPressed()))
		{
			specialCd = kind == Companions.WHEELIE ? 0.9 : 0.4;
			onSpecial(this);
		}
		if (turboT > 0)
		{
			turboT -= elapsed;
			velocity.x = face * 240;
			acceleration.y = 900;
			return;
		}
		var dir = (Input.right() ? 1 : 0) - (Input.left() ? 1 : 0);
		var spd = kind == Companions.TALL ? 88.0 : 112.0;
		var jumpV = kind == Companions.TALL ? 290.0 : 275.0;
		var target = dir * spd;
		var acc = (onFloor ? 1500.0 : 900.0) * elapsed;
		if (velocity.x < target)
			velocity.x = Math.min(target, velocity.x + acc);
		else
			velocity.x = Math.max(target, velocity.x - acc);
		if (dir != 0)
			face = dir;
		coyote = onFloor ? 0.08 : coyote - elapsed;
		jumpBuf = Input.jumpPressed() ? 0.12 : jumpBuf - elapsed;
		if (jumpBuf > 0 && coyote > 0)
		{
			velocity.y = -jumpV;
			coyote = 0;
			jumpBuf = 0;
		}
		acceleration.y = (velocity.y < 0 && !Input.jumpHeld()) ? 900 * 2.4 : 900;
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
		FlxTween.tween(scale, {x: 0.2, y: 0.2}, 0.4, {onComplete: _ ->
		{
			exited = true;
			kill();
		}});
	}

	/**
	 * A földön járó társ haladása a cél (gx) felé: lépcső / fal (≤ 3 csempe) ugrás, szakadék átugrás (ha átugorható), különben vár a peremen;
	 * lefelé csak akkor lép le, ha a cél lent van (wantDown) és lent talaj is van.
	 */
	function walkToward(gx:Float, near:Float, onFloor:Bool, hitWall:Bool, wantDown:Bool):Void
	{
		var cx = x + width / 2;
		var dx = gx - cx;
		var spd = kind == Companions.TALL ? 84.0 : 100.0;
		var jumpV = kind == Companions.TALL ? 285.0 : 275.0;
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
			var below = false;
			for (k in 1...7)
				if (level.isStandable(colAhead, footRow + k))
				{
					below = true;
					break;
				}
			if (below && wantDown)
				return; // lelép
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
			acceleration.y = mode == 4 ? acceleration.y : 900;
			immovable = false;
			allowCollisions = FlxDirectionFlags.ANY;
		}
	}

	static inline function clamp(v:Float, m:Float):Float
		return v > m ? m : (v < -m ? -m : v);
}
