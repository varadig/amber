package;

import flixel.FlxG;
import flixel.FlxGame;
import openfl.display.Sprite;
import openfl.filters.ShaderFilter;

class Main extends Sprite
{
	static var amber:AmberShader;
	static var clock:Float = 0;

	/** A shaderek közös órája (a HUD szünet-hullámzása a játékképével együtt mozog). */
	public static function shaderTime():Float
		return clock;
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

	/** Szünet-effekt (0..1, a PlayState.setPaused állítja): AmberShader.uPause, lágyan be- és kiúszik. */
	public static var pauseTarget:Float = 0;
	static var pauseNow:Float = 0;

	/** Teszthez: a szünet-effekt pillanatnyi erőssége. */
	public static function amberPause():Float
		return pauseNow;

	/** A shaderben éppen érvényes tiszta-látás sugár (px); a PlayState.updateFog ehhez halványítja a tárgyakat / ellenségeket. */
	public static function clearRadius():Float
		return clearNow;
	public static var focusX:Float = 240;
	public static var focusY:Float = 135;
	/** VISOR-élesedés effekt: 1-ről 0-ra fut (FOCUS_TIME mp alatt); lásd AmberShader.uFocus. */
	static var focusT:Float = 0;
	static inline var FOCUS_TIME = 2.0;

	/** A képernyő-shader hangulatának (Looks) újra-beállítása. */
	public static function applyLook():Void
	{
		if (amber != null)
			Looks.apply(amber);
	}

	/** A VISOR felvételekor: a kép villódzik, majd egy fénysáv élesíti fentről lefelé. */
	public static function startFocus():Void
		focusT = 1;

	#if hl
	/**
		A program legelején (az SDL indulása előtt; a statikus __init__ a main előtt fut): SDL-beállítások környezeti változóként.
		A Bluetooth-on csatlakozó PS4 / PS5 kontroller csak "bővített" módban rezeg, ezt az SDL 2.28 alapból nem kapcsolja be (a lime sem).
	**/
	static function __init__():Void
	{
		Sys.putEnv("SDL_JOYSTICK_HIDAPI_PS4_RUMBLE", "1");
		Sys.putEnv("SDL_JOYSTICK_HIDAPI_PS5_RUMBLE", "1");
	}
	#end

