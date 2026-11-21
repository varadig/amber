package;

import flixel.FlxSprite;
import flixel.util.FlxDirectionFlags;

/** Kapu-elem: azonosító (gid) köti a nyomólaphoz / kapcsolóhoz / kulcshoz; nyitva: átlátszó és nem ütközik. A zárt kapu (locked) kulccsal nyílik. */
class Gate extends FlxSprite
{
	public var gid:Int;
	public var locked:Bool;
	public var isOpen(get, never):Bool;

	function get_isOpen():Bool
		return !visible;

	public function new(x:Float, y:Float, gid:Int, locked:Bool)
	{
		super(x, y);
		this.gid = gid;
		this.locked = locked;
		loadGraphic(locked ? Art.lockGate() : Art.gate(), false, 16, 16, false, locked ? "lockgate" : "gate");
		immovable = true;
	}

	public function setOpen(o:Bool):Void
	{
		visible = !o;
		allowCollisions = o ? FlxDirectionFlags.NONE : FlxDirectionFlags.ANY;
	}
}

/** Nyomólap: a hős, egy láda vagy egy társ lenyomja. `hold`: csak amíg le van nyomva (különben egyszer és örökre). */
class Plate extends FlxSprite
{
	public var gid:Int;
	public var hold:Bool;
	public var pressed:Bool = false;

	public function new(x:Float, y:Float, gid:Int, hold:Bool)
	{
		super(x, y);
		this.gid = gid;
		this.hold = hold;
		loadGraphic(Art.plate(), true, 16, 6, false, "plate");
		animation.add("up", [0], 1);
		animation.add("down", [1], 1);
		animation.play("up");
		immovable = true;
	}

	public function setPressed(p:Bool):Void
	{
		pressed = p;
		animation.play(p ? "down" : "up");
	}
}

/** Kar: a társ drón (vagy a hős) átbillenti; a kapu megnyílik. */
class Lever extends FlxSprite
{
	public var gid:Int;
	public var flipped:Bool = false;

	public function new(x:Float, y:Float, gid:Int)
	{
		super(x, y);
		this.gid = gid;
		loadGraphic(Art.lever(), true, 16, 10, false, "lever");
		animation.add("off", [0], 1);
		animation.add("on", [1], 1);
		animation.play("off");
		immovable = true;
	}

	public function flip():Void
	{
		flipped = true;
		animation.play("on");
	}
}

/** Sorrend-kapcsoló: a helyes sorrendben megnyomva nyílik a kapu (a sorrendet egy tábla mutatja). */
class SwitchPad extends FlxSprite
{
	public var gid:Int;
	public var idx:Int;
	public var label:String;

	public function new(x:Float, y:Float, gid:Int, idx:Int, label:String)
	{
		super(x, y);
		this.gid = gid;
		this.idx = idx;
		this.label = label;
		loadGraphic(Art.switchPad(), true, 12, 14, false, "switchpad");
		animation.add("up", [0], 1);
		animation.add("down", [1], 1);
		animation.play("up");
		immovable = true;
	}

	public function setDown(d:Bool):Void
		animation.play(d ? "down" : "up");
}

/** Tolható láda: gravitáció, súrlódás; a hős tolja, a nyomólapra állítva lenyomva tartja. */
class Crate extends FlxSprite
{
	public var ox:Float;
	public var oy:Float;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		ox = x;
		oy = y;
		loadGraphic(Art.crate(), false, 16, 16, false, "crate");
		acceleration.y = 900;
		drag.x = 520;
		maxVelocity.set(160, 320);
		mass = 0.7;
	}

	public var carried:Bool = false;

	/** A magas társ felemeli: nincs ütközés / gravitáció, a társ viszi. */
	public function carry():Void
	{
		carried = true;
		acceleration.y = 0;
		velocity.set(0, 0);
		allowCollisions = FlxDirectionFlags.NONE;
	}

	public function drop(px:Float, py:Float):Void
	{
		carried = false;
		acceleration.y = 900;
		allowCollisions = FlxDirectionFlags.ANY;
		reset(px, py);
	}

	public function resetPos():Void
	{
		carried = false;
		allowCollisions = FlxDirectionFlags.ANY;
		acceleration.y = 900;
		reset(ox, oy);
		velocity.set(0, 0);
	}
}

/** Áramforrás-aljzat: az áramcella behelyezése működésbe hozza az emelőt. */
class Socket extends FlxSprite
{
	public var gid:Int;
	public var filled:Bool = false;

	public function new(x:Float, y:Float, gid:Int)
	{
		super(x, y);
		this.gid = gid;
		loadGraphic(Art.socket(), true, 12, 12, false, "socket");
		animation.add("empty", [0], 1);
		animation.add("full", [1, 2], 4);
		animation.play("empty");
		immovable = true;
	}

	public function fill():Void
	{
		filled = true;
		animation.play("full");
	}
}
