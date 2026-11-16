package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.util.FlxDirectionFlags;

/**
 * A hős: modern platformer-mozgás, de a képességei az alkatrészein múlnak (`Parts`): csupaszon lassú és csak picit ugrik;
 * LEGS: teljes ugrás és gyors futás; THRUSTER: szökellés (dash; kioltja az ellenséget); CLAWS: fal-csúszás és fal-ugrás (kapaszkodó póz);
 * BLASTER: lövés; a JET CELL ideiglenes repülést ad (ugrás gomb nyomva tartva). Mindenkinek jár: coyote idő, bufferelt ugrás,
 * változó ugrásmagasság, csúcspont-lebegés, lefelé ejtés az egyirányú platformokon, ellenségre ugrás (stomp), sérülés utáni sérthetetlenség.
 */
class Player extends FlxSprite
{
	static inline var GRAV = 960.0;
	static inline var MAX_FALL = 360.0;
	static inline var DASH_SPEED = 300.0;
	static inline var DASH_TIME = 0.16;
	public static inline var FLIGHT_TIME = 5.0;

	public var hearts:Int = 3;
	public var maxHearts:Int = 3;
	public var invuln:Float = 0;
	public var dashing:Bool = false;
	public var dropT:Float = 0;
	public var onFloor:Bool = false;
	public var flightT:Float = 0;
	public var clinging:Bool = false;
	public var frozen:Bool = false;
	/** Lemerült akku: ennyi másodpercig nem irányítható a robot (újraindulás). */
	public var powerDown:Float = 0;
	public var stunned(get, never):Bool;

	/** Események (a PlayState köti be). */
	public var onJump:Void->Void;
	public var onLand:Float->Void;
	public var onDash:Void->Void;
	public var onWallJump:Void->Void;
	public var onTrail:Void->Void;
	public var onThrust:Void->Void;
	public var onSlide:Int->Void;
	public var onShoot:Float->Float->Int->Void;

	var coyote:Float = 0;
	var buffer:Float = 0;
	var wallCoyote:Float = 0;
	var wallDir:Int = 0;
	var lastWallJump:Int = 0;
	var dashT:Float = 0;
	var dashCd:Float = 0;
	var shootCd:Float = 0;
	var dashesLeft:Int = 1;
	/** Szűrt mozgás-bemenet (processzor nélkül lomha). */
	var dirF:Float = 0;
	var jumpDelay:Float = 0;
	var stun:Float = 0;
	var wasOnFloor:Bool = false;
	var lastVy:Float = 0;
	var trailT:Float = 0;
	var slideT:Float = 0;
	var face:Int = 1;
	var lookMask:Int = -1;

