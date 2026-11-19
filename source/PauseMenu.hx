package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import openfl.geom.Rectangle;

/**
 * Szünet-menü: keretes panel a HUD-rétegen (a játékra közben a Main.pauseTarget-tel "szünet" shader-effekt kerül, a panel éles marad).
 * Dupla keret sarokdíszekkel, fejléc-sáv (PAUSED + a pálya neve), kiválasztható sorok villogó kurzorral, alul súgó.
 * Megnyitáskor lefelé "kinyílik" (a magassága animálódik). A bemenetet a PlayState kezeli (sel, a sorok: ITEMS).
 */
class PauseMenu extends FlxGroup
{
	public static inline var RESUME = 0;
	public static inline var RESPAWN = 1;
	public static inline var SETTINGS = 2;
	public static inline var LANGUAGE = 3;
	public static inline var FULLSCREEN = 4;
	static final ITEMS = ["RESUME", "RESPAWN AT CHECKPOINT", "SETTINGS", "LANGUAGE", "FULLSCREEN"];

	static inline var W = 280;
	static inline var H = 166;
	static inline var X0 = 100;
	static inline var Y0 = 50;

	public var sel:Int = 0;
	public var count(get, never):Int;

	var panel:FlxSprite;
	var title:FlxText;
	var sub:FlxText;
	var rows:Array<FlxText> = [];
	var cursor:FlxText;
	var hint:FlxText;
	var t:Float = 0;
	var openT:Float = 0;

	function get_count():Int
		return ITEMS.length;

	public function new()
	{
		super();
		panel = new FlxSprite(X0, Y0);
		panel.makeGraphic(W, H, 0, true);
		drawPanel();
		add(panel);
		title = new LangText(X0, Y0 + 5, W, "PAUSED", 16);
		title.setFormat(null, 16, 0xFF080808, CENTER);
		add(title);
		sub = new LangText(X0, Y0 + 30, W, "", 8);
		sub.setFormat(null, 8, 0xFFBBBBBB, CENTER);
		add(sub);
		for (i in 0...ITEMS.length)
		{
			var r = new LangText(X0 + 44, Y0 + 50 + i * 18, W - 60, "", 8);
			r.setFormat(null, 8, 0xFFFFFFFF, LEFT);
			add(r);
			rows.push(r);
		}
		cursor = new FlxText(X0 + 28, 0, 16, ">", 8);
		cursor.setFormat(null, 8, 0xFFFFFFFF, LEFT);
		add(cursor);
		hint = new LangText(X0, Y0 + H - 16, W, "ENTER / A: OK    ESC / START: RESUME", 8);
		hint.setFormat(null, 8, 0xFF777777, CENTER);
		add(hint);
		forEach(b -> cast(b, FlxSprite).scrollFactor.set(0, 0));
		visible = false;
	}

	/** Dupla keret, sarokdíszek, sötét kitöltés, világos fejléc-sáv és elválasztó vonalak. */
	function drawPanel():Void
	{
		var p = panel.pixels;
		p.fillRect(new Rectangle(0, 0, W, H), 0xFFBBBBBB);
		p.fillRect(new Rectangle(2, 2, W - 4, H - 4), 0xF0060606);
		p.fillRect(new Rectangle(4, 4, W - 8, H - 8), 0xFF777777);
		p.fillRect(new Rectangle(5, 5, W - 10, H - 10), 0xF20A0A0A);
		// fejléc-sáv (a PAUSED felirat sötéten ül rajta)
		p.fillRect(new Rectangle(5, 5, W - 10, 22), 0xFFDDDDDD);
		for (x in 0...Std.int((W - 10) / 4))
			p.fillRect(new Rectangle(5 + x * 4, 25, 2, 2), 0xFF777777);
		// elválasztó a menüsorok fölött és a súgó fölött
		p.fillRect(new Rectangle(16, 44, W - 32, 1), 0xFF555555);
		p.fillRect(new Rectangle(16, H - 20, W - 32, 1), 0xFF555555);
		// sarokdíszek (kis négyzetek a külső keret sarkain)
		for (cx in [0, W - 6])
			for (cy in [0, H - 6])
			{
				p.fillRect(new Rectangle(cx, cy, 6, 6), 0xFFFFFFFF);
				p.fillRect(new Rectangle(cx + 2, cy + 2, 2, 2), 0xFF060606);
			}
		panel.dirty = true;
	}

	public function show(levelTitle:String):Void
	{
		sel = RESUME;
		t = 0;
		// (ha épp csukódott, onnan nyílik vissza)
		if (!closing)
			openT = 0;
		closing = false;
		sub.text = levelTitle;
		visible = true;
		refresh();
	}

	/** Csukódik (a nyitás fordítottja), és csak a végén tűnik el. */
	var closing:Bool = false;

	public function hide():Void
	{
		if (visible)
			closing = true;
	}

	public function refresh():Void
	{
		for (i in 0...ITEMS.length)
		{
			rows[i].text = i == FULLSCREEN ? "FULLSCREEN   " + (Main.isFullscreen() ? "ON" : "OFF") : (i == LANGUAGE ? "LANGUAGE   " + Lang.displayName() : ITEMS[i]);
			rows[i].color = i == sel ? 0xFFFFFFFF : 0xFF999999;
		}
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (!visible)
			return;
		t += elapsed;
		// kinyílás / csukódás: a panel a közepéből függőlegesen kinyílik (0,18 mp; a Flixel a sprite közepéből skáláz), illetve összecsukódik;
		// közben a tartalom rejtve
		if (closing)
		{
			openT = Math.max(0, openT - elapsed / 0.15);
			if (openT <= 0)
			{
				closing = false;
				visible = false;
				return;
			}
		}
		else
			openT = Math.min(1, openT + elapsed / 0.18);
		panel.scale.y = Math.max(0.02, 1 - Math.pow(1 - openT, 3));
		var shown = openT >= 1 && !closing;
		title.visible = sub.visible = hint.visible = shown;
		for (r in rows)
			r.visible = shown;
		// kurzor: a kijelölt sor előtt, ütemesen villog és kicsit "lélegzik"
		cursor.visible = shown && (t % 0.6) < 0.42;
		cursor.y = rows[sel].y;
		cursor.x = X0 + 28 + Math.sin(t * 6) * 1.5;
		// a FULLSCREEN sor a böngésző állapotát követi
		if (shown)
			refresh();
	}
}
