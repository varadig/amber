package;

import flixel.FlxG;
import flixel.input.gamepad.FlxGamepadInputID;

/** Billentyűzet + kontroller egységes kezelése. */
class Input
{
	/** Az összes aktív kontrollert nézi (a böngésző néha több bejegyzést ad egy kontrollerre, és a "lastActive" ugrál / null marad). */
	public static function held(id:FlxGamepadInputID):Bool
	{
		for (p in FlxG.gamepads.getActiveGamepads())
			if (p.checkStatus(id, PRESSED))
				return true;
		return false;
	}

	public static function just(id:FlxGamepadInputID):Bool
	{
		for (p in FlxG.gamepads.getActiveGamepads())
			if (p.checkStatus(id, JUST_PRESSED))
				return true;
		return false;
	}

	/** A bal pálca tengelye: a legnagyobb kitérésű kontrolleré. */
	public static function stickX():Float
	{
		var r = 0.0;
		for (p in FlxG.gamepads.getActiveGamepads())
			if (Math.abs(p.analog.value.LEFT_STICK_X) > Math.abs(r))
				r = p.analog.value.LEFT_STICK_X;
		return r;
	}

	public static function stickY():Float
	{
		var r = 0.0;
		for (p in FlxG.gamepads.getActiveGamepads())
			if (Math.abs(p.analog.value.LEFT_STICK_Y) > Math.abs(r))
				r = p.analog.value.LEFT_STICK_Y;
		return r;
	}

	public static function left():Bool
	{
		return FlxG.keys.anyPressed([LEFT, A]) || (held(FlxGamepadInputID.DPAD_LEFT) || stickX() < -0.35);
	}

	public static function right():Bool
	{
		return FlxG.keys.anyPressed([RIGHT, D]) || (held(FlxGamepadInputID.DPAD_RIGHT) || stickX() > 0.35);
	}

	public static function up():Bool
	{
		return FlxG.keys.anyPressed([UP, W]) || (held(FlxGamepadInputID.DPAD_UP) || stickY() < -0.5);
	}

	public static function down():Bool
	{
		return FlxG.keys.anyPressed([DOWN, S]) || (held(FlxGamepadInputID.DPAD_DOWN) || stickY() > 0.5);
	}

	public static function jumpPressed():Bool
	{
		return FlxG.keys.anyJustPressed([UP, W, Z, SPACE, C]) || (just(FlxGamepadInputID.A));
	}

	public static function jumpHeld():Bool
	{
		return FlxG.keys.anyPressed([UP, W, Z, SPACE, C]) || (held(FlxGamepadInputID.A));
	}

	public static function dashPressed():Bool
	{
		return FlxG.keys.anyJustPressed([X, SHIFT, K]) || (just(FlxGamepadInputID.X) || just(FlxGamepadInputID.B));
	}

	public static function shootPressed():Bool
	{
		return FlxG.keys.anyJustPressed([V, J, CONTROL]) || (just(FlxGamepadInputID.Y));
	}

	/** Ajtón belépés / kilépés: Fel, W, E, Enter (kontroller: D-pad fel). */
	public static function interactPressed():Bool
	{
		return FlxG.keys.anyJustPressed([UP, W, E, ENTER]) || (just(FlxGamepadInputID.DPAD_UP));
	}

	/** Társ-parancs: Q (kontroller: L1): küldés / megállítás / visszahívás. */
	public static function commandPressed():Bool
	{
		return FlxG.keys.anyJustPressed([Q]) || (just(FlxGamepadInputID.LEFT_SHOULDER));
	}

	/** Társ-váltás: Tab (kontroller: R1). */
	public static function cyclePressed():Bool
	{
		return FlxG.keys.anyJustPressed([TAB]) || (just(FlxGamepadInputID.RIGHT_SHOULDER));
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
			if (held(FlxGamepadInputID.RIGHT_TRIGGER) || held(FlxGamepadInputID.RIGHT_TRIGGER_BUTTON) || p.analog.value.RIGHT_TRIGGER > 0.6)
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
		return FlxG.keys.anyJustPressed([ESCAPE, P]) || (just(FlxGamepadInputID.START));
	}

	public static function confirmPressed():Bool
	{
		return FlxG.keys.anyJustPressed([ENTER, SPACE, Z, UP, W, C]) || (just(FlxGamepadInputID.A) || just(FlxGamepadInputID.START));
	}

	public static function restartPressed():Bool
		return FlxG.keys.justPressed.R;
}
