package;

import flixel.FlxG;
import flixel.FlxGame;
import openfl.display.Sprite;
import openfl.filters.ShaderFilter;

class Main extends Sprite
{
	static var amber:AmberShader;
	static var clock:Float = 0;
	/** A látás célértéke (0 homályos .. 1 éles): a PlayState állítja a VISOR szerint; a megjelenített érték simán követi. */
	public static var sightTarget:Float = 1;
	static var sightNow:Float = 1;
	/** Sérülés: 1-re állítva elektromos kisülés-effekt (gyorsan lecseng). */
	public static var hitFx:Float = 0;
	/** Fáradtság (lemerülő akku): a kép elsötétül és elmosódik, simán követi a célértéket. */
	public static var tiredTarget:Float = 0;
	static var tiredNow:Float = 0;

	public function new()
	{
		super();
		// A borostyán-monitor shader az egész játékon (a játék példányon, hogy a pásztázó-vonalak az ablak felbontásán is élesek legyenek)
		amber = new AmberShader();
		var filter = new ShaderFilter(amber);
		// a kamera szűrője állapotváltáskor elvész (új kamera), ezért minden váltás után újra beállítjuk
		FlxG.signals.postStateSwitch.add(() ->
		{
			sightTarget = 1;
			tiredTarget = 0;
			hitFx = 0;
			FlxG.camera.filters = [filter];
		});
		FlxG.signals.postGameStart.addOnce(() ->
		{
			FlxG.mouse.visible = false;
			FlxG.sound.muteKeys = [];
			FlxG.sound.volumeUpKeys = [];
			FlxG.sound.volumeDownKeys = [];
		});
		FlxG.signals.preUpdate.add(Input.pollR2);
		FlxG.signals.postUpdate.add(() ->
		{
			clock += FlxG.elapsed;
			amber.uTime.value = [clock];
			sightNow += (sightTarget - sightNow) * Math.min(1, FlxG.elapsed * 2.5);
			amber.uSight.value = [sightNow];
			hitFx = Math.max(0, hitFx - FlxG.elapsed * 2.2);
			amber.uHit.value = [hitFx];
			tiredNow += (tiredTarget - tiredNow) * Math.min(1, FlxG.elapsed * 1.3);
			amber.uTired.value = [tiredNow];
		});

		// Belső felbontás 480x270 (C64-szerű pixelek), arányos nagyítással
		#if test
		// ?level=N: a megadott pályától indul (csak teszt-buildben)
		var m = ~/[?&]level=([0-9]+)/;
		if (m.match(js.Browser.location.search))
			PlayState.level = Std.parseInt(m.matched(1));
		addChild(new FlxGame(480, 270, PlayState, 60, 60, true));
		#else
		addChild(new FlxGame(480, 270, TitleState, 60, 60, true));
		#end

		#if js
		// a hang feloldása valódi felhasználói eseményből (billentyű / kattintás / érintés): a böngésző csak így engedi a lejátszást
		for (ev in ["keydown", "pointerdown", "touchend", "mousedown"])
			js.Browser.window.addEventListener(ev, (_) -> Audio.unlock(), true);
		// F: teljes képernyő (közvetlenül a billentyűeseményből, mert a böngésző csak felhasználói műveletre engedi)
		js.Browser.window.addEventListener("keydown", (e:js.html.KeyboardEvent) ->
		{
			if (e.code != "KeyF" || e.repeat)
				return;
			js.Syntax.code("var d = document;
				var p = d.fullscreenElement ? d.exitFullscreen() : d.documentElement.requestFullscreen();
				if (p && p.catch) p.catch(function () {});");
		});
		#end
	}
}
