package;

/**
	Kontroller-rezgés (force feedback, pl. PS4 DualShock).
	Böngészőben: a Gamepad API (`vibrationActuator.playEffect("dual-rumble")`, Chrome / Edge / Brave; a Firefox és a Safari nem támogatja).
	Asztali (HashLink / natív) változatban: `lime.ui.Gamepad.rumble` -> SDL `SDL_GameControllerRumble` (a lime.hdll része).
	A játékesemények a hangeffektjeik neve szerint rezegnek (`Audio.play` -> `onSound`), így minden ütés / landolás / omlás egy helyen hangolható.
	Kikapcsolható: beállítások menü, VIBRATION (`Prefs.rumble`).
**/
class Rumble
{
	/** Hangeffekt -> [erős motor (bal, mély), gyenge motor (jobb, éles), hossz ms]; a hangerő (0..1) skálázza az erősséget. Ami nincs itt, nem rezeg. */
	static final BY_SOUND:Map<String, Array<Float>> = [
		"hurt" => [0.85, 0.6, 230],
		"fall" => [1.0, 0.8, 420],
		"kill" => [0.25, 0.6, 90],
		"stomp" => [0.3, 0.7, 90],
		"land" => [0.15, 0.45, 70],
		"walljump" => [0.0, 0.3, 50],
		"dash" => [0.15, 0.4, 80],
		"shoot" => [0.0, 0.22, 40],
		"break" => [0.8, 0.55, 300],
		"crumble" => [0.4, 0.3, 200],
		"plate" => [0.35, 0.2, 100],
		"door" => [0.3, 0.2, 110],
		"doorOpen" => [0.55, 0.3, 650],
		"checkpoint" => [0.0, 0.35, 120],
		"heal" => [0.0, 0.25, 140]
	];

	/** A legutóbbi rezgés vége (ms): egy gyengébb hatás ne vágja el a még tartó erősebbet. */
	static var busyUntil:Float = 0;
	static var busyLevel:Float = 0;

	/** Egy hangeffekthez tartozó rezgés (az Audio.play hívja). */
	public static function onSound(name:String, volume:Float):Void
	{
		var r = BY_SOUND.get(name);
		if (r != null)
			play(r[0] * volume, r[1] * volume, Std.int(r[2]));
	}

	/** Rezgés: strong / weak 0..1, hossz ms-ban. Minden csatlakoztatott, rezegni tudó kontrolleren. */
	public static function play(strong:Float, weak:Float, ms:Int):Void
	{
		if (!Prefs.rumble || ms <= 0)
			return;
		strong = Math.max(0, Math.min(1, strong));
		weak = Math.max(0, Math.min(1, weak));
		var now = haxe.Timer.stamp() * 1000;
		var level = Math.max(strong, weak);
		if (now < busyUntil && level < busyLevel)
			return;
		busyUntil = now + ms;
		busyLevel = level;
		#if js
		try
		{
			js.Syntax.code("var ps = navigator.getGamepads ? navigator.getGamepads() : [];
				for (var i = 0; i < ps.length; i++) {
					var p = ps[i];
					if (!p || !p.connected || !p.vibrationActuator) continue;
					var r = p.vibrationActuator.playEffect('dual-rumble', {startDelay: 0, duration: {0}, strongMagnitude: {1}, weakMagnitude: {2}});
					if (r && r.catch) r.catch(function () {});
				}", ms, strong, weak);
		}
		catch (e:Dynamic) {}
		#else
		for (g in lime.ui.Gamepad.devices)
			if (g != null && g.connected)
				g.rumble(strong, weak, ms);
		#end
	}

	#if (cheats && !js)
	/** Hibakeresés (asztali cheat-build): a lime által látott kontrollerek kiírása (`rumblelist=1`), és három próba-rezgés (`rumbletest=1`). */
	public static function selfTest(pulse:Bool = true):Void
	{
		function list(tag:String):Void
		{
			var n = 0;
			for (g in lime.ui.Gamepad.devices)
			{
				n++;
				Sys.println('RUMBLETEST $tag gamepad id=${g.id} name="${g.name}" guid=${g.guid} connected=${g.connected}');
			}
			Sys.println('RUMBLETEST $tag gamepads: $n');
		}
		list("t0");
		// (a HIDAPI-meghajtó Bluetooth-on később kapcsolódik: újra listázunk)
		new flixel.util.FlxTimer().start(3.0, _ -> list("t3"));
		if (!pulse)
			return;
		var k = 0;
		new flixel.util.FlxTimer().start(1.0, t ->
		{
			k++;
			Sys.println('RUMBLETEST pulse $k');
			busyUntil = 0;
			play(1.0, 1.0, 500);
		}, 3);
	}
	#end

	/** Azonnali leállítás (szünet, pályaváltás). */
	public static function stop():Void
	{
		busyUntil = 0;
		busyLevel = 0;
		#if js
		try
		{
			js.Syntax.code("var ps = navigator.getGamepads ? navigator.getGamepads() : [];
				for (var i = 0; i < ps.length; i++) {
					var p = ps[i];
					if (p && p.connected && p.vibrationActuator && p.vibrationActuator.reset) { var r = p.vibrationActuator.reset(); if (r && r.catch) r.catch(function () {}); }
				}");
		}
		catch (e:Dynamic) {}
		#else
		// SDL: nulla erősségű rezgés = leállítás
		for (g in lime.ui.Gamepad.devices)
			if (g != null && g.connected)
				g.rumble(0, 0, 0);
		#end
	}
}
