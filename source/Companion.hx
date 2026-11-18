package;

import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import flixel.util.FlxDirectionFlags;
import Puzzle;

/** Egy útvonal-csempe: oszlop, sor (a talp sora), és az ide vezető él fajtája (0 járás, 1 lelépés, 2 ugrás). */
typedef RouteNode = {c:Int, r:Int, k:Int};

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
	/** A társ sérülése a közös akkut meríti (mint a hősé); itt csak a sérthetetlenség van. */
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
		maxVelocity.set(300, 480); // a LEGS-szinttel nő a társak futása / ugrása
	}

	/** Sérülés: elveszít egy szívet, rövid sérthetetlenség, hátralökődés. */
	public function takeHit(fromX:Float):Bool
	{
		if (invuln > 0 || turboT > 0 || mode == 3 || fading)
			return false;
		var core = Parts.tier(Parts.CORE);
		invuln = core >= 5 ? 2.2 : (core >= 4 ? 1.9 : 1.4);
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
		if (hurry > 0)
			hurry -= elapsed;
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
						specialCd = 0.35 / skillBoost();
						onSpecial(this);
					}
				case 0:
					// az ORB a hős mögött és fölött lebeg, tisztes távolban (ne takarja a többi robotot)
					var gx = tx - targetFace() * 38 - 4;
					var gy = ty - 44 + Math.sin(bobT * 3) * 3;
					if (idleAct == 2) // keringés a hős körül
					{
						gx += Math.cos(bobT * 8) * 16;
						gy += Math.sin(bobT * 8) * 10;
					}
					// segítség: a közelben lévő (akár magasan lebegő) atomokat, akkukat összeszedi
					updateLoot(elapsed);
					if (loot != null)
					{
						gx = loot.x + loot.width / 2 - width / 2;
						gy = loot.y + loot.height / 2 - height / 2;
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
					// segítség: a vele egy szinten, közel fekvő atomot / akkut útközben összeszedi
					updateLoot(elapsed);
					var routing = false;
					if (!idling && route != null)
						routing = followRoute(onFloor, elapsed, (kind == Companions.TALL ? 84.0 : 100.0) * Parts.runBoost(), (kind == Companions.TALL ? 320.0 : 335.0) * Parts.jumpBoost());
					if (!idling && !routing)
					{
						// lefelé: ha a cél talpa legalább egy csempével lejjebb van, lelépünk (a középpont-összehasonlítás ezt két csempére tolta)
						walkToward(loot != null ? loot.x + loot.width / 2 : tx, loot != null ? 4 : (kind == Companions.TALL ? 30 : 22), onFloor, hitWall, target.y + target.height > y + height + 12);
						// útkereső: ha mozogni akarna, de ~2 mp-ig nem halad (alagútba / kamrába szorult), kiutat keres a hőshöz
						if (planCool > 0)
							planCool -= elapsed;
						var wantMove = loot == null && Math.abs(tx - cx) > 30;
						if (wantMove && Math.abs(x - progX) < 1.5)
							progT += elapsed;
						else
						{
							progX = x;
							progT = 0;
						}
						if (progT > 2.0 && planCool <= 0)
						{
							progT = 0;
							planCool = 3;
							var gn = goalNode(tx);
							if (gn != null && !trapAtFloor(gn[0], gn[1] + 1))
							{
								route = planRoute(gn[0], gn[1]);
								routeI = 0;
								routeT = 0;
								routeX = x;
								routeStall = 0;
							}
						}
					}
					// a gyűjtendő tárgy közvetlenül fölöttünk van: ugrunk érte
					if (loot != null && onFloor && !idling && Math.abs(loot.x + loot.width / 2 - cx) < 12 && loot.y + loot.height / 2 < y + height - 6)
						velocity.y = -310;
					setSolidRole(false);
					// elakadás / lemaradás / leesés: a célhoz kerül
					var dx = tx - cx;
					if (onFloor && Math.abs(dx) > 100 && Math.abs(velocity.x) < 4)
						stuckT += elapsed;
					else
						stuckT = 0;
					// (az útkereső ~1 mp után indul: a teleport csak utána, ha az sem segít)
					var far = stuckT > 3.5 || Math.abs(dx) > 300 || ty < y - 130;
					var fell = y > (level.killRow + 3) * LevelData.T && ty < (level.killRow + 2) * LevelData.T;
					// ha a hős olyan gödörben van, ahonnan mi nem jönnénk ki, nem teleportálunk mellé (a peremen várunk)
					if (fell || (far && !trapAtFloor(Std.int(tx / LevelData.T), Std.int((target.y + target.height + 2) / LevelData.T))))
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
					{
						// a repedező (leszakadó) platformról a legközelebbi stabil talajra menekül
						var sx = hurry > 0 && safeGround != null ? safeGround(this) : Math.NaN;
						if (!Math.isNaN(sx))
							walkToward(sx, 3, onFloor, hitWall, false);
						else
							velocity.x = 0;
					}
					setSolidRole(onFloor);
			}
		}
		if (idleAct == 1)
			face = Math.sin(idleLeft * 7) > 0 ? 1 : -1; // körülnéz
		state = mode == 4 ? "control" : (mode == 3 ? "door" : (idleAct > 0 ? ["", "look", "hop", "stroll", "beep"][idleAct] : (mode == 0 ? "follow" : "wait")));
		flipX = face < 0;
		if (kind != Companions.ORB && mode != 4 && mode != 3 && route == null)
			guardFall(onFloor);
		super.update(elapsed);
	}

	/** A talajon álló társ ne lépjen le halálos szakadékba (talaj nélküli mélység): a perem előtt megáll. Mozgó / leszakadó platformon is véd. */
	function guardFall(onFloor:Bool):Void
	{
		if (!onFloor || velocity.y < -1 || Math.abs(velocity.x) < 1)
			return;
		var T = LevelData.T;
		var d = velocity.x > 0 ? 1 : -1;
		var col = Std.int((x + width / 2 + d * (width / 2 + 2)) / T);
		var footRow = Std.int((y + height + 2) / T);
		if (stand(col, footRow))
			return;
		for (j in 1...17)
			if (stand(col, footRow + j))
				return; // van lent talaj: lépcső / lelépés (azt a trapBelow-s logika dönti el)
		velocity.x = 0;
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

	/**
	 * A társ különleges képességének gyorsasága: a hős alkatrész-szintjei fejlesztik
	 * (WHEELIE: THRUSTER, TALL: GEAR, ORB: BLASTER); szintenként +20%.
	 */
	public function skillBoost():Float
	{
		var id = kind == Companions.WHEELIE ? Parts.THRUSTER : (kind == Companions.TALL ? Parts.GEAR : Parts.BLASTER);
		return 1 + 0.2 * Math.max(0, Parts.tier(id) - 1);
	}

	/** Irányított mozgás (a földön járó társak): gyorsulás, ugrás (coyote idő, bufferelt gomb, változó magasság). */
	function control(elapsed:Float, onFloor:Bool):Void
	{
		if (specialCd <= 0 && onSpecial != null && (Input.dashPressed() || Input.shootPressed()))
		{
			specialCd = (kind == Companions.WHEELIE ? 0.9 : 0.4) / skillBoost();
			onSpecial(this);
		}
		if (turboT > 0)
		{
			turboT -= elapsed;
			velocity.x = face * 240 * Parts.runBoost();
			acceleration.y = 900;
			return;
		}
		var dir = (Input.right() ? 1 : 0) - (Input.left() ? 1 : 0);
		var spd = (kind == Companions.TALL ? 88.0 : 112.0) * Parts.runBoost();
		var jumpV = (kind == Companions.TALL ? 320.0 : 335.0) * Parts.jumpBoost();
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
		var spd = (kind == Companions.TALL ? 84.0 : 100.0) * Parts.runBoost();
		if (hurry > 0)
			spd *= kind == Companions.TALL ? 2.2 : 1.5; // leszakadó platformon sietünk (a lassú TALL jobban), hogy ne zuhanjunk vele együtt
		var jumpV = (kind == Companions.TALL ? 320.0 : 335.0) * Parts.jumpBoost(); // a hőssel azonos ugrómagasság (kb. 57 px I. szinten, LEGS-szinttel nő)
		var maxGap = kind == Companions.TALL ? 3 : 4;
		// a cél lent van, és vízszintesen közel (a "közel" körül ingadozás ellen a lelépéshez tágabb sáv kell, és az irányt megtartjuk)
		var ed = wantDown && onFloor && Math.abs(dx) <= near + 30 ? edgeDir() : 0;
		if (ed != 0)
		{
			if (descendDir == 0)
				descendDir = ed;
			dx = descendDir * 100;
		}
		else
		{
			descendDir = 0;
			if (Math.abs(dx) <= near)
			{
				// a cél fölöttünk van egy magasabb felületen (egyirányú platform): fölé ugrunk
				if (wantUp && onFloor && tryHopUp(face, 900.0, jumpV, spd))
					return;
				if (onFloor)
					velocity.x = 0;
				return;
			}
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
		// tüske vagy nem ráléphető ellenség közvetlenül előttünk: átugorjuk
		if (hazardAhead != null && hazardAhead(this, dir))
		{
			velocity.y = -285;
			velocity.x = dir * spd * 1.1;
			hopDir = dir;
			return;
		}
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
			for (k in 1...16)
				if (stand(colAhead, footRow + k))
				{
					below = true;
					break;
				}
			if (below && wantDown)
			{
				// olyan gödörbe nem megyünk le, ahonnan a falak miatt nem tudnánk kijönni: a peremen várunk
				if (trapBelow(colAhead, footRow))
					velocity.x = 0;
				return; // különben lelép
			}
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
	 * Segítség (gyűjtés): a PlayState keres egy közeli felvehető tárgyat (atom, akku): `findLoot(társ, kihagyandó)`; a társ érte megy.
	 * Ha 4 mp alatt nem éri el, 25 mp-re kihagyja (pl. falba zárt tárgy).
	 */
	public var findLoot:Companion->FlxSprite->FlxSprite = null;
	var loot:FlxSprite = null;
	var skip:FlxSprite = null;
	var skipT:Float = 0;
	var lootScan:Float = 0;
	var lootT:Float = 0;

	function updateLoot(elapsed:Float):Void
	{
		if (findLoot == null)
			return;
		if (skipT > 0)
		{
			skipT -= elapsed;
			if (skipT <= 0)
				skip = null;
		}
		if (loot != null && (!loot.alive || !loot.exists))
			loot = null;
		if (loot != null)
		{
			lootT += elapsed;
			if (lootT > 4)
			{
				skip = loot;
				skipT = 25;
				loot = null;
			}
		}
		if (loot == null)
		{
			lootScan -= elapsed;
			if (lootScan <= 0)
			{
				lootScan = 0.4;
				loot = findLoot(this, skip);
				lootT = 0;
			}
		}
	}
	/** Veszély (tüske, nem ráléphető ellenség) a társ előtt a megadott irányban? A PlayState állítja be; igaz esetén a társ átugorja. */
	public var hazardAhead:Companion->Int->Bool = null;
	/** A lelépés megválasztott iránya (a peremhez), amíg a cél alattunk van: nem ingadozik a két perem között. */
	var descendDir:Int = 0;
	/** Leszakadó platformon áll: sietős mozgás (másodpercek); a PlayState állítja. */
	public var hurry:Float = 0;
	/** A legközelebbi stabil talaj x-e (NaN, ha nincs): a repedező platformról való menekülés célja. A PlayState állítja. */
	public var safeGround:Companion->Float = null;

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
					var found = false;
					for (j in 1...16)
						if (stand(c, footRow + j))
						{
							found = true;
							break;
						}
					if (found && !trapBelow(c, footRow))
						return d;
					blocked[s] = true; // ezen az oldalon szakadék van lent talaj nélkül, vagy gödör, amiből nem jönnénk ki: nem lépünk le
				}
			}
		return 0;
	}

	// --- Útkereső (A*): ha a követés elakad (pl. alagútba / kamrába szorult), a rács-gráfon keres kiutat a hőshöz ---

	/** Statikus és dinamikus akadály (repedezett fal, zárt kapu, a TALL-nak a rács) a (c, r) csempén? A PlayState adja a dinamikus részt. */
	public var blockedExtra:Int->Int->Bool = null;
	var route:Array<RouteNode> = null;
	var routeI:Int = 0;
	var routeT:Float = 0;
	var routeX:Float = 0;
	var routeStall:Float = 0;
	/** Az útvonal kiinduló csempéje (a tiltólistához) és a sikertelen élek: kulcs = honnan * N + hova, érték = a tiltás lejárta (másodpercben). */
	var routeStartC:Int = 0;
	var routeStartR:Int = 0;
	var badEdges:Map<Int, Float> = new Map();
	var jumpStep:Int = -1;
	var jumpTries:Int = 0;

	/** Az éppen követett lépés (honnan -> hova) sikertelen: 25 mp-re tiltólistára kerül, hogy az újratervezés ne ugyanazt próbálja; az útvonal megszakad. */
	function failStep():Void
	{
		if (route != null && routeI < route.length)
		{
			var W = level.w;
			var N = W * LevelData.H;
			var n = route[routeI];
			var fc = routeI > 0 ? route[routeI - 1].c : routeStartC;
			var fr = routeI > 0 ? route[routeI - 1].r : routeStartR;
			var key = (fr * W + fc) * N + (n.r * W + n.c);
			var prev = badEdges.get(key);
			// ugyanaz az él másodszor is sikertelen: hosszabb tiltás
			badEdges.set(key, haxe.Timer.stamp() + (prev != null && prev > haxe.Timer.stamp() - 60 ? 90 : 25));
		}
		route = null;
		jumpStep = -1;
	}
	/** Felfelé ugrás közben a cél felület magassága (px), amíg a talpunk nem ér fölé: addig csak függőlegesen emelkedünk. */
	var jumpTop:Float = -1;
	var planCool:Float = 0;
	var progX:Float = 0;
	var progT:Float = 0;

	function solidAt(c:Int, r:Int):Bool
	{
		if (c < 0 || c >= level.w || r >= LevelData.H)
			return true;
		if (r < 0)
			return false;
		return level.isSolid(c, r) || (blockedExtra != null && blockedExtra(c, r));
	}

	function groundAt(c:Int, r:Int):Bool
	{
		if (c < 0 || c >= level.w || r >= LevelData.H)
			return false;
		return level.isStandable(c, r) || (blockedExtra != null && blockedExtra(c, r)) || (movingStand != null && movingStand(c, r) != null);
	}

	/** A test (a TALL-nál két csempe) szabadon elfér a (c, r) csempén (r = a talp sora)? */
	function bodyFree(c:Int, r:Int):Bool
		return !solidAt(c, r) && (kind != Companions.TALL || !solidAt(c, r - 1));

	/** Álló csempe: szabad test + alatta talaj. */
	function validNode(c:Int, r:Int):Bool
		return bodyFree(c, r) && groundAt(c, r + 1);

	/**
	 * A*: a saját csempénkről a (gc, gr) célcsempére vezető út (járás, lelépés, ugrás felfelé / szakadék fölött), vagy null.
	 * Élek: 0 járás, 1 lelépés (esés), 2 ugrás. Az akadályok: tömör csempék + `blockedExtra`.
	 */
	function planRoute(gc:Int, gr:Int):Array<RouteNode>
	{
		var T = LevelData.T;
		var W = level.w;
		var H = LevelData.H;
		var sc = Std.int((x + width / 2) / T);
		var sr = Std.int((y + height - 1) / T);
		// légben (pl. ugrálás közben) a lent lévő első álló csempéről indulunk
		var fixR = -1;
		for (k in 0...4)
			if (validNode(sc, sr + k))
			{
				fixR = sr + k;
				break;
			}
		if (fixR < 0)
			return null;
		sr = fixR;
		var N = W * H;
		var g = new haxe.ds.Vector<Float>(N);
		var par = new haxe.ds.Vector<Int>(N);
		var knd = new haxe.ds.Vector<Int>(N);
		for (i in 0...N)
		{
			g[i] = 1e9;
			par[i] = -1;
		}
		var hid:Array<Int> = [];
		var hf:Array<Float> = [];
		function push(id:Int, f:Float):Void
		{
			hid.push(id);
			hf.push(f);
			var i = hid.length - 1;
			while (i > 0)
			{
				var p = (i - 1) >> 1;
				if (hf[p] <= hf[i])
					break;
				var ti = hid[p];
				hid[p] = hid[i];
				hid[i] = ti;
				var tf = hf[p];
				hf[p] = hf[i];
				hf[i] = tf;
				i = p;
			}
		}
		function pop():Int
		{
			var top = hid[0];
			var lastId = hid.pop();
			var lastF = hf.pop();
			if (hid.length > 0)
			{
				hid[0] = lastId;
				hf[0] = lastF;
				var i = 0;
				while (true)
				{
					var l = 2 * i + 1;
					var r = l + 1;
					var m = i;
					if (l < hid.length && hf[l] < hf[m])
						m = l;
					if (r < hid.length && hf[r] < hf[m])
						m = r;
					if (m == i)
						break;
					var ti = hid[m];
					hid[m] = hid[i];
					hid[i] = ti;
					var tf = hf[m];
					hf[m] = hf[i];
					hf[i] = tf;
					i = m;
				}
			}
			return top;
		}
		var nowT = haxe.Timer.stamp();
		function relax(from:Int, c2:Int, r2:Int, cost:Float, k:Int):Void
		{
			var id = r2 * W + c2;
			// a korábban sikertelen élek (ahol elakadtunk / többször nem sikerült az ugrás) egy ideig tiltottak
			var until = badEdges.get(from * N + id);
			if (until != null && until > nowT)
				return;
			var ng = g[from] + cost;
			if (ng < g[id])
			{
				g[id] = ng;
				par[id] = from;
				knd[id] = k;
				push(id, ng + Math.abs(c2 - gc) + Math.abs(r2 - gr));
			}
		}
		var maxGap = kind == Companions.TALL ? 3 : 4;
		var tall = kind == Companions.TALL;
		routeStartC = sc;
		routeStartR = sr;
		var sid = sr * W + sc;
		g[sid] = 0;
		push(sid, Math.abs(sc - gc) + Math.abs(sr - gr));
		var goalId = -1;
		var iter = 0;
		while (hid.length > 0 && iter++ < 30000)
		{
			var id = pop();
			var c = id % W;
			var r = Std.int(id / W);
			if (c == gc && r == gr)
			{
				goalId = id;
				break;
			}
			if (Math.abs(c - sc) > 110)
				continue;
			var d = -1;
			while (d <= 1)
			{
				var nc = c + d;
				if (bodyFree(nc, r))
				{
					if (groundAt(nc, r + 1))
						relax(id, nc, r, 1, 0);
					else
					{
						// lelépés: esés az első talajig (legfeljebb 15 csempe)
						var rr = r + 1;
						while (rr < r + 16 && rr < H - 1 && bodyFree(nc, rr))
						{
							if (validNode(nc, rr))
							{
								relax(id, nc, rr, 1 + 0.3 * (rr - r), 1);
								break;
							}
							rr++;
						}
					}
				}
				// ugrás: felfelé (legfeljebb 3 csempe), szakadék fölött, vagy lejjebb
				for (k in 1...maxGap + 2)
					for (hh in -3...4)
					{
						var h = -hh; // h > 0: felfelé
						if (h == 0 && k == 1)
							continue;
						var maxK = h <= 1 ? maxGap + 1 : (h == 2 ? 3 : 2);
						if (h < 0)
							maxK = maxGap + 1;
						if (k > maxK)
							continue;
						var tc = c + d * k;
						var tr = r - h;
						if (!validNode(tc, tr))
							continue;
						var top = (tr < r ? tr : r) - 1;
						var clear = true;
						var rr = top;
						while (rr < r)
						{
							if (solidAt(c, rr) || (tall && solidAt(c, rr - 1)))
								clear = false;
							rr++;
						}
						var j = 1;
						while (clear && j <= k)
						{
							if (solidAt(c + d * j, top) || (tall && solidAt(c + d * j, top - 1)))
								clear = false;
							j++;
						}
						if (clear && tr > r)
						{
							rr = r;
							while (rr <= tr)
							{
								if (solidAt(tc, rr))
									clear = false;
								rr++;
							}
						}
						if (clear)
							relax(id, tc, tr, 2 + k + (h < 0 ? -h : h), 2);
					}
				d += 2;
			}
		}
		if (goalId < 0)
			return null;
		var out:Array<RouteNode> = [];
		var cur = goalId;
		while (par[cur] >= 0)
		{
			out.push({c: cur % W, r: Std.int(cur / W), k: knd[cur]});
			cur = par[cur];
		}
		out.reverse();
		if (out.length > 30)
			return null; // túl hosszú kerülő: a normál követés / teleport marad
		return out;
	}

	/** Az útvonal követése; hamis, ha elfogyott / megszakadt (ilyenkor a normál követés megy tovább). */
	function followRoute(onFloor:Bool, elapsed:Float, spd:Float, jumpV:Float):Bool
	{
		var T = LevelData.T;
		var cx = x + width / 2;
		var cc = Std.int(cx / T);
		var cr = Std.int((y + height - 1) / T);
		while (routeI < route.length && onFloor && route[routeI].c == cc && route[routeI].r == cr)
			routeI++;
		if (routeI >= route.length)
		{
			route = null;
			return false;
		}
		routeT += elapsed;
		if (routeT > 10)
		{
			failStep();
			planCool = 1;
			return false;
		}
		var n = route[routeI];
		var dist = n.c * T + T / 2 - cx;
		var dir = dist >= 0 ? 1 : -1;
		face = dir;
		if (!onFloor)
		{
			// levegőben a cél oszlop felé kormányozunk (a fal pereme fölött is átviszi); felfelé ugrásnál előbb függőlegesen emelkedünk,
			// amíg a talpunk a cél felülete fölé nem ér (különben a tető / a fal alá ütköznénk)
			if (jumpTop >= 0 && y + height > jumpTop + 0.5)
				velocity.x = 0;
			else
				velocity.x = clamp(dist * 6, spd * 1.2);
			routeX = x;
			routeStall = 0;
			return true;
		}
		jumpTop = -1;
		if (n.k == 2)
		{
			var up = cr - n.r;
			// felfelé ugrás előtt a saját csempénk közepére állunk (a fal / tető pereme mellé ne lógjunk)
			var ownCx = cc * T + T / 2;
			if (up > 0 && Math.abs(cx - ownCx) > 2.5)
			{
				velocity.x = (ownCx > cx ? 1 : -1) * Math.min(spd, Math.abs(ownCx - cx) * 8 + 20);
				return true;
			}
			var dyl = (n.r + 1) * T - (y + height);
			var g = 900.0;
			var v = Math.max(150.0, Math.sqrt(2 * g * Math.max(0.0, -dyl + 9)));
			var ok = false;
			var dd = Math.abs(dist);
			while (v <= jumpV)
			{
				var tt = (v + Math.sqrt(v * v + 2 * g * dyl)) / g;
				if (dd / tt <= spd * 1.35)
				{
					// ugyanarra a csempére ugrik-e már harmadszor? akkor az az él nem jó: tiltólista, újratervezés
					if (jumpStep == routeI)
						jumpTries++;
					else
					{
						jumpStep = routeI;
						jumpTries = 1;
					}
					if (jumpTries > 2)
					{
						failStep();
						planCool = 0.3;
						return false;
					}
					velocity.y = -v;
					velocity.x = dir * Math.max(40.0, dd / tt);
					ok = true;
					break;
				}
				v += 8;
			}
			if (!ok)
			{
				velocity.y = -jumpV;
				velocity.x = dir * spd;
			}
			hopDir = 0;
			if (up > 0)
			{
				velocity.x = 0; // először egyenesen fel
				jumpTop = (n.r + 1) * T;
			}
		}
		else
			velocity.x = dir * spd;
		// elakadás: ha 1,2 mp-ig nem mozdul, feladjuk (újratervezés később)
		if (Math.abs(x - routeX) < 0.8)
		{
			routeStall += elapsed;
			if (routeStall > 1.2)
			{
				failStep();
				planCool = 0.8;
				return false;
			}
		}
		else
		{
			routeX = x;
			routeStall = 0;
		}
		return true;
	}

	/** A cél (hős) csempéje: a lába alatti első talajig lejjebb keresve. Visszaadja a [oszlop, sor] párt, vagy null. */
	function goalNode(tx:Float):Array<Int>
	{
		var T = LevelData.T;
		var gc = Std.int(tx / T);
		var gr = Std.int((target.y + target.height - 1) / T);
		for (k in 0...16)
			if (validNode(gc, gr + k))
				return [gc, gr + k];
		return null;
	}

	/** A (col) oszlopban lent (a fromRow alatti első talajon) olyan gödör van-e, ahonnan ugrással nem tudnánk kijönni? */
	function trapBelow(col:Int, fromRow:Int):Bool
	{
		for (j in 1...16)
			if (stand(col, fromRow + j))
				return trapAtFloor(col, fromRow + j);
		return false;
	}

	/**
	 * A `land` sorban lévő talajon a `col` oszlopban gödör (csapda) van-e: mindkét oldalon (legfeljebb 6 csempén belül) fal áll,
	 * aminek a teteje magasabb, mint a saját ugrásmagasságunk. Nyitott oldal vagy mászható fal esetén nem csapda.
	 */
	function trapAtFloor(col:Int, land:Int):Bool
	{
		var T = LevelData.T;
		var jv = kind == Companions.TALL ? 320.0 : 335.0;
		var reach = jv * jv / (2 * 900.0);
		var s = -1;
		while (s <= 1)
		{
			var c = col;
			var n = 0;
			while (n < 6 && !level.isSolid(c, land - 1))
			{
				c += s;
				n++;
			}
			if (!level.isSolid(c, land - 1))
				return false; // nyitott oldal: simán kisétál
			var r = land - 1;
			while (r > land - 15 && level.isSolid(c, r - 1))
				r--;
			if ((land - r) * T <= reach - 6)
				return false; // ezen az oldalon ki tud ugrani
			s += 2;
		}
		return true;
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
