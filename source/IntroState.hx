package;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

/**
 * Bevezető az új játék elején (rövid, animált, átugorható): mi a küldetés lényege, és miért homályos a kép, miért esetlen a robot.
 *  1. elsötétült város, a robot kikapcsolva
 *  2. a robot alkatrészei szétszóródtak
 *  3. hiányzó alkatrészek -> következmények (VISOR: homályos kép, LEGS: alacsony ugrás, PROCESSOR: lomha vezérlés)
 *  4. minden alkatrész visszaad egy képességet: az élesedés bemutatója, majd indul a játék
 * Ugrás: egy lépés előre; ESC: az egész átugrása.
 */
class IntroState extends FlxState
{
	static inline var GROUND = 222;
	static final CAPTIONS = [
		["THE CITY WENT DARK.", "EVERY ROBOT FELL SILENT."],
		["YOU WAKE UP BROKEN.", "YOUR PARTS ARE SCATTERED ACROSS THE RUINS."],
		["NO PARTS, NO ABILITIES:", "BLURRY FAR SIGHT, WEAK LEGS, SLOW REFLEXES."],
		["FIND THE PARTS. EACH ONE RESTORES A SYSTEM.", "THEN REACH THE EXIT DOOR."]
	];

	/** Teszt: nincs automatikus jelenet-váltás. */
	public static var manual:Bool = false;
	var scene:Int = -1;
	var sceneT:Float = 0;
	var stage:FlxGroup;
	var robot:FlxSprite;
	var capLines:Array<FlxText> = [];
	var capFull:Array<String> = [];
	var capChars:Float = 0;
	var icons:Array<FlxSprite> = [];
	var tags:Array<FlxGroup> = [];
	var hint:FlxText;
	var uiCam:FlxCamera;
	var leaving:Bool = false;
	var focused:Bool = false;
	var age:Float = 0;

	override public function create():Void
	{
		super.create();
		bgColor = 0xFF000000;
		FlxG.camera.fade(0xFF000000, 0.4, true);
		var stars = new FlxSprite(0, -40);
		stars.loadGraphic(Art.stars(960, 5), false, 0, 0, false, "tstars");
		add(stars);
		var city = new FlxSprite(0, -50);
		city.loadGraphic(Art.backdrop(960, 9, "5", 70), false, 0, 0, false, "tbd9");
		city.alpha = 0.55;
		add(city);
		var tiles = Art.tiles();
		for (i in 0...30)
		{
			var top = new FlxSprite(i * 16, GROUND);
			top.loadGraphic(tiles, true, 16, 16, false, "ttiles");
			top.animation.frameIndex = 1;
			add(top);
			for (r in 0...3)
			{
				var f = new FlxSprite(i * 16, GROUND + 16 + r * 16);
				f.loadGraphic(tiles, true, 16, 16, false, "ttiles");
				f.animation.frameIndex = 2;
				add(f);
			}
		}
		stage = new FlxGroup();
		add(stage);
		// a robot: csupasz alváz, nagyítva (12 x 14 -> 48 x 56)
		robot = new FlxSprite(234 - 6, 0);
		robot.loadGraphic(Art.player(0), true, 12, 14, false, "player");
		robot.animation.add("off", [10], 1);
		robot.animation.add("idle", [0], 1);
		robot.animation.add("jump", [5], 1);
		robot.animation.add("fall", [6], 1);
		robot.animation.play("off");
		robot.scale.set(4, 4);
		add(robot);
		// a feliratok külön kamerán (a látás-homály ne érje őket): borostyán árnyalat, de effektek nélkül
		uiCam = new FlxCamera(0, 0, FlxG.width, FlxG.height);
		uiCam.bgColor = 0x00000000;
		uiCam.filters = [new openfl.filters.ShaderFilter(new HudShader())];
		FlxG.cameras.add(uiCam, false);
		for (i in 0...2)
		{
			var l = new LangText(0, 232 + i * 12, 480, "", 8);
			l.setFormat(null, 8, 0xFFFFFFFF, LEFT);
			l.cameras = [uiCam];
			add(l);
			capLines.push(l);
		}
		hint = new LangText(0, 258, 480, "JUMP: NEXT     ESC: SKIP", 8);
		hint.setFormat(null, 8, 0xFF777777, CENTER);
		hint.cameras = [uiCam];
		add(hint);
		robotY(0);
		next();
	}

