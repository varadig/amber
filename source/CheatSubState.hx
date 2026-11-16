package;

#if cheats
import flixel.FlxG;
import flixel.FlxSubState;
import flixel.text.FlxText;

/** Egy cheat-menüpont: felirat (dinamikus) és a művelet; a művelet true-val zárja be a menüt. */
typedef CheatItem =
{
	label:Void->String,
	run:Void->Bool
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

	var game:PlayState;
	var title:FlxText;
	var rows:Array<FlxText> = [];
	var more:FlxText;
	var page:String = "main";
	var items:Array<CheatItem> = [];
	var sel:Int = 0;
	var top:Int = 0;
	var stickPrev:Int = 0;
	/** Az R2 előző állapota (nyitáskor lenyomott: a megnyitó gombnyomás ne zárja be rögtön). */
	var r2Prev:Bool = true;
	var pendingPage:Null<String> = null;
	var backStack:Array<String> = [];

	public function new(game:PlayState)
	{
		super(0xE0101010);
		this.game = game;
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
					l.push(dyn(() -> "GIVE " + Parts.NAMES[i] + (Parts.has(i) ? "  (TIER " + Parts.tier(i) + ")" : ""), () ->
					{
						g.cheatPart(i);
						return false;
					}));
				l.push(act("ALL PARTS", g.cheatAllParts));
				l.push(act("STRIP ALL PARTS (NAKED ROBOT)", g.cheatStripParts));
				return l;
			case "screen":
				return [
					keep("BATTERY 100%", () -> g.cheatBattery(100)),
					keep("BATTERY 50%", () -> g.cheatBattery(50)),
					keep("BATTERY 20% (TIRED)", () -> g.cheatBattery(20)),
					keep("BATTERY 5%", () -> g.cheatBattery(5)),
					act("BATTERY EMPTY (POWER DOWN)", g.cheatPowerDown),
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
			case "world":
				return [
					act("OPEN ALL GATES", g.cheatOpenGates),
					act("SOLVE ALL TERMINALS", g.cheatSolveTerminals),
					act("COMPLETE LEVEL (CLEAR SCREEN)", g.cheatComplete),
					act("NEXT LEVEL", g.cheatNextLevel),
					act("PREVIOUS LEVEL", g.cheatPrevLevel),
					act("RESTART LEVEL", g.cheatRestart),
					sub("JUMP TO LEVEL", "levels")
				];
			case "levels":
				return [for (i in 0...LevelData.COUNT) act("LEVEL " + (i + 1), () -> g.cheatGoto(i))];
			case "enemies":
				return [
					act("SPAWN WALKER", () -> g.cheatEnemy(LevelData.WALKER)),
					act("SPAWN FLYER", () -> g.cheatEnemy(LevelData.FLYER)),
					act("SPAWN CRAWLER", () -> g.cheatEnemy(LevelData.CRAWLER)),
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
				return [
					sub("HERO", "hero"),
					sub("PARTS", "parts"),
					sub("BATTERY & SCREEN EFFECTS", "screen"),
					sub("ROBOTS (FRIENDS)", "robots"),
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
			case "world": "WORLD";
			case "levels": "JUMP TO LEVEL";
			case "enemies": "ENEMIES";
			case "minigames": "MINI-GAMES";
			case "toggles": "TOGGLES";
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
			if (idx < items.length)
			{
				t.text = (idx == sel ? "> " : "  ") + items[idx].label();
				t.color = idx == sel ? 0xFFFFFFFF : 0xFF8A8A8A;
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
		var pad = FlxG.gamepads.lastActive;
		var k = FlxG.keys.justPressed;
		var sy = pad != null ? pad.analog.value.LEFT_STICK_Y : 0.0;
		var s = sy < -0.5 ? 1 : (sy > 0.5 ? 2 : 0);
		var fresh = s != stickPrev;
		stickPrev = s;
		var up = k.UP || k.W || (pad != null && pad.justPressed.DPAD_UP) || (fresh && s == 1);
		var down = k.DOWN || k.S || (pad != null && pad.justPressed.DPAD_DOWN) || (fresh && s == 2);
		var use = k.ENTER || k.SPACE || k.Z || (pad != null && pad.justPressed.A);
		var r2 = Input.r2Held();
		var r2New = r2 && !r2Prev;
		r2Prev = r2;
		var back = k.ESCAPE || k.F9 || r2New || (pad != null && (pad.justPressed.B || pad.justPressed.BACK));
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