	function get_stunned():Bool
		return stun > 0;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		width = 8;
		height = 12;
		offset.set(2, 2);
		acceleration.y = GRAV;
		maxVelocity.set(400, MAX_FALL + 200);
		refreshLook();
		applyParts();
		hearts = maxHearts;
	}

	/** Az alkatrészek hatása: szívek száma (CORE) és a szökellések száma (THRUSTER). */
	public function applyParts():Void
	{
		maxHearts = 2 + Std.int(Math.min(3, Parts.tier(Parts.CORE)));
		if (hearts > maxHearts)
			hearts = maxHearts;
	}

	function maxDashes():Int
		return Parts.tier(Parts.THRUSTER) >= 2 ? 2 : 1;

	/** A megjelenés az aktuálisan birtokolt alkatrészekhez igazítva (csupasz alváz -> felszerelt robot). */
	public function refreshLook():Void
	{
		var m = Parts.mask();
		if (m == lookMask)
			return;
		lookMask = m;
		loadGraphic(Art.player(m), true, 12, 14, false, "player" + m);
		width = 8;
		height = 12;
		offset.set(2, 2);
		animation.add("idle", [0], 1);
		animation.add("run", [1, 2, 3, 4], 12);
		animation.add("jump", [5], 1);
		animation.add("fall", [6], 1);
		animation.add("wall", [7], 1);
		animation.add("dash", [8], 1);
		animation.add("hurt", [9], 1);
		animation.add("off", [10], 1);
	}

	/** Futósebesség: csupaszon lassú. */
	function runSpeed():Float
		return Parts.has(Parts.LEGS) ? (Parts.tier(Parts.LEGS) >= 2 ? 130.0 : 118.0) : 78.0;

	/** Ugrás-erő: csupaszon csak egy kis szökkenés. */
	function jumpPower():Float
		return Parts.has(Parts.LEGS) ? (Parts.tier(Parts.LEGS) >= 2 ? 365.0 : 332.0) : 215.0;

	override public function update(elapsed:Float):Void
	{
		if (frozen)
		{
			super.update(elapsed);
			return;
		}
		var on = powerDown <= 0;
		if (!on)
			powerDown -= elapsed;
		// az előző képkocka ütközései (a super.update nullázza a `touching`-ot)
		var t = touching;
		onFloor = t.has(FlxDirectionFlags.FLOOR);
		var hasClaws = Parts.has(Parts.CLAWS);
		var wallL = hasClaws && t.has(FlxDirectionFlags.LEFT);
		var wallR = hasClaws && t.has(FlxDirectionFlags.RIGHT);

		if (invuln > 0)
		{
			invuln -= elapsed;
			visible = invuln <= 0 || Std.int(invuln * 18) % 2 == 0;
		}
		else
			visible = true;
		if (stun > 0)
			stun -= elapsed;
		if (dropT > 0)
			dropT -= elapsed;
		if (dashCd > 0)
			dashCd -= elapsed;
		if (shootCd > 0)
			shootCd -= elapsed;

		if (onFloor)
		{
			if (!wasOnFloor && lastVy > 120 && onLand != null)
				onLand(lastVy);
			coyote = 0.10;
			dashesLeft = maxDashes();
			lastWallJump = 0;
		}
		else
			coyote -= elapsed;
		wasOnFloor = onFloor;

		var dir = on ? ((Input.right() ? 1 : 0) - (Input.left() ? 1 : 0)) : 0;
		if (stun > 0)
			dir = 0;
		if (dir != 0 && !clinging)
			face = dir;
		var jumpHeld = on && Input.jumpHeld();
		// processzor nélkül a vezérlés késve reagál (az ugrás gomb ~90 ms-mal később hat), és a mozgás-bemenet lomhán követi a kart
		var chip = Parts.tier(Parts.CHIP);
		if (on && Input.jumpPressed())
		{
			if (chip == 0)
				jumpDelay = 0.09;
			else
				buffer = 0.12;
		}
		else
			buffer -= elapsed;
		if (jumpDelay > 0)
		{
			jumpDelay -= elapsed;
			if (jumpDelay <= 0)
				buffer = 0.12;
		}
		var follow = chip == 0 ? 6.0 : (chip == 1 ? 30.0 : 60.0);
		dirF += (dir - dirF) * Math.min(1, follow * elapsed);
		if (dir == 0 && Math.abs(dirF) < 0.03)
			dirF = 0;

		// fal-érintés (a karmokkal; rövid utólagos fal-ugrás ablakkal)
		var touchingWall = !onFloor && ((wallL && dir <= 0) || (wallR && dir >= 0)) && (wallL || wallR);
		if (touchingWall)
		{
			wallDir = wallL ? -1 : 1;
			wallCoyote = 0.09;
		}
		else
			wallCoyote -= elapsed;
		// kapaszkodás: a fal felé tartva a fal mellett a hős megkapaszkodik (kapaszkodó póz, lassú csúszás)
		clinging = touchingWall && dir == wallDir && stun <= 0 && !dashing && velocity.y > -120;
		if (clinging)
			face = wallDir;

		if (dashing)
		{
			dashT -= elapsed;
			velocity.y = 0;
			acceleration.y = 0;
			trailT -= elapsed;
			if (trailT <= 0)
			{
				trailT = 0.03;
				if (onTrail != null)
					onTrail();
			}
			if (dashT <= 0)
			{
				dashing = false;
				velocity.x = face * runSpeed() * 1.1;
			}
		}
		else
		{
			acceleration.y = GRAV;
			// vízszintes mozgás: gyorsulás / lassulás (a talajon fürgébb)
			var target = dirF * runSpeed();
			// a szervók (GEAR) nélkül a levegőben alig irányítható
			var air = Parts.has(Parts.GEAR) ? (Parts.tier(Parts.GEAR) >= 2 ? 1000.0 : 820.0) : 380.0;
			var accel = onFloor ? (chip == 0 ? 650.0 : 1250.0) : air;
			if (dir == 0)
				accel = onFloor ? (chip == 0 ? 700.0 : 1500.0) : 260.0;
			if (stun > 0)
				accel = 120;
			velocity.x = approach(velocity.x, target, accel * elapsed);

			// változó ugrásmagasság: elengedéskor erősebb gravitáció; a csúcson kis lebegés
			if (velocity.y < 0 && !jumpHeld)
				acceleration.y = GRAV * 2.7;
			else if (Math.abs(velocity.y) < 45 && jumpHeld)
				acceleration.y = GRAV * 0.55;

			if (clinging)
			{
				velocity.y = Math.min(velocity.y, 42);
				slideT -= elapsed;
				if (slideT <= 0 && onSlide != null)
				{
					slideT = 0.07;
					onSlide(wallDir);
				}
			}

			// ugrás
			if (buffer > 0 && stun <= 0)
			{
				if (coyote > 0)
				{
					velocity.y = -jumpPower();
					coyote = 0;
					buffer = 0;
					onFloor = false;
					if (onJump != null)
						onJump();
				}
				else if (wallCoyote > 0 && wallDir != lastWallJump)
				{
					// fal-ugrás: ugyanarról az oldalról nem ismételhető (a földet érésig), így egy fallal nem lehet végtelenül felmászni
					velocity.y = -jumpPower() * 0.95;
					velocity.x = -wallDir * 150;
					face = -wallDir;
					lastWallJump = wallDir;
					wallCoyote = 0;
					buffer = 0;
					dashesLeft = maxDashes();
					if (onWallJump != null)
						onWallJump();
				}
			}
			// repülés (JET CELL): az ugrás gomb nyomva tartva felfelé hajt, amíg el nem fogy az üzemanyag
			if (flightT > 0 && jumpHeld && stun <= 0 && !onFloor && buffer <= 0)
			{
				if (velocity.y > -125)
				{
					velocity.y = Math.max(-125, velocity.y - 1500 * elapsed);
					acceleration.y = 0;
					flightT -= elapsed;
					if (onThrust != null)
						onThrust();
				}
			}
			// lefelé ejtés az egyirányú platformról
			if (on && onFloor && Input.down() && Input.jumpPressed())
			{
				dropT = 0.22;
				buffer = 0;
				coyote = 0;
				y += 2;
			}
			// dash (THRUSTER)
			if (on && Parts.has(Parts.THRUSTER) && Input.dashPressed() && dashesLeft > 0 && dashCd <= 0 && stun <= 0)
			{
				dashing = true;
				dashT = DASH_TIME;
				dashCd = 0.28;
				dashesLeft--;
				velocity.x = face * DASH_SPEED;
				velocity.y = 0;
				if (onDash != null)
					onDash();
			}
			// lövés (BLASTER)
			if (on && Parts.has(Parts.BLASTER) && Input.shootPressed() && shootCd <= 0 && stun <= 0)
			{
				shootCd = Parts.tier(Parts.BLASTER) >= 2 ? 0.13 : 0.26;
				if (onShoot != null)
					onShoot(x + width / 2 + face * 6, y + 5, face);
			}
		}

		lastVy = velocity.y;
		super.update(elapsed);

		// megjelenítés
		flipX = face < 0;
		if (!on)
			animation.play("off");
		else if (stun > 0)
			animation.play("hurt");
		else if (dashing)
			animation.play("dash");
		else if (clinging)
			animation.play("wall");
		else if (!onFloor)
			animation.play(velocity.y < 0 ? "jump" : "fall");
		else if (Math.abs(velocity.x) > 10)
			animation.play("run");
		else
			animation.play("idle");
		if (animation.name == "run")
			animation.timeScale = FlxMath.bound(Math.abs(velocity.x) / runSpeed(), 0.5, 1.3);
		// a hős látható mérete: nyújtás / nyomódás az ugrás-landolás pillanatában
		scale.x = FlxMath.lerp(scale.x, 1, 0.3);
		scale.y = FlxMath.lerp(scale.y, 1, 0.3);
	}

	static inline function approach(v:Float, target:Float, d:Float):Float
	{
		if (v < target)
			return Math.min(target, v + d);
		return Math.max(target, v - d);
	}

	public function squash(sx:Float, sy:Float):Void
	{
		scale.set(sx, sy);
	}

	/** Ellenségre ugrás utáni pattanás (a gomb nyomva tartásával magasabbra). */
	public function bounce():Void
	{
		var gearF = Parts.has(Parts.GEAR) ? (Parts.tier(Parts.GEAR) >= 2 ? 1.15 : 1.0) : 0.8;
		velocity.y = (Input.jumpHeld() ? -jumpPower() * 0.92 : -jumpPower() * 0.62) * gearF;
		dashesLeft = maxDashes();
		coyote = 0;
		dashing = false;
		squash(0.8, 1.25);
	}

	/** Sérülés: `fromX` az ütközés forrásának x-e (a hős onnan elrepül). */
	public function takeHit(fromX:Float):Bool
	{
		if (invuln > 0 || dashing)
			return false;
		hearts--;
		invuln = 1.5;
		stun = 0.28;
		dashing = false;
		velocity.x = (x + width / 2 < fromX ? -1 : 1) * 150;
		velocity.y = -200;
		return true;
	}

	public function respawnAt(px:Float, py:Float):Void
	{
		reset(px, py);
		velocity.set(0, 0);
		invuln = 1.6;
		stun = 0;
		dashing = false;
		dashesLeft = maxDashes();
		clinging = false;
		frozen = false;
	}
}
