package;

import flixel.FlxG;

/** Billentyűzet + kontroller egységes kezelése. */
class Input
{
	static inline function pad()
		return FlxG.gamepads.lastActive;

	public static function left():Bool
	{
		var p = pad();
		return FlxG.keys.anyPressed([LEFT, A]) || (p != null && (p.pressed.DPAD_LEFT || p.analog.value.LEFT_STICK_X < -0.35));
	}

	public static function right():Bool
	{
		var p = pad();
		return FlxG.keys.anyPressed([RIGHT, D]) || (p != null && (p.pressed.DPAD_RIGHT || p.analog.value.LEFT_STICK_X > 0.35));
	}

	public static function down():Bool
	{
		var p = pad();
		return FlxG.keys.anyPressed([DOWN, S]) || (p != null && (p.pressed.DPAD_DOWN || p.analog.value.LEFT_STICK_Y > 0.5));
	}

	public static function jumpPressed():Bool
	{
		var p = pad();
		return FlxG.keys.anyJustPressed([UP, W, Z, SPACE, C]) || (p != null && p.justPressed.A);
	}

	public static function jumpHeld():Bool
	{
		var p = pad();
		return FlxG.keys.anyPressed([UP, W, Z, SPACE, C]) || (p != null && p.pressed.A);
	}

	public static function dashPressed():Bool
	{
		var p = pad();
		return FlxG.keys.anyJustPressed([X, SHIFT, K]) || (p != null && (p.justPressed.X || p.justPressed.B));
	}

	public static function shootPressed():Bool
	{
		var p = pad();
		return FlxG.keys.anyJustPressed([V, J, CONTROL]) || (p != null && p.justPressed.Y);
	}

	/** Ajtón belépés / kilépés: Fel, W, E, Enter (kontroller: D-pad fel). */
	public static function interactPressed():Bool
	{
		var p = pad();
		return FlxG.keys.anyJustPressed([UP, W, E, ENTER]) || (p != null && p.justPressed.DPAD_UP);
	}

	public static function pausePressed():Bool
	{
		var p = pad();
		return FlxG.keys.anyJustPressed([ESCAPE, P]) || (p != null && p.justPressed.START);
	}

	public static function confirmPressed():Bool
	{
		var p = pad();
		return FlxG.keys.anyJustPressed([ENTER, SPACE, Z, UP, W, C]) || (p != null && (p.justPressed.A || p.justPressed.START));
	}

	public static function restartPressed():Bool
		return FlxG.keys.justPressed.R;
}