	public function new()
	{
		super();
		#if (cheats && js)
		// ?exportlevels=1: a generált pályák és a Tiled-erőforrások exportja (scripts/generate-levels.ps1)
		if (js.Browser.location.search.indexOf("exportlevels=1") >= 0)
			FlxG.signals.postGameStart.addOnce(LevelExport.run);
		#end
		// A borostyán-monitor shader az egész játékon (a játék példányon, hogy a pásztázó-vonalak az ablak felbontásán is élesek legyenek)
		#if (hl && target.threaded && !amber_nothread)
		Audio.startWorker(); // a zene háttérszála (asztali változat: a renderelés nem lassítja a játékot)
		#end
		Looks.load();
		Lang.load(); // a választott nyelv (cheat-menü: LANGUAGE), a böngésző megjegyzi
		Prefs.load(); // eszköz-súgó be / ki (beállítások menü)
		#if (cheats && js)
		// fejlesztői mentés: az előző munkamenet utolsó állapotából dátumozott mentés lesz (cheat-menü: SAVE STATES),
		// és az oldal elhagyásakor (frissítés, bezárás, élő újratöltés) a pillanatnyi állapot elmentődik
		DevSave.snapshotOnLoad();
		js.Browser.window.addEventListener("pagehide", (_) ->
		{
			var ps = Std.downcast(FlxG.state, PlayState);
			if (ps != null)
				DevSave.saveLatest(ps.devSnapshot());
		});
		#end
		DevReload.init(); // dev build: élő újratöltés új dev build esetén
		amber = new AmberShader();
		var filter = new ShaderFilter(amber);
		// a kamera szűrője állapotváltáskor elvész (új kamera), ezért minden váltás után újra beállítjuk
		FlxG.signals.postStateSwitch.add(() ->
		{
			tiredTarget = 0;
			hitFx = 0;
			Rumble.stop();
			focusT = 0;
			pauseTarget = 0;
			pauseNow = 0;
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
			#if desktop
			// az ablak (Windows: tálca, macOS: Dock) ikonja a játék ikonja, futás közben beállítva
			try
			{
				var img = lime.utils.Assets.getImage("assets/icon.png");
				if (img != null && lime.app.Application.current != null && lime.app.Application.current.window != null)
					lime.app.Application.current.window.setIcon(img);
			}
			catch (e:Dynamic) {}
			#end
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
			pauseNow += (pauseTarget - pauseNow) * Math.min(1, FlxG.elapsed * 7.0);
			if (Math.abs(pauseTarget - pauseNow) < 0.002)
				pauseNow = pauseTarget;
			amber.uPause.value = [pauseNow];
			// hangminőség az APU szintjéből (globális effekt-lánc)
			AudioFx.update();
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
		#if js
		var qs = js.Browser.location.search;
		#else
		// Windows (HashLink): ugyanezek parancssori argumentumként: Amber.exe level=3 goto=exit
		var qs = "?" + Sys.args().join("&");
		#end
		var direct = false;
		var lm = ~/[?&]level=([0-9]+)/;
		if (lm.match(qs))
		{
			PlayState.level = Std.parseInt(lm.matched(1));
			direct = true;
		}
		// ?map=level0: tetszőleges beágyazott pályafájl (levels/<név>.tmj), lásd PlayState.cheatGotoFile
		var mm = ~/[?&]map=([A-Za-z0-9_-]+)/;
		if (mm.match(qs))
		{
			var idx = Levels.indexOfFile(mm.matched(1));
			if (idx >= 0)
				PlayState.level = idx;
			else
			{
				LevelLoader.fileOverride = mm.matched(1);
				LevelLoader.overrideLevel = 0;
				PlayState.level = 0;
			}
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
		#if !js
		// rumbletest=1 (asztali cheat-build): a kontroller(ek) kiírása és három próba-rezgés (hibakereséshez)
		// fpslog=1 (asztali cheat-build): 2 mp-enként a képkocka-idők (átlag / legnagyobb, ms) és a 20 ms fölötti akadások száma
		if (qs.indexOf("fpslog=1") >= 0)
		{
			var last = haxe.Timer.stamp(), sum = 0.0, mx = 0.0, n = 0, slow = 0, acc = 0.0;
			var t0 = 0.0, upd = 0.0, drw = 0.0;
			FlxG.signals.preUpdate.add(() -> t0 = haxe.Timer.stamp());
			FlxG.signals.postUpdate.add(() -> upd += (haxe.Timer.stamp() - t0) * 1000);
			FlxG.signals.preDraw.add(() -> t0 = haxe.Timer.stamp());
			FlxG.signals.postDraw.add(() ->
			{
				var now = haxe.Timer.stamp();
				drw += (now - t0) * 1000;
				var dt = (now - last) * 1000;
				last = now;
				sum += dt;
				n++;
				acc += dt;
				if (dt > mx)
					mx = dt;
				if (dt > 20)
					slow++;
				if (dt > 100)
					Sys.println('FPSLOG spike ${Math.round(dt)}ms at frame-time ${Math.round(now * 1000) % 100000}');
				if (acc >= 2000)
				{
					Sys.println('FPSLOG avg=${Math.round(sum / n * 10) / 10}ms max=${Math.round(mx)}ms slow=$slow frames=$n update=${Math.round(upd / n * 10) / 10}ms draw=${Math.round(drw / n * 10) / 10}ms');
					upd = 0;
					drw = 0;
					sum = 0;
					mx = 0;
					n = 0;
					slow = 0;
					acc = 0;
				}
			});
		}
		if (qs.indexOf("rumbletest=1") >= 0 || qs.indexOf("rumblelist=1") >= 0)
			FlxG.signals.postGameStart.addOnce(() -> Rumble.selfTest(qs.indexOf("rumbletest=1") >= 0));
		#end
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
			toggleFullscreen();
		});
		#else
		// asztali (Windows, HashLink) változat: az F billentyűt képkockánként olvassuk
		FlxG.signals.postUpdate.add(() ->
		{
			if (FlxG.keys.justPressed.F)
				toggleFullscreen();
		});
		#if hl
		// a lime HL-kötése a címet UTF-16 bájtokként adja át (az első 0 bájtnál elvágódik: "A"):
		// a kívánt bájtokat (Windowson ANSI kódlap: Windows-1250 / 1252, az Ä mindkettőben 0xC4; máshol UTF-8) kettesével egy-egy karakterbe csomagoljuk
		var win = lime.app.Application.current != null ? lime.app.Application.current.window : null;
		if (win != null)
		{
			#if windows
			var b = haxe.io.Bytes.ofHex("c46d626572"); // "Ämber" (ANSI)
			#else
			var b = haxe.io.Bytes.ofString("Ämber"); // macOS / Linux: az SDL UTF-8-at vár
			#end
			var t = new StringBuf();
			var i = 0;
			while (i < b.length)
			{
				t.addChar(b.get(i) | ((i + 1 < b.length ? b.get(i + 1) : 0) << 8));
				i += 2;
			}
			win.title = t.toString();
		}
		#end
		#end
	}

	/**
		Teljes képernyő be / ki (F billentyű, beállítások menü). A böngésző csak friss billentyű- / egéresemény után engedi
		(Chrome / Edge: néhány másodpercig tartó "felhasználói aktiválás", ezért a képkockánként olvasott billentyűből is működik);
		a kontroller gombja nem számít ilyennek: onnan nem kapcsolható be.
	**/
	public static function toggleFullscreen():Void
	{
		#if js
		js.Syntax.code("var d = document;
			var p = d.fullscreenElement ? d.exitFullscreen() : d.documentElement.requestFullscreen();
			if (p && p.catch) p.catch(function () {});");
		#else
		FlxG.fullscreen = !FlxG.fullscreen;
		#end
	}

	public static function isFullscreen():Bool
	{
		#if js
		return js.Syntax.code("!!document.fullscreenElement");
		#else
		return FlxG.fullscreen;
		#end
	}
}
