package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

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

		var title = new FlxText(0, 70, 480, "ÄMBER", 32);
		title.setFormat(null, 32, 0xFFFFFFFF, CENTER);
		add(title);
		var mascot = new FlxSprite(340, 62);
		mascot.loadGraphic(Art.mascot(), false, 14, 18, false, "mascot");
		mascot.scale.set(2, 2);
		mascot.updateHitbox();
		add(mascot);
		FlxTween.tween(mascot, {y: 56}, 0.9, {type: PINGPONG, ease: FlxEase.sineInOut});
		var sub = new FlxText(0, 136, 480, "REBUILD YOURSELF. THEN BUILD YOUR FRIENDS.", 8);
		sub.setFormat(null, 8, 0xFF777777, CENTER);
		add(sub);

		prompt = new FlxText(0, 168, 480, "PRESS JUMP TO START", 8);
		prompt.setFormat(null, 8, 0xFFFFFFFF, CENTER);
		add(prompt);
		var setHint = new FlxText(0, 186, 480, "O / TRIANGLE: SETTINGS (VOLUME)", 8);
		setHint.setFormat(null, 8, 0xFF777777, CENTER);
		add(setHint);
		var help = new FlxText(0, 254, 480, "ARROWS/WASD MOVE   Z/SPACE/L-CLICK JUMP   X/SHIFT DASH   V/J/R-CLICK FIRE   UP/E USE   TAB SWITCH   P PAUSE", 8);
		help.setFormat(null, 8, 0xFF777777, CENTER);
		add(help);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		t += elapsed;
		Audio.guard();
		if (subState != null)
			return;
		if (FlxG.keys.justPressed.O || Input.just(flixel.input.gamepad.FlxGamepadInputID.Y))
		{
			openSubState(new SettingsSubState());
			return;
		}
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
			FlxG.camera.fade(0xFF000000, 0.3, false, () -> FlxG.switchState(() -> new IntroState())); // a bevezető után indul a játék
		}
	}
}
