package;

#if cheats
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.text.FlxText;
import MiniGames.MiniGame;

/** Egy cheat-menüpont: felirat (dinamikus) és a művelet; a művelet true-val zárja be a menüt. */
typedef CheatItem =
{
	label:Void->String,
	run:Void->Bool,
	/** Ikon a sor előtt: 0..9 = alkatrész, ICON_ATOM, ICON_BATT; -1 / hiányzó = nincs. */
	?icon:Int
}

/**
 * Cheat-menü (F9 / kontroller: SELECT): csak fejlesztői buildben (-debug, -Dtest, -Dcheats), a release-ben nincs benne.
 * Lapozható: a főlapról kategóriákba lehet lépni; a legtöbb elem alkalmazza a hatást és bezár, a kapcsolók nyitva maradnak.
 * Vezérlés: fel / le (D-pad, bal pálca) választ, Space / Enter / A használ, Esc / B / F9 vissza (főlapon bezár).
 * A hatásokat a `PlayState.cheat*` függvények végzik.
 */
class CheatSubState extends FlxSubState
{
	static inline var ROWS:Int = 12;
	static inline var ICON_ATOM:Int = 100;
	static inline var ICON_BATT:Int = 101;
	/** Soronként három ikon-sprite (alkatrész / atom / akku): a megfelelő látszik a sor szövege előtt. */
	var partIc:Array<FlxSprite> = [];
	var atomIc:Array<FlxSprite> = [];
	var battIc:Array<FlxSprite> = [];

	var game:PlayState;
	/** Ha mini-játékból nyílt: az a mini-játék (a lista szűkebb, és megoldható). */
	var mini:MiniGame;
	var title:FlxText;
	var rows:Array<FlxText> = [];
	var more:FlxText;
	var page:String = "main";
	var items:Array<CheatItem> = [];
	var sel:Int = 0;
	var top:Int = 0;
	var stickPrev:Int = 0;
	/** A megnyitás óta eltelt idő: az első 0,4 mp-ben nem zár be (a megnyitó gombnyomás villanásai ne csukják be rögtön). */
	var age:Float = 0;
	var padInfo:FlxText;
	var padInfoT:Float = 0;
	var pendingPage:Null<String> = null;
	var backStack:Array<String> = [];

	public function new(game:PlayState, ?mini:MiniGame)
	{
		super(0xE0101010);
		this.game = game;
		this.mini = mini;
		Cheats.used = true;
	}

	override public function create():Void
	{
		super.create();
		title = new FlxText(0, 10, FlxG.width, "", 16);
		title.alignment = CENTER;
		title.scrollFactor.set(0, 0);
		add(title);
		for (i in 0...ROWS)
		{
			var t = new FlxText(0, 36 + i * 15, FlxG.width, "", 8);
			t.alignment = CENTER;
			t.scrollFactor.set(0, 0);
			add(t);
			rows.push(t);
			var p = new FlxSprite(0, t.y - 1);
			p.loadGraphic(Art.partIcons(), true, 10, 10, false, "parts");
			var a = new FlxSprite(0, t.y);
			a.loadGraphic(Art.atom(), true, 8, 8, false, "atom");
			a.animation.add("spin", [0, 1, 2, 3], 6);
			a.animation.play("spin");
			var b = new FlxSprite(0, t.y - 1);
			b.loadGraphic(Art.battery(), true, 8, 10, false, "battery");
			for (s in [p, a, b])
			{
				s.scrollFactor.set(0, 0);
				s.visible = false;
				add(s);
			}
			partIc.push(p);
			atomIc.push(a);
			battIc.push(b);
		}
		more = new FlxText(0, 218, FlxG.width, "", 8);
		more.alignment = CENTER;
		more.scrollFactor.set(0, 0);
		add(more);
		var hint = new FlxText(0, 248, FlxG.width, "UP / DOWN SELECT    SPACE / A USE    ESC / B / R2 BACK", 8);
		hint.alignment = CENTER;
		hint.color = 0xFF888888;
		hint.scrollFactor.set(0, 0);
		add(hint);
		padInfo = new FlxText(0, 236, FlxG.width, "", 8);
		padInfo.alignment = CENTER;
		padInfo.color = 0xFF55AA55;
		padInfo.scrollFactor.set(0, 0);
		add(padInfo);
		buildPage("main");
	}

