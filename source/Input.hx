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

	public static function up():Bool
	{
		var p = pad();
		return FlxG.keys.anyPressed([UP, W]) || (p != null && (p.pressed.DPAD_UP || p.analog.value.LEFT_STICK_Y < -0.5));
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

	/** Társ-parancs: Q (kontroller: L1): küldés / megállítás / visszahívás. */
	public static function commandPressed():Bool
	{
		var p = pad();
		return FlxG.keys.anyJustPressed([Q]) || (p != null && p.justPressed.LEFT_SHOULDER);
	}

	/** Társ-váltás: Tab (kontroller: R1). */
	public static function cyclePressed():Bool
	{
		var p = pad();
		return FlxG.keys.anyJustPressed([TAB]) || (p != null && p.justPressed.RIGHT_SHOULDER);
	}

	/** 1-4: közvetlen robotválasztás (0 = nincs). */
	public static function digitPressed():Int
	{
		var k = FlxG.keys.justPressed;
		if (k.ONE)
			return 1;
		if (k.TWO)
			return 2;
		if (k.THREE)
			return 3;
		if (k.FOUR)
			return 4;
		return 0;
	}

	/** R2 (PS4): a cheat-menü gombja; digitális gomb vagy analóg trigger is lehet (a böngésző-leképezéstől függően). */
	public static function r2Held():Bool
	{
		// az összes aktív kontrollert nézi (a böngésző néha két bejegyzést ad ugyanarra a kontrollerre, és a "legutóbb aktív" közöttük ugrál)
		for (p in FlxG.gamepads.getActiveGamepads())
			if (p.pressed.RIGHT_TRIGGER || p.pressed.RIGHT_TRIGGER_BUTTON || p.analog.value.RIGHT_TRIGGER > 0.6)
				return true;
		return false;
	}

	/** Diagnosztika: az éppen lenyomott kontroller-gomb(ok) neve (a cheat-menü alján látszik). */
	public static function padDebug():String
	{
		var s = "";
		for (p in FlxG.gamepads.getActiveGamepads())
		{
			var id = p.firstJustPressedID();
			if (id != flixel.input.gamepad.FlxGamepadInputID.NONE)
				s += "PAD" + p.id + ":" + flixel.input.gamepad.FlxGamepadInputID.toStringMap.get(id) + " ";
		}
		return s;
	}

	/** R2: az állapot képkockánként egyszer (a Main preUpdate-je hívja), így az élváltás (r2New) állapotoktól / menüktől függetlenül egyetlen helyen számolódik. */
	public static var r2New:Bool = false;
	static var r2Down:Bool = false;
	static var r2Off:Float = 0;

	/** Az analóg trigger ingadozása ellen: csak akkor számít elengedettnek, ha 0,12 mp-ig nem volt lenyomva (nincs villogás). */
	public static function pollR2():Void
	{
		var held = r2Held();
		r2New = false;
		if (held)
		{
			r2Off = 0;
			if (!r2Down)
			{
				r2Down = true;
				r2New = true;
			}
		}
		else if (r2Down)
		{
			r2Off += FlxG.elapsed;
			if (r2Off > 0.12)
				r2Down = false;
		}
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
