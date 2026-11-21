package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;

/**
 * Ranglista-ablak (a Moonshardé alapján) két lépésben:
 *  1. névbeírás (csak ha `score` meg van adva és beküldhető: játék vége / végigjátszás után): 3 betűs név. Billentyű: fel / le betűt vált,
 *     balra / jobbra lép, betű begépelhető, Enter / Space beküld; kontroller: D-pad + A. Sikertelen küldés után ESC / B kihagyja.
 *  2. a lista: a legjobb 10 (név, pont, elért pálya / KÉSZ), a frissen beküldött sor kiemelve; ESC / Enter / ugrás / B bezár.
 * A PlayState-ben a HUD-kamerán rajzol (PlayState.openSubState).
 */
class LeaderboardSubState extends FlxSubState
{
	static inline var ROW_H:Int = 15;
	static inline var LIST_Y:Int = 66;

	var score:Int;
	var level:Int;
	var atoms:Int;
	var completed:Bool;
	var title:String;
	var entering:Bool;
	var ready:Float = 0;

	// névbeírás
	var letters:Array<Int> = [];
	var cursor:Int = 0;
	var sending:Bool = false;
	var failed:Bool = false;
	var letterTexts:Array<LangText> = [];
	var upTexts:Array<LangText> = [];
	var downTexts:Array<LangText> = [];
	var status:LangText;

	// lista
	var rows:Array<Array<LangText>> = [];
	var highlight:FlxSprite;
	var info:LangText;

	/** `score` < 0: csak a lista (címképernyőről). `title`: a fejléc a névbeírásnál (GAME OVER / ALL PARTS FOUND). */
	public function new(score:Int = -1, level:Int = 1, atoms:Int = 0, completed:Bool = false, title:String = "GAME OVER")
	{
		super(0xE0000000);
		this.score = score;
		this.level = level;
		this.atoms = atoms;
		this.completed = completed;
		this.title = title;
		entering = score >= 0 && Leaderboard.canSubmit();
	}

	override public function create():Void
	{
		super.create();
		for (c in Leaderboard.savedName().split(""))
			letters.push(c.charCodeAt(0));
		if (entering)
			buildEntry();
		else
			buildList();
	}

	function text(x:Float, y:Float, w:Float, s:String, size:Int, color:Int, align:flixel.text.FlxText.FlxTextAlign = CENTER):LangText
	{
		var t = new LangText(x, y, w, s, size);
		t.setFormat(null, size, color, align);
		t.scrollFactor.set(0, 0);
		add(t);
		return t;
	}

	// --- 1. névbeírás ---

	function buildEntry():Void
	{
		text(0, 34, FlxG.width, title, 16, 0xFFFFFFFF);
		text(0, 62, FlxG.width, "SCORE " + score + "   LEVEL " + level, 8, 0xFFBBBBBB);
		text(0, 90, FlxG.width, "ENTER YOUR NAME", 8, 0xFF999999);
		for (i in 0...Leaderboard.NAME_LEN)
		{
			var x = FlxG.width / 2 - 54 + i * 36;
			upTexts.push(text(x, 106, 36, "^", 8, 0xFF777777));
			letterTexts.push(text(x, 118, 36, "A", 16, 0xFFFFFFFF));
			downTexts.push(text(x, 140, 36, "v", 8, 0xFF777777));
		}
		status = text(0, 170, FlxG.width, "", 8, 0xFFBBBBBB);
		text(0, 236, FlxG.width, "UP / DOWN: LETTER   LEFT / RIGHT: POSITION   ENTER: SEND", 8, 0xFF777777);
		refreshEntry();
	}

	function refreshEntry():Void
	{
		for (i in 0...Leaderboard.NAME_LEN)
		{
			letterTexts[i].text = String.fromCharCode(letters[i]);
			letterTexts[i].color = i == cursor ? 0xFFFFFFFF : 0xFF888888;
			upTexts[i].visible = downTexts[i].visible = i == cursor;
		}
		status.text = sending ? "SENDING..." : (failed ? "COULD NOT SEND - ENTER: RETRY   ESC: SKIP" : "");
	}

	function changeLetter(d:Int):Void
	{
		var c = letters[cursor] - 65 + d;
		letters[cursor] = 65 + ((c % 26) + 26) % 26;
		Audio.play("blip", 0.6);
		refreshEntry();
	}

	function submit():Void
	{
		if (sending)
			return;
		sending = true;
		failed = false;
		refreshEntry();
		var name = [for (c in letters) String.fromCharCode(c)].join("");
		Leaderboard.submit(name, score, level, atoms, completed, ok ->
		{
			if (!exists)
				return;
			sending = false;
			if (ok)
			{
				Audio.play("checkpoint", 0.9);
				entering = false;
				clearAll();
				buildList();
			}
			else
			{
				failed = true;
				refreshEntry();
			}
		});
	}

	function clearAll():Void
	{
		for (m in members.copy())
			if (m != null)
			{
				remove(m, true);
				m.destroy();
			}
		letterTexts = [];
		upTexts = [];
		downTexts = [];
		rows = [];
	}

