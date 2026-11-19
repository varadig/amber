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
	/** Tiszta látás sugara (px) és a robot helye a képen: kívül átmenetesen homályos (AmberShader.uClear / uFocusPos). 640 fölött nincs homály. */
	public static var clearTarget:Float = 700;
	static var clearNow:Float = 700;
	/** A PlayState.create állítja: a következő állapotváltás / képkocka a látást átmenet nélkül a célértékre teszi. */
	public static var snapVision:Bool = false;
	public static var focusX:Float = 240;
	public static var focusY:Float = 135;
	/** VISOR-élesedés effekt: 1-ről 0-ra fut (FOCUS_TIME mp alatt); lásd AmberShader.uFocus. */
	static var focusT:Float = 0;
	static inline var FOCUS_TIME = 2.8;

	/** A képernyő-shader hangulatának (Looks) újra-beállítása. */
	public static function applyLook():Void
	{
		if (amber != null)
			Looks.apply(amber);
	}

	/** A VISOR felvételekor: a kép villódzik, majd egy fénysáv élesíti fentről lefelé. */
	public static function startFocus():Void
		focusT = 1;

	public function new()
	{
		super();
		#if (cheats && js)
		// ?exportlevels=1: a generált pályák és a Tiled-erőforrások exportja (scripts/generate-levels.ps1)
		if (js.Browser.location.search.indexOf("exportlevels=1") >= 0)
			FlxG.signals.postGameStart.addOnce(LevelExport.run);
		#end
		// A borostyán-monitor shader az egész játékon (a játék példányon, hogy a pásztázó-vonalak az ablak felbontásán is élesek legyenek)
		Looks.load();
		DevReload.init(); // dev build: élő újratöltés új dev build esetén
		amber = new AmberShader();
		var filter = new ShaderFilter(amber);
		// a kamera szűrője állapotváltáskor elvész (új kamera), ezért minden váltás után újra beállítjuk
		FlxG.signals.postStateSwitch.add(() ->
		{
			tiredTarget = 0;
			hitFx = 0;
			focusT = 0;
			if (!snapVision)
			{
				sightTarget = 1;
				clearTarget = 700;
			}
			// a PlayState.create már beállította a célt (snapVision): azonnal azzal indulunk, nincs átmenet
			clearNow = clearTarget;
			sightNow = sightTarget;
			amber.uClear.value = [clearNow];
			amber.uClearNew.value = [clearNow];
			amber.uSight.value = [sightNow];
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
			if (snapVision)
			{
				// állapotváltás után az első képkockán a látás azonnal a célértéken áll
				snapVision = false;
				clearNow = clearTarget;
				sightNow = sightTarget;
			}
			else if (focusT > 0)
			{
				// VISOR-élesedés: a villódzás + fénysáv alatt a látás nem változik, a végén egyből a célérték
				focusT -= FlxG.elapsed / FOCUS_TIME;
				if (focusT <= 0)
				{
					focusT = 0;
					sightNow = sightTarget;
					clearNow = clearTarget;
				}
			}
			else
			{
				sightNow += (sightTarget - sightNow) * Math.min(1, FlxG.elapsed * 2.5);
				clearNow += (clearTarget - clearNow) * Math.min(1, FlxG.elapsed * 2.0);
			}
			amber.uClear.value = [clearNow];
			amber.uClearNew.value = [focusT > 0 ? clearTarget : clearNow];
			amber.uFocusPos.value = [focusX, focusY];
			amber.uFocus.value = [focusT];
			amber.uSight.value = [sightNow];
			hitFx = Math.max(0, hitFx - FlxG.elapsed * 2.2);
			amber.uHit.value = [hitFx];
			tiredNow += (tiredTarget - tiredNow) * Math.min(1, FlxG.elapsed * 1.3);
			amber.uTired.value = [tiredNow];
		});

		// Belső felbontás 480x270 (C64-szerű pixelek), arányos nagyítással
		#if cheats
		// fejlesztői URL-paraméterek (csak -debug / -Dtest / -Dcheats buildben): ?level=N (0-tól) a megadott pályával indít, ?goto=<pont> a pálya egy pontjára ugrik
		// (spawn, cpN, partN, buildingN, doorN, terminalN, benchN, exit, vagy "x,y" pixel), ?parts=prev|all az előző pályák / minden alkatrészt megadja
		var qs = js.Browser.location.search;
		var direct = false;
		var lm = ~/[?&]level=([0-9]+)/;
		if (lm.match(qs))
		{
			PlayState.level = Std.parseInt(lm.matched(1));
			direct = true;
		}
		var gm = ~/[?&]goto=([A-Za-z0-9,._-]+)/;
		if (gm.match(qs))
		{
			PlayState.devGoto = gm.matched(1);
			direct = true;
		}
		var pm = ~/[?&]parts=([a-z]+)/;
		if (pm.match(qs))
			PlayState.devParts = pm.matched(1);
		#if test
		direct = true;
		#end
		var first:Class<flixel.FlxState> = direct ? PlayState : TitleState;
		if (qs.indexOf("intro=1") >= 0)
		{
			first = IntroState; // ?intro=1: a bevezető közvetlen megnyitása (teszt); ?intro=1&manual=1: nincs automatikus lépés
			IntroState.manual = qs.indexOf("manual=1") >= 0;
		}
		addChild(new FlxGame(480, 270, first, 60, 60, true));
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