	function openPage(p:String):Void
	{
		pendingPage = p;
	}

	function item(label:String, run:Void->Bool):CheatItem
		return {label: () -> label, run: run};

	function dyn(label:Void->String, run:Void->Bool):CheatItem
		return {label: label, run: run};

	/** Ikont ad a menüponthoz. */
	function ico(it:CheatItem, icon:Int):CheatItem
	{
		it.icon = icon;
		return it;
	}

	function sub(label:String, p:String):CheatItem
		return item(label + " >", () ->
		{
			backStack.push(page);
			openPage(p);
			return false;
		});

	/** Egy művelet: lefut, a menü bezárul (hogy a hatás látszódjon). */
	function act(label:String, f:Void->Void):CheatItem
		return item(label, () ->
		{
			f();
			return true;
		});

	/** Egy művelet, ami után a menü nyitva marad. */
	function keep(label:String, f:Void->Void):CheatItem
		return item(label, () ->
		{
			f();
			return false;
		});

	function itemsFor(p:String):Array<CheatItem>
	{
		var g = game;
		switch (p)
		{
			case "hero":
				return [
					act("HEAL TO FULL", g.cheatHeal),
					act("TAKE A HIT (SHOCK EFFECT)", g.cheatDamage),
					act("KILL (SIGNAL LOST)", g.cheatKill),
					act("MOVE HERO TO THE EXIT DOOR", g.cheatToDoor),
					act("RESET WALL / FALL STUCK (TELEPORT UP)", g.cheatUnstick)
				];
			case "parts":
				var l:Array<CheatItem> = [];
				for (i in 0...Parts.COUNT)
					l.push(ico(dyn(() -> "GIVE " + Parts.NAMES[i] + (Parts.has(i) ? "  (TIER " + Parts.tier(i) + ")" : ""), () ->
					{
						g.cheatPart(i);
						return false;
					}), i));
				l.push(ico(keep("GIVE 100 ATOMS", () -> g.cheatAtoms(100)), ICON_ATOM));
				l.push(act("ALL PARTS", g.cheatAllParts));
				l.push(act("PARTS OF PREVIOUS LEVELS", g.cheatPartsOfEarlierLevels));
				l.push(act("STRIP ALL PARTS (NAKED ROBOT)", g.cheatStripParts));
				return l;
			case "screen":
				return [
					ico(keep("BATTERY 100%", () -> g.cheatBattery(100)), ICON_BATT),
					ico(keep("BATTERY 50%", () -> g.cheatBattery(50)), ICON_BATT),
					ico(keep("BATTERY 20% (TIRED)", () -> g.cheatBattery(20)), ICON_BATT),
					ico(keep("BATTERY 5%", () -> g.cheatBattery(5)), ICON_BATT),
					ico(act("BATTERY EMPTY (POWER DOWN)", g.cheatPowerDown), ICON_BATT),
					keep("ELECTRIC SHOCK FLASH", g.cheatShock),
					dyn(() -> "TIRED SCREEN FX: " + g.cheatTiredName(), () ->
					{
						g.cheatCycleTired();
						return false;
					}),
					dyn(() -> "BLURRY SIGHT: " + (g.cheatSight ? "ON" : "OFF"), () ->
					{
						g.cheatSight = !g.cheatSight;
						return false;
					})
				];
			case "look":
				// a választás azonnal látszik, és megmarad a következő betöltéskor (a menü nyitva marad: lehet válogatni)
				var l:Array<CheatItem> = [];
				for (i in 0...Looks.LIST.length)
					l.push(dyn(() -> (Looks.current == i ? "* " : "  ") + Looks.LIST[i].name, () ->
					{
						Looks.set(i);
						return false;
					}));
				return l;
			case "robots":
				return [
					act("ADD WHEELIE", () -> g.cheatCompanion(Companions.WHEELIE)),
					act("ADD TALL", () -> g.cheatCompanion(Companions.TALL)),
					act("ADD ORB", () -> g.cheatCompanion(Companions.ORB)),
					act("BRING ALL ROBOTS TO ME", g.cheatGather),
					dyn(() -> "FRIENDS: " + (g.cheatFollow() ? "FOLLOW" : "WAIT"), () ->
					{
						g.cheatToggleFollow();
						return false;
					}),
					act("HURT ALL FRIENDS", g.cheatHurtFriends)
				];
			case "unlock":
				var l:Array<CheatItem> = [];
				for (i in 0...g.cheatTerminalCount())
					l.push(dyn(() -> g.cheatTerminalName(i), () ->
					{
						g.cheatUnlockTerminal(i);
						return false;
					}));
				l.push(act("UNLOCK ALL TERMINALS", g.cheatSolveTerminals));
				return l;
			case "world":
				return [
					sub("UNLOCK TERMINALS", "unlock"),
					act("OPEN ALL GATES", g.cheatOpenGates),
					act("SOLVE ALL TERMINALS", g.cheatSolveTerminals),
					act("COMPLETE LEVEL (CLEAR SCREEN)", g.cheatComplete),
					act("NEXT LEVEL", g.cheatNextLevel),
					act("PREVIOUS LEVEL", g.cheatPrevLevel),
					act("RESTART LEVEL", g.cheatRestart),
					sub("JUMP TO LEVEL", "levels")
				];
			case "teleport":
				return [for (s in g.cheatSpots()) act(s.name, () -> g.cheatTeleportTo(s.x, s.y))];
			case "levels":
				return [for (i in 0...LevelData.COUNT) act("LEVEL " + (i + 1), () -> g.cheatGoto(i))];
			case "enemies":
				return [
					act("SPAWN WALKER", () -> g.cheatEnemy(LevelData.WALKER)),
					act("SPAWN FLYER", () -> g.cheatEnemy(LevelData.FLYER)),
					act("SPAWN CRAWLER", () -> g.cheatEnemy(LevelData.CRAWLER)),
					act("SPAWN HUNTER (CHASES YOU)", () -> g.cheatEnemy(LevelData.HUNTER)),
					act("KILL ALL ENEMIES", g.cheatKillEnemies)
				];
			case "minigames":
				return [for (i in 0...MiniGames.COUNT) act(MiniGames.TITLES[i], () -> g.cheatMini(i))];
			case "toggles":
				return [
					dyn(() -> "GOD MODE: " + (g.cheatGod ? "ON" : "OFF"), () ->
					{
						g.cheatGod = !g.cheatGod;
						return false;
					}),
					dyn(() -> "INFINITE BATTERY: " + (g.cheatInfBatt ? "ON" : "OFF"), () ->
					{
						g.cheatInfBatt = !g.cheatInfBatt;
						return false;
					}),
					dyn(() -> "SLOW MOTION: " + (FlxG.timeScale < 1 ? "ON" : "OFF"), () ->
					{
						FlxG.timeScale = FlxG.timeScale < 1 ? 1 : 0.3;
						return false;
					})
				];
			default:
				if (mini != null)
					return [
						act("SOLVE THIS MINI-GAME NOW", mini.cheatSolve),
						sub("UNLOCK TERMINALS", "unlock"),
						sub("PARTS", "parts"),
						sub("BATTERY & SCREEN EFFECTS", "screen"),
						sub("TOGGLES", "toggles"),
						item("CLOSE", () -> true)
					];
				return [
					sub("HERO", "hero"),
					sub("PARTS", "parts"),
					sub("BATTERY & SCREEN EFFECTS", "screen"),
					sub("LOOK (SHADER STYLES)", "look"),
					sub("ROBOTS (FRIENDS)", "robots"),
					sub("TELEPORT IN THIS LEVEL", "teleport"),
					sub("WORLD & LEVELS", "world"),
					sub("ENEMIES", "enemies"),
					sub("MINI-GAMES", "minigames"),
					sub("TOGGLES", "toggles"),
					item("CLOSE", () -> true)
				];
		}
	}

