package;

import flixel.FlxG;
import flixel.FlxState;
import flixel.text.FlxText;

/** Záróképernyő a 5. pálya után. */
class EndState extends FlxState
{
	var t:Float = 0;
	var prompt:FlxText;

	override public function create():Void
	{
		super.create();
		bgColor = 0xFF000000;
		FlxG.camera.fade(0xFF000000, 0.5, true);
		var a = new LangText(0, 70, 480, "ALL PARTS FOUND", 16);
		a.setFormat(null, 16, 0xFFFFFFFF, CENTER);
		add(a);
		var b = new LangText(0, 100, 480, "THE ROBOT IS WHOLE AGAIN", 16);
		b.setFormat(null, 16, 0xFFBBBBBB, CENTER);
		add(b);
		var c = new LangText(0, 150, 480, "FINAL SCORE " + PlayState.totalScore, 8);
		c.setFormat(null, 8, 0xFFFFFFFF, CENTER);
		add(c);
		prompt = new LangText(0, 200, 480, "PRESS JUMP", 8);
		prompt.setFormat(null, 8, 0xFF777777, CENTER);
		add(prompt);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		t += elapsed;
		prompt.visible = Std.int(t * 2) % 2 == 0;
		if (t > 0.8 && Input.confirmPressed())
		{
			PlayState.level = 0;
			PlayState.totalScore = 0;
			Parts.reset();
			Companions.reset();
			FlxG.switchState(() -> new TitleState());
		}
	}
}
