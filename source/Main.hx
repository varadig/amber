package;

import flixel.FlxG;
import flixel.FlxGame;
import openfl.display.Sprite;
import openfl.filters.ShaderFilter;

class Main extends Sprite
{
	static var amber:AmberShader;
	static var clock:Float = 0;

	public function new()
	{
		super();
		// A borostyán-monitor shader az egész játékon (a játék példányon, hogy a pásztázó-vonalak az ablak felbontásán is élesek legyenek)
		amber = new AmberShader();
		var filter = new ShaderFilter(amber);
		// a kamera szűrője állapotváltáskor elvész (új kamera), ezért minden váltás után újra beállítjuk
		FlxG.signals.postStateSwitch.add(() -> FlxG.camera.filters = [filter]);
		FlxG.signals.postGameStart.addOnce(() ->
		{
			FlxG.mouse.visible = false;
			FlxG.sound.muteKeys = [];
			FlxG.sound.volumeUpKeys = [];
			FlxG.sound.volumeDownKeys = [];
		});
		FlxG.signals.postUpdate.add(() ->
		{
			clock += FlxG.elapsed;
			amber.uTime.value = [clock];
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