	function buildPage(p:String):Void
	{
		page = p;
		items = itemsFor(p);
		sel = 0;
		top = 0;
		title.text = switch (p)
		{
			case "hero": "HERO";
			case "parts": "PARTS";
			case "screen": "BATTERY & SCREEN";
			case "robots": "ROBOTS";
			case "look": "LOOK (SAVED)";
			case "world": "WORLD";
			case "levels": "JUMP TO LEVEL";
			case "teleport": "TELEPORT";
			case "enemies": "ENEMIES";
			case "minigames": "MINI-GAMES";
			case "toggles": "TOGGLES";
			case "unlock": "UNLOCK TERMINALS";
			default: "CHEATS";
		};
		refresh();
	}

	function refresh():Void
	{
		if (sel < top)
			top = sel;
		if (sel >= top + ROWS)
			top = sel - ROWS + 1;
		for (i in 0...ROWS)
		{
			var idx = top + i;
			var t = rows[i];
			partIc[i].visible = atomIc[i].visible = battIc[i].visible = false;
			if (idx < items.length)
			{
				t.text = (idx == sel ? "> " : "  ") + items[idx].label();
				t.color = idx == sel ? 0xFFFFFFFF : 0xFF8A8A8A;
				var ic = items[idx].icon;
				if (ic != null && ic >= 0)
				{
					var s = ic == ICON_ATOM ? atomIc[i] : (ic == ICON_BATT ? battIc[i] : partIc[i]);
					if (s == partIc[i])
						s.animation.frameIndex = ic;
					s.x = Std.int(FlxG.width / 2 - t.textField.textWidth / 2 - 14);
					s.visible = true;
					s.alpha = idx == sel ? 1 : 0.55;
				}
			}
			else
				t.text = "";
		}
		more.text = items.length > ROWS ? (top > 0 ? "^ " : "  ") + (sel + 1) + "/" + items.length + (top + ROWS < items.length ? " v" : "") : "";
	}

