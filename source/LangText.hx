package;

import flixel.text.FlxText;

/**
 * FlxText fordítással: a beállított (angol) szöveget a Lang.t-n át jeleníti meg; az eredetit megőrzi (raw),
 * így nyelvváltáskor (Lang.set) újrafordítja. A játék minden szövege ezt használja (a cheat-menü kivételével).
 * A .text olvasva a megjelenített (fordított) szöveget adja: a már magyar szöveg újra beállítva változatlan marad.
 */
class LangText extends FlxText
{
	var raw:String = "";

	public function new(x = 0.0, y = 0.0, fieldWidth = 0.0, ?text:String, size = 8, embeddedFont = true)
	{
		super(x, y, fieldWidth, Lang.t(text), size, embeddedFont);
		raw = text;
		Lang.live.push(this);
	}

	override function set_text(value:String):String
	{
		raw = value;
		return super.set_text(Lang.t(value));
	}

	public function retranslate():Void
	{
		if (textField != null)
			super.set_text(Lang.t(raw));
	}

	override public function destroy():Void
	{
		Lang.live.remove(this);
		super.destroy();
	}
}
