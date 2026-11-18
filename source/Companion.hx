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
	/**
	 * Mozgó platform a (csempe-oszlop, csempe-sor) csempe tetején? A platform vízszintes sebességét (px/s) adja, különben null.
	 * A PlayState állítja be: a pályatérkép (`level`) a mozgó platformokat nem ismeri, ezért a követő ezzel látja, hova ugorhat.
	 */
	public var movingStand:Int->Int->Null<Float> = null;
	var level:LevelData;
	var bobT:Float = Math.random() * 6;
	var stuckT:Float = 0;
	var doorX:Float = 0;
	var doorY:Float = 0;
	var enterT:Float = 0;
	var fading:Bool = false;
	var coyote:Float = 0;
	var jumpBuf:Float = 0;
	/** Üresjárat: ha a robot (követve vagy várva) sokáig nem csinál semmit, véletlen apróságot tesz. */
	var idleT:Float = 0;
	var idleAct:Int = 0;
	var idleLeft:Float = 0;
	var idleDir:Int = 1;
	var idleHopped:Bool = false;
	/** A robot aktuális állapota (follow / wait / control / door / look / hop / stroll / beep); a HUD-nak és a teszteknek. */
	public var state:String = "wait";

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

		// üresjárat: a követő (a cél közelében, mozdulatlan célnál) vagy váró robot ismétlődően tesz valami apróságot
		var quiet = (mode == 0 || mode == 1) && invuln <= 0 && (mode == 1 || (Math.abs(tx - cx) < 70 && Math.abs(target.velocity.x) < 6 && Math.abs(target.velocity.y) < 30));
		idleTick(elapsed, quiet);
		var idling = idleAct != 0 && idleMove(onFloor, hitWall);

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
					if (idleAct == 2) // keringés a hős körül
					{
						gx += Math.cos(bobT * 8) * 16;
						gy += Math.sin(bobT * 8) * 10;
					}
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
					if (idleAct == 2) // helyben köröz
					{
						velocity.x = Math.cos(bobT * 6) * 35;
						velocity.y = Math.sin(bobT * 6) * 35;
					}
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
					wantUp = target.y + target.height < y + height - 12;
					if (!idling)
						// lefelé: ha a cél talpa legalább egy csempével lejjebb van, lelépünk (a középpont-összehasonlítás ezt két csempére tolta)
						walkToward(tx, kind == Companions.TALL ? 30 : 22, onFloor, hitWall, target.y + target.height > y + height + 12);
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
					if (onFloor && !idling)
						velocity.x = 0;
					setSolidRole(onFloor);
			}
		}
		if (idleAct == 1)
			face = Math.sin(idleLeft * 7) > 0 ? 1 : -1; // körülnéz
		state = mode == 4 ? "control" : (mode == 3 ? "door" : (idleAct > 0 ? ["", "look", "hop", "stroll", "beep"][idleAct] : (mode == 0 ? "follow" : "wait")));
		flipX = face < 0;
		super.update(elapsed);
	}

	/** Üresjárat-időzítő: ~4 mp tétlenség után véletlen tevékenység (1 körülnéz, 2 ugrik / keringő ORB, 3 sétál, 4 "pittyeg" = összenyomódik). */
	function idleTick(elapsed:Float, quiet:Bool):Void
	{
		if (!quiet)
		{
			idleT = 0;
			idleAct = 0;
			return;
		}
		if (idleAct == 0)
		{
			idleT += elapsed;
			if (idleT < 4)
				return;
			var opts = [1, 2, 4];
			if (kind != Companions.ORB && mode == 0)
				opts.push(3);
			if (kind == Companions.TALL && mode == 1)
				opts.remove(2); // a váró magas társ platform: nem ugrál
			idleAct = opts[Std.random(opts.length)];
			idleLeft = idleAct == 2 && kind != Companions.ORB ? 0.7 : 1.2 + Math.random();
			idleDir = Std.random(2) * 2 - 1;
			idleHopped = false;
			if (idleAct == 4)
				FlxTween.tween(scale, {y: 0.6}, 0.14, {onComplete: _ -> FlxTween.tween(scale, {y: 1}, 0.2)});
			return;
		}
		idleLeft -= elapsed;
		if (idleLeft <= 0)
		{
			idleAct = 0;
			idleT = 4 - (1.5 + Math.random() * 3); // a következő apróság 1,5-4,5 mp múlva
		}
	}

	/** A földön járó társ üresjárati mozgása; igaz, ha ő mozgatja a robotot (a követés ilyenkor szünetel). */
	function idleMove(onFloor:Bool, hitWall:Bool):Bool
	{
		if (kind == Companions.ORB)
			return idleAct == 2;
		if (!onFloor)
			return false;
		switch (idleAct)
		{
			case 2:
				if (!idleHopped)
				{
					idleHopped = true;
					velocity.y = -170;
				}
				return true;
			case 3:
				face = idleDir;
				velocity.x = idleDir * 28;
				if (!level.isStandable(Std.int((x + width / 2 + idleDir * 10) / LevelData.T), Std.int((y + height + 2) / LevelData.T)))
				{
					velocity.x = 0;
					idleLeft = 0;
				}
				if (hitWall)
					idleLeft = 0;
				return true;
			default:
				velocity.x = 0;
				return true;
		}
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
		var jumpV = kind == Companions.TALL ? 320.0 : 335.0;
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
		var jumpV = kind == Companions.TALL ? 320.0 : 335.0; // a hőssel azonos ugrómagasság (kb. 57 px)
		var maxGap = kind == Companions.TALL ? 3 : 4;
		if (Math.abs(dx) <= near)
		{
			// a cél fölöttünk van egy magasabb felületen (egyirányú platform): fölé ugrunk
			if (wantUp && onFloor && tryHopUp(face, 900.0, jumpV, spd))
				return;
			// a cél közvetlenül alattunk van (lent áll): a legközelebbi peremhez megyünk, és lelépünk, különben örökre fent maradnánk
			var ed = wantDown && onFloor ? edgeDir() : 0;
			if (ed == 0)
			{
				if (onFloor)
					velocity.x = 0;
				return;
			}
			dx = ed * 100;
		}
		var dir = dx > 0 ? 1 : -1;
		face = dir;
		if (!onFloor)
		{
			// falra / platformra ugrás közben a levegőben is nyomjuk a fal felé, különben a csúcson a fal mellett lecsúszik, és sosem kerül át a peremen
			if (hopDir != 0)
			{
				velocity.x = hopDir * spd * 0.7;
				face = hopDir;
			}
			return; // különben megmarad a lendület
		}
		hopDir = 0;
		var T = LevelData.T;
		var colAhead = Std.int((cx + dir * (width / 2 + 5)) / T);
		var footRow = Std.int((y + height + 2) / T);
		var bodyRow = Std.int((y + height - 5) / T);
		velocity.x = dir * spd;
		var g = 900.0;
		// magasabb felületre (egyirányú, mozgó vagy leszakadó platform) ugrás, ha a cél följebb van
		if (wantUp && tryHopUp(dir, g, jumpV, spd))
			return;
		if (level.isSolid(colAhead, bodyRow))
		{
			// fal / lépcső: a tetejére ugrik, ha legfeljebb 3 csempe magas és fölötte szabad; csak akkorát, amekkora kell
			var h = 1;
			while (h <= 3 && level.isSolid(colAhead, bodyRow - h))
				h++;
			if (h <= 3 && !level.isSolid(colAhead, bodyRow - h - 1))
			{
				var rise = (y + height) - (bodyRow - h + 1) * T + 9; // a peremnél a test szélessége miatt pár pixellel magasabbra kell
				var v = Math.sqrt(2 * g * rise);
				if (v <= jumpV)
				{
					velocity.y = -v;
					velocity.x = dir * spd * 0.75;
					hopDir = dir;
					return;
				}
			}
			velocity.x = 0;
			return;
		}
		if (!stand(colAhead, footRow))
		{
			var below = false;
			for (k in 1...7)
				if (stand(colAhead, footRow + k))
				{
					below = true;
					break;
				}
			if (below && wantDown)
				return; // lelép
			// a legközelebbi túlsó talaj (mozgó platform is): a szakadék szélessége és a magasságkülönbség szerint számolt ugrás (nem ugrik túl)
			var landCol = -999;
			var landRow = 0;
			var landVx = 0.0;
			for (k in 1...maxGap + 2)
			{
				var cc = colAhead + dir * k;
				for (r in -2...3)
					if (stand(cc, footRow + r) && !level.isSolid(cc, footRow + r - 1) && !level.isSolid(cc, footRow + r - 2))
					{
						landCol = cc;
						landRow = footRow + r;
						var mv = movingStand != null ? movingStand(cc, footRow + r) : null;
						landVx = mv != null ? mv : 0.0;
						break;
					}
				if (landCol != -999)
					break;
			}
			if (landCol == -999)
			{
				velocity.x = 0; // a peremen vár
				return;
			}
			var dyl = landRow * T - (y + height);
			var vmin = Math.max(150.0, Math.sqrt(2 * g * Math.max(0.0, -dyl + 6)));
			var v = vmin;
			var jumpOk = false;
			while (v <= jumpV)
			{
				var tt = (v + Math.sqrt(v * v + 2 * g * dyl)) / g;
				// a mozgó platform a repülés alatt odébb megy: a leszállási pontot előre számoljuk
				var dist = Math.abs(landCol * T + T / 2 + landVx * tt - cx);
				if (dist / tt <= spd * 1.35)
				{
					jumpOk = true;
					velocity.y = -v;
					velocity.x = dir * Math.max(40.0, dist / tt);
					break;
				}
				v += 8;
			}
			if (!jumpOk)
				velocity.x = 0;
		}
	}

	/** A követés célja magasabban van (legalább egy csempével): az update számolja a mód 0 hívása előtt. */
	var wantUp:Bool = false;
	/** Falra / platformra ugrás iránya a levegőben (0 = nincs): a csúcson is a perem felé nyomjuk. */
	var hopDir:Int = 0;

	/**
	 * Felugrás egy magasabb felületre (egyirányú / mozgó / leszakadó platform, legfeljebb a saját ugrásmagasságig): ha a közelben (a saját oszlopunkban
	 * vagy legfeljebb két oszloppal előrébb) van fölöttünk szabad tetejű felület, akkora ugrással, amekkora kell.
	 */
	function tryHopUp(dir:Int, g:Float, jumpV:Float, spd:Float):Bool
	{
		var T = LevelData.T;
		var cx = x + width / 2;
		var col = Std.int(cx / T);
		var footRow = Std.int((y + height + 2) / T);
		var headRows = kind == Companions.TALL ? 2 : 1;
		for (k in 0...3)
		{
			var c = col + dir * k;
			for (h in 1...5)
			{
				var row = footRow - h;
				if (!stand(c, row) || level.isSolid(c, row))
					continue;
				var free = true;
				for (j in 1...headRows + 1)
					if (level.isSolid(c, row - j))
						free = false;
				if (!free)
					continue;
				var rise = h * T + 9;
				var v = Math.sqrt(2 * g * rise);
				if (v > jumpV)
					continue;
				// előrébb lévő felületnél csak közelről ugrunk (különben elrepülnénk mellette)
				if (k > 0 && Math.abs(c * T + T / 2 - cx) > T * 1.7)
					continue;
				velocity.y = -v;
				velocity.x = k > 0 ? dir * spd * 0.8 : 0;
				hopDir = k > 0 ? dir : 0;
				return true;
			}
		}
		return false;
	}

	/** Szilárd / egyirányú csempe vagy mozgó platform a (tx, ty) csempén. */
	function stand(tx:Int, ty:Int):Bool
		return level.isStandable(tx, ty) || (movingStand != null && movingStand(tx, ty) != null);

	/** A legközelebbi perem iránya (-1 / 1), ahol a talaj véget ér és lent (legfeljebb 6 csempével mélyebben) újra van talaj; 0, ha nincs. */
	function edgeDir():Int
	{
		var T = LevelData.T;
		var col = Std.int((x + width / 2) / T);
		var footRow = Std.int((y + height + 2) / T);
		var blocked = [false, false];
		for (k in 1...11)
			for (s in 0...2)
			{
				var d = s == 0 ? 1 : -1;
				var c = col + d * k;
				if (blocked[s])
					continue;
				if (!stand(c, footRow))
				{
					for (j in 1...7)
						if (stand(c, footRow + j))
							return d;
					blocked[s] = true; // ezen az oldalon szakadék van lent talaj nélkül: nem lépünk le
				}
			}
		return 0;
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
