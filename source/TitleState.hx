package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;

/** Nyitóképernyő: logó, villogó felirat, a hős futása a rom-sziluett előtt. */
class TitleState extends FlxState
{
	var prompt:FlxText;
	var hero:FlxSprite;
	var t:Float = 0;
	var layers:Array<FlxSprite> = [];

	override public function create():Void
	{
		super.create();
		bgColor = 0xFF000000;
		Audio.init();

		var stars = new FlxSprite(0, -40);
		stars.loadGraphic(Art.stars(960, 5), false, 0, 0, false, "tstars");
		add(stars);
		for (cfg in [{seed: 3, tone: "5", dens: 40}, {seed: 9, tone: "6", dens: 70}])
		{
			var s = new FlxSprite(0, -50);
			s.loadGraphic(Art.backdrop(960, cfg.seed, cfg.tone, cfg.dens), false, 0, 0, false, "tbd" + cfg.seed);
			add(s);
			layers.push(s);
		}
		// talaj-csík
		var tiles = Art.tiles();
		for (i in 0...30)
		{
			var top = new FlxSprite(i * 16, 222);
			top.loadGraphic(tiles, true, 16, 16, false, "ttiles");
			top.animation.frameIndex = 1;
			add(top);
			for (r in 0...3)
			{
				var f = new FlxSprite(i * 16, 238 + r * 16);
				f.loadGraphic(tiles, true, 16, 16, false, "ttiles");
				f.animation.frameIndex = 2;
				add(f);
			}
		}
		hero = new FlxSprite(-20, 208);
		hero.loadGraphic(Art.player(), true, 12, 14, false, "player");
		hero.animation.add("run", [1, 2, 3, 4], 12);
		hero.animation.play("run");
		add(hero);

		var title = new FlxText(0, 56, 480, "AMBER", 32);
		title.setFormat(null, 32, 0xFFFFFFFF, CENTER);
		add(title);
		var title2 = new FlxText(0, 92, 480, "ASCENT", 32);
		title2.setFormat(null, 32, 0xFFBBBBBB, CENTER);
		add(title2);
		var sub = new FlxText(0, 136, 480, "REBUILD YOURSELF. THEN BUILD YOUR FRIENDS.", 8);
		sub.setFormat(null, 8, 0xFF777777, CENTER);
		add(sub);

		prompt = new FlxText(0, 168, 480, "PRESS JUMP TO START", 8);
		prompt.setFormat(null, 8, 0xFFFFFFFF, CENTER);
		add(prompt);
		var help = new FlxText(0, 254, 480, "ARROWS/WASD MOVE   Z/SPACE JUMP   X/SHIFT DASH   V/J FIRE   UP/E USE   TAB SWITCH   P PAUSE   F FULLSCREEN", 8);
		help.setFormat(null, 8, 0xFF777777, CENTER);
		add(help);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		t += elapsed;
		prompt.visible = Std.int(t * 2) % 2 == 0;
		hero.x += 70 * elapsed;
		if (hero.x > 500)
			hero.x = -20;
		layers[0].x = -((t * 6) % 480);
		layers[1].x = -((t * 14) % 480);
		if (Input.confirmPressed())
		{
			Audio.play("select", 1);
			Audio.playMusic();
			PlayState.level = 0;
			PlayState.totalScore = 0;
			Parts.reset();
			Companions.reset();
			FlxG.camera.fade(0xFF000000, 0.3, false, () -> FlxG.switchState(() -> new PlayState()));
		}
	}
}