	/** A robot függőleges eltolása a talajhoz képest (felfelé pozitív). */
	function robotY(lift:Float):Void
		robot.y = GROUND - 14 - 21 - lift;

	function setCaption(i:Int):Void
	{
		// a feliratot előre fordítjuk: a gépelés részszövegei már nem lennének a szótárban (a magyar szöveg a LangText-en változatlanul átmegy)
		capFull = [for (l in CAPTIONS[i]) Lang.t(l)];
		capChars = 0;
		for (k in 0...capLines.length)
		{
			capLines[k].text = capFull.length > k ? capFull[k] : "";
			capLines[k].x = 240 - capLines[k].textField.textWidth / 2 - 2; // a teljes sor szélességéhez igazítva (gépelés közben sem ugrál)
			capLines[k].text = "";
		}
	}

	function next():Void
	{
		scene++;
		if (scene >= CAPTIONS.length)
		{
			finish();
			return;
		}
		sceneT = 0;
		focused = false;
		stage.forEach(s -> s.destroy());
		stage.clear();
		icons = [];
		tags = [];
		setCaption(scene);
		Audio.play("select", 0.5);
		switch (scene)
		{
			case 1:
				// az alkatrészek kirepülnek a robotból és szétszóródnak
				robot.animation.play("idle");
				var targets = [[40, 70], [90, 130], [150, 60], [200, 120], [270, 70], [330, 125], [390, 60], [430, 120], [60, 175], [420, 175]];
				for (i in 0...Parts.COUNT)
				{
					var s = new FlxSprite(234, 190);
					s.loadGraphic(Art.partIcons(), true, 10, 10, false, "parts");
					s.animation.frameIndex = i;
					s.scale.set(3, 3);
					s.alpha = 0;
					stage.add(s);
					icons.push(s);
					FlxTween.tween(s, {x: targets[i][0], y: targets[i][1], alpha: 1}, 0.8, {startDelay: 0.5 + i * 0.12, ease: FlxEase.quadOut});
				}
			case 2:
				robot.animation.play("idle");
				var rowIcon = [Parts.VISOR, Parts.LEGS, Parts.CHIP, Parts.AUDIO];
				var rowText = ["NO GPU: ONLY NEAR SIGHT, FAR IS BLURRY", "NO LEGS: SLOW, LOW JUMPS", "NO CPU: LAGGY CONTROLS", "NO APU: MUFFLED, CRACKLY SOUND"];
				for (i in 0...rowIcon.length)
				{
					var g = new FlxGroup();
					var ic = new FlxSprite(96, 48 + i * 26);
					ic.loadGraphic(Art.partIcons(), true, 10, 10, false, "parts");
					ic.animation.frameIndex = rowIcon[i];
					ic.scale.set(2, 2);
					g.add(ic);
					var t = new LangText(120, 48 + i * 26 + 3, 300, rowText[i], 8);
					t.setFormat(null, 8, 0xFFFFFFFF, LEFT);
					g.add(t);
					// áthúzás: a hiányzó rész jele
					var x = new LangText(88, 48 + i * 26 + 1, 20, "X", 16);
					x.setFormat(null, 16, 0xFFFFFFFF, LEFT);
					g.add(x);
					g.forEach(s -> cast(s, FlxSprite).visible = false);
					g.cameras = [uiCam];
					tags.push(g);
					stage.add(g);
				}
			case 3:
				// a VISOR a robotba repül: élesedik a kép (a játék VISOR-felvételi effektje)
				robot.animation.play("idle");
				var s = new FlxSprite(60, 60);
				s.loadGraphic(Art.partIcons(), true, 10, 10, false, "parts");
				s.animation.frameIndex = Parts.VISOR;
				s.scale.set(3, 3);
				stage.add(s);
				icons.push(s);
				FlxTween.tween(s, {x: 234, y: 175}, 1.0, {startDelay: 0.5, ease: FlxEase.quadIn, onComplete: _ ->
				{
					s.kill();
					focused = true;
					Main.startFocus();
					Audio.play("key", 0.8);
				}});
				var ex = new LangText(380, 190, 90, "EXIT >", 8);
				ex.setFormat(null, 8, 0xFFFFFFFF, CENTER);
				ex.cameras = [uiCam];
				stage.add(ex);
			default:
				robot.animation.play("off");
		}
	}