	function goBack():Void
	{
		if (page == "main")
			close();
		else
		{
			var prev = backStack.length > 0 ? backStack.pop() : "main";
			openPage(prev);
		}
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (pendingPage != null)
		{
			var p = pendingPage;
			pendingPage = null;
			buildPage(p);
			return;
		}
		var k = FlxG.keys.justPressed;
		var sy = Input.stickY();
		var s = sy < -0.5 ? 1 : (sy > 0.5 ? 2 : 0);
		var fresh = s != stickPrev;
		stickPrev = s;
		var up = k.UP || k.W || Input.just(FlxGamepadInputID.DPAD_UP) || (fresh && s == 1);
		var down = k.DOWN || k.S || Input.just(FlxGamepadInputID.DPAD_DOWN) || (fresh && s == 2);
		var use = k.ENTER || k.SPACE || k.Z || Input.just(FlxGamepadInputID.A);
		age += elapsed;
		var pd = Input.padDebug();
		if (pd != "")
		{
			padInfo.text = "LAST PAD INPUT: " + pd;
			padInfoT = 3;
		}
		else if (padInfoT > 0 && (padInfoT -= elapsed) <= 0)
			padInfo.text = "";
		var back = age > 0.4 && (k.ESCAPE || k.F9 || Input.r2New || (Input.just(FlxGamepadInputID.B) || Input.just(FlxGamepadInputID.BACK)));
		if (back)
		{
			goBack();
			return;
		}
		if (up && items.length > 0)
			sel = (sel + items.length - 1) % items.length;
		if (down && items.length > 0)
			sel = (sel + 1) % items.length;
		if (use && items.length > 0 && items[sel].run())
		{
			close();
			return;
		}
		refresh();
	}
}
#end
