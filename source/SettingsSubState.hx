package;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;

/** Hangbeállítások: zene és hangeffekt hangereje (fel/le: sor, bal/jobb: érték, ESC / ENTER / START: vissza). Mentve. */
class SettingsSubState extends FlxSubState
{
	var cam:FlxCamera;
	var rows:Array<FlxText> = [];
	var sel:Int = 0;
	var hint:FlxText;

	override public function create():Void
	{
		super.create();
		cam = new FlxCamera(0, 0, 480, 270);
		cam.bgColor = 0x00000000;
		FlxG.cameras.add(cam, false);
		cameras = [cam];

		var bg = new FlxSprite(0, 0).makeGraphic(480, 270, 0xDD000000);
		add(bg);
		var title = new FlxText(0, 70, 480, "SETTINGS", 16);
		title.setFormat(null, 16, 0xFFFFFFFF, CENTER);
		add(title);
		for (i in 0...2)
		{
			var r = new FlxText(0, 110 + i * 24, 480, "", 8);
			r.setFormat(null, 8, 0xFFFFFFFF, CENTER);
			add(r);
			rows.push(r);
		}
		hint = new FlxText(0, 190, 480, "UP/DOWN SELECT   LEFT/RIGHT CHANGE   ESC / START: BACK", 8);
		hint.setFormat(null, 8, 0xFF777777, CENTER);
		add(hint);
		Audio.previewOn();
		refresh();
	}

	static function bar(v:Float):String
	{
		var n = Math.round(v * 10);
		var s = "";
		for (i in 0...10)
			s += i < n ? "|" : ".";
		return "[" + s + "] " + n * 10 + "%";
	}

	function refresh():Void
	{
		rows[0].text = (sel == 0 ? "> " : "  ") + "MUSIC   " + bar(Audio.musicVolume);
		rows[1].text = (sel == 1 ? "> " : "  ") + "SFX     " + bar(Audio.sfxVolume);
		for (i in 0...2)
			rows[i].color = i == sel ? 0xFFFFD866 : 0xFFFFFFFF;
	}

	function change(d:Int):Void
	{
		if (sel == 0)
		{
			Audio.musicVolume = Math.max(0, Math.min(1, Math.round((Audio.musicVolume + d * 0.1) * 10) / 10));
			Audio.applyMusicVolume();
		}
		else
		{
			Audio.sfxVolume = Math.max(0, Math.min(1, Math.round((Audio.sfxVolume + d * 0.1) * 10) / 10));
			Audio.play("jump", 1);
		}
		refresh();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		Audio.tick();
		var k = FlxG.keys.justPressed;
		if (k.UP || k.W || Input.just(flixel.input.gamepad.FlxGamepadInputID.DPAD_UP))
		{
			sel = (sel + 1) % 2;
			refresh();
		}
		if (k.DOWN || k.S || Input.just(flixel.input.gamepad.FlxGamepadInputID.DPAD_DOWN))
		{
			sel = (sel + 1) % 2;
			refresh();
		}
		if (k.LEFT || k.A || Input.just(flixel.input.gamepad.FlxGamepadInputID.DPAD_LEFT))
			change(-1);
		if (k.RIGHT || k.D || Input.just(flixel.input.gamepad.FlxGamepadInputID.DPAD_RIGHT))
			change(1);
		if (k.ESCAPE || k.ENTER || k.P || Input.just(flixel.input.gamepad.FlxGamepadInputID.START) || Input.just(flixel.input.gamepad.FlxGamepadInputID.B))
		{
			Audio.saveVolumes();
			Audio.previewOff();
			close();
		}
	}

	override public function destroy():Void
	{
		if (cam != null)
			FlxG.cameras.remove(cam);
		super.destroy();
	}
}