	function finish():Void
	{
		if (leaving)
			return;
		leaving = true;
		FlxG.camera.fade(0xFF000000, 0.4, false, () -> FlxG.switchState(() -> new PlayState()));
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		age += elapsed;
		sceneT += elapsed;
		Audio.guard();
		if (leaving)
			return;
		// látás: a játék elején VISOR nélkül homályos, ahogy majd a pályán is
		Main.sightTarget = 1.0;
		Main.clearTarget = scene >= 3 && focused ? 110.0 : 52.0;
		Main.focusX = robot.x + 6;
		Main.focusY = robot.y + 7;
		// gépelődő felirat
		capChars += elapsed * 38;
		var left = Std.int(capChars);
		for (k in 0...capLines.length)
		{
			var full = capFull.length > k ? capFull[k] : "";
			var n = Std.int(Math.max(0, Math.min(full.length, left)));
			capLines[k].text = full.substr(0, n);
			left -= full.length;
		}
		switch (scene)
		{
			case 0:
				// a robot kikapcsolva, halk villódzó lámpa a háttérben: a kép sötét
				robot.alpha = 0.6 + 0.4 * (Std.int(sceneT * 3) % 2 == 0 ? 1 : 0.5);
			case 1:
				robot.alpha = 1;
				for (i in 0...icons.length)
					if (sceneT > 1.6 + i * 0.12)
						icons[i].alpha = 0.55 + 0.45 * Math.abs(Math.sin(sceneT * 3 + i));
			case 2:
				// esetlen robot: alacsony, lomha ugrások
				var hop = Math.abs(Math.sin(sceneT * 2.2)) * 8;
				robotY(hop);
				robot.animation.play(hop > 1 ? "jump" : "idle");
				robot.x = 228 + Math.sin(sceneT * 1.1) * 14;
				for (i in 0...tags.length)
					if (sceneT > 0.8 + i * 1.0)
						tags[i].forEach(s -> cast(s, FlxSprite).visible = true);
			case 3:
				// a VISOR után a robot már magasabbra ugrik
				if (focused)
				{
					var hop = Math.abs(Math.sin((sceneT - 1.6) * 3)) * 22;
					robotY(hop);
					robot.animation.play(hop > 2 ? "jump" : "idle");
				}
				else
					robotY(0);
				robot.x = 228;
				if (!manual && sceneT > 6.5)
					finish();
		}
		if (FlxG.keys.justPressed.ESCAPE)
		{
			finish();
			return;
		}
		// (teszt módban csak billentyű: a fejnélküli böngészőben látszólagos kontroller-gomb "nyomódik")
		var confirm = manual ? FlxG.keys.anyJustPressed([ENTER, SPACE, Z, UP, W, C]) : Input.confirmPressed();
		if (age > 0.5 && sceneT > 0.4 && confirm)
			next();
		else if (!manual && scene < 3 && sceneT > 4.6)
			next();
	}
}
