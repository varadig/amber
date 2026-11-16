package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.util.FlxDirectionFlags;

/**
 * A hős: modern platformer-mozgás. Gyorsulás / lassulás, coyote idő, bufferelt ugrás, változó ugrásmagasság, csúcspont-lebegés,
 * fal-csúszás és fal-ugrás, levegős szökellés (dash; kioltja az ellenséget), lefelé ejtés az egyirányú platformokon,
 * ellenség-ugrálás (stomp) pattanással, sérülés utáni sérthetetlenség.
 */
class Player extends FlxSprite
{
	static inline var RUN = 118.0;
	static inline var JUMP = 332.0;
	static inline var GRAV = 960.0;
	static inline var MAX_FALL = 360.0;
	static inline var DASH_SPEED = 300.0;
	static inline var DASH_TIME = 0.16;

	public var hearts:Int = 3;
	public var maxHearts:Int = 3;
	public var invuln:Float = 0;
	public var dashing:Bool = false;
	public var dropT:Float = 0;
	public var onFloor:Bool = false;
	public var stunned(get, never):Bool;

	/** Események (a PlayState köti be). */
	public var onJump:Void->Void;
	public var onLand:Float->Void;
	public var onDash:Void->Void;
	public var onWallJump:Void->Void;
	public var onTrail:Void->Void;

	var coyote:Float = 0;
	var buffer:Float = 0;
	var wallCoyote:Float = 0;
	var wallDir:Int = 0;
	var dashT:Float = 0;
	var dashCd:Float = 0;
	var canDash:Bool = true;
	var stun:Float = 0;
	var wasOnFloor:Bool = false;
	var lastVy:Float = 0;
	var trailT:Float = 0;
	var face:Int = 1;
	var wallSliding:Bool = false;

	function get_stunned():Bool
		return stun > 0;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic(Art.player(), true, 12, 14, false, "player");
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
		acceleration.y = GRAV;
		maxVelocity.set(400, MAX_FALL + 200);
	}

	override public function update(elapsed:Float):Void
	{
		// az előző képkocka ütközései (a super.update nullázza a `touching`-ot)
		var t = touching;
		onFloor = t.has(FlxDirectionFlags.FLOOR);
		var wallL = t.has(FlxDirectionFlags.LEFT);
		var wallR = t.has(FlxDirectionFlags.RIGHT);

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

		if (onFloor)
		{
			if (!wasOnFloor && lastVy > 120 && onLand != null)
				onLand(lastVy);
			coyote = 0.10;
			canDash = true;
		}
		else
			coyote -= elapsed;
		wasOnFloor = onFloor;

		var dir = (Input.right() ? 1 : 0) - (Input.left() ? 1 : 0);
		if (stun > 0)
			dir = 0;
		if (dir != 0)
			face = dir;
		var jumpHeld = Input.jumpHeld();
		if (Input.jumpPressed())
			buffer = 0.12;
		else
			buffer -= elapsed;

		// fal-érintés (rövid utólagos fal-ugrás ablakkal)
		var touchingWall = !onFloor && ((wallL && dir <= 0) || (wallR && dir >= 0)) && (wallL || wallR);
		if (touchingWall)
		{
			wallDir = wallL ? -1 : 1;
			wallCoyote = 0.09;
		}
		else
			wallCoyote -= elapsed;
		wallSliding = touchingWall && velocity.y > 0 && dir == wallDir;

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
				velocity.x = face * RUN * 1.1;
			}
		}
		else
		{
			acceleration.y = GRAV;
			// vízszintes mozgás: gyorsulás / lassulás (a talajon fürgébb)
			var target = dir * RUN;
			var accel = onFloor ? 1250.0 : 820.0;
			if (dir == 0)
				accel = onFloor ? 1500.0 : 260.0;
			if (stun > 0)
				accel = 120;
			velocity.x = approach(velocity.x, target, accel * elapsed);

			// változó ugrásmagasság: elengedéskor erősebb gravitáció; a csúcson kis lebegés
			if (velocity.y < 0 && !jumpHeld)
				acceleration.y = GRAV * 2.7;
			else if (Math.abs(velocity.y) < 45 && jumpHeld)
				acceleration.y = GRAV * 0.55;

			if (wallSliding)
				velocity.y = Math.min(velocity.y, 48);

			// ugrás
			if (buffer > 0 && stun <= 0)
			{
				if (coyote > 0)
				{
					velocity.y = -JUMP;
					coyote = 0;
					buffer = 0;
					onFloor = false;
					if (onJump != null)
						onJump();
				}
				else if (wallCoyote > 0)
				{
					velocity.y = -JUMP * 0.95;
					velocity.x = -wallDir * 150;
					face = -wallDir;
					wallCoyote = 0;
					buffer = 0;
					canDash = true;
					if (onWallJump != null)
						onWallJump();
				}
			}
			// lefelé ejtés az egyirányú platformról
			if (onFloor && Input.down() && Input.jumpPressed())
			{
				dropT = 0.22;
				buffer = 0;
				coyote = 0;
				y += 2;
			}
			// dash
			if (Input.dashPressed() && canDash && dashCd <= 0 && stun <= 0)
			{
				dashing = true;
				dashT = DASH_TIME;
				dashCd = 0.28;
				canDash = false;
				velocity.x = face * DASH_SPEED;
				velocity.y = 0;
				if (onDash != null)
					onDash();
			}
		}

		lastVy = velocity.y;
		super.update(elapsed);

		// megjelenítés
		flipX = face < 0;
		if (stun > 0)
			animation.play("hurt");
		else if (dashing)
			animation.play("dash");
		else if (!onFloor && wallSliding)
			animation.play("wall");
		else if (!onFloor)
			animation.play(velocity.y < 0 ? "jump" : "fall");
		else if (Math.abs(velocity.x) > 10)
			animation.play("run");
		else
			animation.play("idle");
		if (animation.name == "run")
			animation.timeScale = FlxMath.bound(Math.abs(velocity.x) / RUN, 0.5, 1.3);
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
		velocity.y = Input.jumpHeld() ? -JUMP * 0.92 : -JUMP * 0.62;
		canDash = true;
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
		canDash = true;
	}
}