	var holdDir:Int = 0;
	var holdTime:Float = 0;

	function updateEntry(elapsed:Float):Void
	{
		if (sending)
			return;
		var n = Leaderboard.NAME_LEN;
		if (FlxG.keys.justPressed.LEFT || Input.just(FlxGamepadInputID.DPAD_LEFT))
		{
			cursor = (cursor + n - 1) % n;
			Audio.play("blip", 0.6);
			refreshEntry();
		}
		else if (FlxG.keys.justPressed.RIGHT || Input.just(FlxGamepadInputID.DPAD_RIGHT))
		{
			cursor = (cursor + 1) % n;
			Audio.play("blip", 0.6);
			refreshEntry();
		}
		// betű begépelése: a kijelölt helyre, és tovább lép
		var k:Int = FlxG.keys.firstJustPressed();
		var ka:Int = FlxKey.A, kz:Int = FlxKey.Z;
		if (k >= ka && k <= kz)
		{
			letters[cursor] = 65 + (k - ka);
			cursor = Std.int(Math.min(n - 1, cursor + 1));
			Audio.play("blip", 0.6);
			refreshEntry();
		}
		// fel / le: betűváltás, nyomva tartva ismétel (0,35 mp után 0,08 mp-enként)
		var up = FlxG.keys.pressed.UP || Input.held(FlxGamepadInputID.DPAD_UP);
		var down = FlxG.keys.pressed.DOWN || Input.held(FlxGamepadInputID.DPAD_DOWN);
		var dir = up && !down ? 1 : (down && !up ? -1 : 0);
		if (dir == 0)
		{
			holdDir = 0;
			holdTime = 0;
		}
		else if (dir != holdDir)
		{
			holdDir = dir;
			holdTime = 0;
			changeLetter(dir);
		}
		else
		{
			var before = holdTime;
			holdTime += elapsed;
			if (holdTime >= 0.35 && (before < 0.35 || Math.floor((holdTime - 0.35) / 0.08) > Math.floor((before - 0.35) / 0.08)))
				changeLetter(dir);
		}
		if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE || Input.just(FlxGamepadInputID.A))
			submit();
		else if (failed && (FlxG.keys.justPressed.ESCAPE || Input.just(FlxGamepadInputID.B)))
			close();
	}

	// --- 2. lista ---

	function buildList():Void
	{
		text(0, 22, FlxG.width, "LEADERBOARD", 16, 0xFFFFFFFF);
		highlight = new FlxSprite(110, LIST_Y);
		highlight.makeGraphic(260, ROW_H - 2, 0x40FFFFFF);
		highlight.scrollFactor.set(0, 0);
		highlight.visible = false;
		add(highlight);
		for (i in 0...Leaderboard.LIMIT)
		{
			var y = LIST_Y + i * ROW_H;
			rows.push([
				text(114, y, 26, "", 8, 0xFF999999, LEFT),
				text(142, y, 50, "", 8, 0xFFFFFFFF, LEFT),
				text(190, y, 80, "", 8, 0xFFFFFFFF, RIGHT),
				text(280, y, 40, "", 8, 0xFF999999, RIGHT),
				text(322, y, 44, "", 8, 0xFF999999, RIGHT)
			]);
		}
		info = text(0, 130, FlxG.width, "LOADING...", 8, 0xFFBBBBBB);
		text(0, 236, FlxG.width, "ESC / JUMP: BACK", 8, 0xFF777777);
		Leaderboard.fetch(list ->
		{
			if (!exists || info == null)
				return;
			if (list == null)
			{
				info.text = "OFFLINE - COULD NOT LOAD THE LEADERBOARD";
				return;
			}
			info.text = list.length == 0 ? "NO SCORES YET - BE THE FIRST!" : "";
			var found = false;
			for (i in 0...list.length)
			{
				var e = list[i];
				rows[i][0].text = (i + 1) + ".";
				rows[i][1].text = e.name;
				rows[i][2].text = Std.string(e.score);
				rows[i][3].text = e.completed ? "DONE" : "LV " + e.level;
				rows[i][4].text = e.atoms + " AT";
				if (!found && e.name == Leaderboard.lastName && e.score == Leaderboard.lastScore)
				{
					found = true;
					highlight.y = LIST_Y + i * ROW_H - 2;
					highlight.visible = true;
				}
			}
		});
	}

	function updateList():Void
	{
		if (FlxG.keys.anyJustPressed([ESCAPE, ENTER, SPACE, Z]) || Input.just(FlxGamepadInputID.B) || Input.just(FlxGamepadInputID.A))
		{
			Audio.play("blip", 0.6);
			close();
		}
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		// az első pillanatban a megnyitó gombnyomást még nem vesszük figyelembe
		if (ready < 0.25)
		{
			ready += elapsed;
			return;
		}
		if (entering)
			updateEntry(elapsed);
		else
			updateList();
	}
}
