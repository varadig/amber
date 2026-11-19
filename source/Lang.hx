package;

import flixel.FlxG;

/**
 * Nyelv: angol (alap) vagy magyar. A fordítás kiíráskor történik (LangText): a kód és a Tiled-pályák angol szövegeit
 * soronként fordítja: pontos egyezés (DICT), változó részeket tartalmazó minták (RULES), végül a nevek (alkatrész, pálya)
 * kifejezésenkénti cseréje (NAMES). Ami nincs a szótárban, angolul marad (a már magyar szöveg változatlanul átmegy).
 * A választás a cheat-menüből váltható (LANGUAGE), és a böngésző megjegyzi (FlxSave "amber-lang"); minden build beolvassa.
 * A pixelfontban nincs ő / ű: helyettük õ / û (a legközelebbi meglévő betű).
 */
class Lang
{
	public static var hu(default, null):Bool = false;

	static var cache:Map<String, String> = new Map();
	/** Az élő LangText-ek: nyelvváltáskor újrafordítják a szövegüket. */
	public static var live:Array<LangText> = [];

	public static function load():Void
	{
		#if js
		try
		{
			var s = new flixel.util.FlxSave();
			if (s.bind("amber-lang") && s.data.hu != null)
				hu = s.data.hu == true;
		}
		catch (e:Dynamic) {}
		#end
	}

	public static function set(on:Bool):Void
	{
		hu = on;
		cache = new Map();
		#if js
		try
		{
			var s = new flixel.util.FlxSave();
			if (s.bind("amber-lang"))
			{
				s.data.hu = on;
				s.flush();
			}
		}
		catch (e:Dynamic) {}
		#end
		for (t in live.copy())
			t.retranslate();
	}

	/** Szöveg fordítása (több sor: soronként). Angol nyelven változatlan. */
	public static function t(s:String):String
	{
		if (!hu || s == null || s == "")
			return s;
		var c = cache.get(s);
		if (c != null)
			return c;
		var out = [for (line in s.split("\n")) chars(line1(line))].join("\n");
		cache.set(s, out);
		return out;
	}

	/** Egy sor: a bal oldali kijelölő ("> " / "  ") és a szélső szóközök megmaradnak. */
	static function line1(line:String):String
	{
		if (line == "")
			return line;
		var lead = "";
		while (lead.length < line.length && line.charAt(lead.length) == " ")
			lead += " ";
		var core = line.substr(lead.length);
		if (StringTools.startsWith(core, "> "))
		{
			lead += "> ";
			core = core.substr(2);
		}
		var tail = "";
		while (core.length > 0 && core.charAt(core.length - 1) == " ")
		{
			tail += " ";
			core = core.substr(0, core.length - 1);
		}
		return lead + tr(core) + tail;
	}

	static function tr(s:String):String
	{
		var d = DICT.get(s);
		if (d != null)
			return d;
		for (r in RULES)
			if (r.re.match(s))
				return r.f(r.re);
		return names(s);
	}

	/** A nevek (alkatrészek, pályák, címkék) kifejezésenkénti cseréje, a hosszabbakkal kezdve (egész szavakra). */
	public static function names(s:String):String
	{
		if (!hu)
			return s;
		var out = s;
		for (k in nameKeys())
		{
			var i = out.indexOf(k);
			while (i >= 0)
			{
				var before = i == 0 ? " " : out.charAt(i - 1);
				var after = i + k.length >= out.length ? " " : out.charAt(i + k.length);
				if (isSep(before) && isSep(after))
				{
					var v = NAMES.get(k);
					out = out.substr(0, i) + v + out.substr(i + k.length);
					i = out.indexOf(k, i + v.length);
				}
				else
					i = out.indexOf(k, i + 1);
			}
		}
		return out;
	}

	static inline function isSep(c:String):Bool
		return c == " " || c == "(" || c == ")" || c == "," || c == ":" || c == "\n";

	static var sortedKeys:Array<String> = null;

	static function nameKeys():Array<String>
	{
		if (sortedKeys == null)
		{
			sortedKeys = [for (k in NAMES.keys()) k];
			sortedKeys.sort((a, b) -> b.length - a.length);
		}
		return sortedKeys;
	}

	/** A pixelfontban nincs ő / ű. */
	static function chars(s:String):String
	{
		if (s.indexOf("Ő") < 0 && s.indexOf("Ű") < 0 && s.indexOf("ő") < 0 && s.indexOf("ű") < 0)
			return s;
		return s.split("Ő").join("Õ").split("Ű").join("Û").split("ő").join("õ").split("ű").join("û");
	}

	/** Fejlesztés-leírás (Parts.INFO / INFO2 / UP) fordítása. */
	static inline function info(s:String):String
	{
		var d = DICT.get(s);
		return d != null ? d : names(s);
	}

	// --- Nevek (alkatrészek, társ-alkatrészek, pályák, címkék) ---
	static final NAMES:Map<String, String> = [
		// pályák
		"RUSTED CAVES" => "ROZSDÁS BARLANGOK", "COPPER WELLS" => "RÉZKUTAK", "NEON RUINS" => "NEONROMOK", "DEEP STATIC" => "MÉLY ZAJ",
		"THE HOLLOW" => "AZ ÜREG", "SIGNAL TOWERS" => "JELTORNYOK", "GLASS GARDEN" => "ÜVEGKERT", "BLACK RELAY" => "FEKETE RELÉ",
		"THE LONG DARK" => "A HOSSZÚ SÖTÉT", "THE AMBER CORE" => "A BOROSTYÁNMAG",
		// alkatrészek
		"LEGS" => "LÁBAK", "CORE" => "ENERGIAMAG", "VISOR" => "VIZOR", "THRUSTER" => "HAJTÓMŰ", "CLAWS" => "KARMOK", "BLASTER" => "SUGÁRVETŐ",
		"PROCESSOR" => "PROCESSZOR", "SERVOS" => "SZERVÓK", "ANTENNA" => "ANTENNA", "JET CELL" => "HAJTÓCELLA",
		"SPRINGS" => "RUGÓK", "REACTOR" => "REAKTOR", "CIRCUIT" => "ÁRAMKÖR", "CANNON" => "ÁGYÚ", "RADIO" => "RÁDIÓ", "ACTUATOR" => "AKTUÁTOR",
		"BOOSTER" => "GYORSÍTÓ", "LENS" => "LENCSE", "FINAL CORE" => "VÉGSŐ MAG",
		// társ-alkatrészek
		"SMALL FRAME" => "KIS VÁZ", "WHEEL MOTOR" => "KERÉKMOTOR", "TINY HEAD" => "APRÓ FEJ", "LONG LEGS" => "HOSSZÚ LÁBAK",
		"TALL FRAME" => "MAGAS VÁZ", "HEAD LAMP" => "FEJLÁMPA", "GLASS BULB" => "ÜVEGBURA", "ROTOR" => "ROTOR", "SPARK CORE" => "SZIKRAMAG",
		// címkék
		"WORKBENCH" => "SZERELŐASZTAL", "EXIT" => "KIJÁRAT", "BONUS" => "BÓNUSZ", "ARCHIVE" => "ARCHÍVUM", "ROBOT" => "ROBOT",
		"ENTER BUILDING" => "BE AZ ÉPÜLETBE", "LEAVE BUILDING" => "KI AZ ÉPÜLETBŐL"
	];

	// --- Pontos (teljes soros) fordítások ---
	static final DICT:Map<String, String> = [
		// címképernyő, vége, bevezető
		"REBUILD YOURSELF. THEN BUILD YOUR FRIENDS." => "ÉPÍTSD ÚJRA MAGAD. AZTÁN A TÁRSAIDAT.",
		"PRESS JUMP TO START" => "UGRÁS: INDULÁS",
		"O / TRIANGLE: SETTINGS    F: FULLSCREEN" => "O / HÁROMSZÖG: BEÁLLÍTÁSOK    F: TELJES KÉPERNYŐ",
		"F: FULLSCREEN" => "F: TELJES KÉPERNYŐ",
		"ARROWS/WASD MOVE   Z/SPACE/L-CLICK JUMP   X/SHIFT DASH   V/J/R-CLICK FIRE   UP/E USE   TAB SWITCH   P PAUSE" => "NYILAK/WASD: MOZGÁS   Z/SPACE/BAL KATT: UGRÁS   X/SHIFT: SZÖKELLÉS   V/J/JOBB KATT: LÖVÉS   FEL/E: HASZNÁL   TAB: VÁLTÁS   P: SZÜNET",
		"ALL PARTS FOUND" => "MINDEN ALKATRÉSZ MEGVAN", "THE ROBOT IS WHOLE AGAIN" => "A ROBOT ÚJRA ÉP", "PRESS JUMP" => "NYOMJ UGRÁST",
		"THE CITY WENT DARK." => "A VÁROS ELSÖTÉTÜLT.", "EVERY ROBOT FELL SILENT." => "MINDEN ROBOT ELNÉMULT.",
		"YOU WAKE UP BROKEN." => "ÖSSZETÖRVE ÉBREDSZ.", "YOUR PARTS ARE SCATTERED ACROSS THE RUINS." => "AZ ALKATRÉSZEID SZÉTSZÓRVA A ROMOK KÖZÖTT.",
		"NO PARTS, NO ABILITIES:" => "NINCS ALKATRÉSZ, NINCS KÉPESSÉG:", "BLURRY FAR SIGHT, WEAK LEGS, SLOW REFLEXES." => "HOMÁLYOS LÁTÁS, GYENGE LÁBAK, LASSÚ REFLEXEK.",
		"FIND THE PARTS. EACH ONE RESTORES A SYSTEM." => "KERESD MEG AZ ALKATRÉSZEKET: MINDEGYIK HELYREÁLLÍT EGY RENDSZERT.",
		"THEN REACH THE EXIT DOOR." => "AZTÁN JUSS EL A KIJÁRATIG.", "JUMP: NEXT     ESC: SKIP" => "UGRÁS: TOVÁBB     ESC: KIHAGY",
		"NO VISOR: ONLY NEAR SIGHT, FAR IS BLURRY" => "NINCS VIZOR: CSAK KÖZELRE LÁTSZ", "NO LEGS: SLOW, LOW JUMPS" => "NINCS LÁB: LASSÚ, KIS UGRÁSOK",
		"NO PROCESSOR: LAGGY CONTROLS" => "NINCS PROCESSZOR: KÉSIK AZ IRÁNYÍTÁS", "EXIT >" => "KIJÁRAT >",
		// beállítások
		"SETTINGS" => "BEÁLLÍTÁSOK", "UP/DOWN SELECT   LEFT/RIGHT CHANGE   ESC / START: BACK" => "FEL/LE: VÁLASZT   BALRA/JOBBRA: ÁLLÍT   ESC / START: VISSZA",
		// szünet, halál
		"PAUSED" => "SZÜNET", "ESC / P / START: RESUME" => "ESC / P / START: FOLYTATÁS",
		"R / SQUARE / SHARE: RESPAWN AT CHECKPOINT" => "R / NÉGYZET / SHARE: VISSZA A MENTÉSI PONTRA",
		"O / TRIANGLE: SETTINGS (VOLUME, FULLSCREEN)" => "O / HÁROMSZÖG: BEÁLLÍTÁSOK (HANGERŐ, TELJES KÉPERNYŐ)",
		"GAME OVER" => "VÉGE A JÁTÉKNAK", "ALL BACKUPS LOST: BACK TO THE START" => "MINDEN MENTÉS ELVESZETT: VISSZA AZ ELEJÉRE", "SIGNAL LOST" => "ELVESZETT A JEL",
		// játék közbeni üzenetek
		"WALK INTO THE EXIT" => "SÉTÁLJ BE A KIJÁRATON", "BUILD YOUR FRIEND AT THE WORKBENCH FIRST" => "ELŐBB ÉPÍTSD MEG A TÁRSADAT A SZERELŐASZTALNÁL",
		"UP / E: GO THROUGH" => "FEL / E: ÁTMENNI", "UP / E: ENTER BUILDING" => "FEL / E: BE AZ ÉPÜLETBE", "UP / E: LEAVE BUILDING" => "FEL / E: KI AZ ÉPÜLETBŐL",
		"UP / E: USE THE COMPUTER" => "FEL / E: SZÁMÍTÓGÉP HASZNÁLATA", "COMPUTER" => "TERMINÁL",
		"TRAPPED! EMERGENCY LIFT ENGAGED" => "CSAPDÁBAN! VÉSZLIFT BEKAPCSOLVA", "REBOOT COMPLETE" => "ÚJRAINDÍTÁS KÉSZ", "BATTERY PACK +35%" => "AKKUPAKK +35%",
		"TERMINAL SOLVED: THE INNER DOOR OPENS" => "TERMINÁL MEGOLDVA: NYÍLIK A BELSŐ AJTÓ", "THE WALL CRUMBLES" => "LEOMLIK A FAL",
		"TOO LIGHT: PUT A CRATE ON THE PLATE" => "TÚL KÖNNYŰ VAGY: TEGYÉL LÁDÁT A LAPRA", "LEVER PULLED: GATE OPENED" => "KAR ÁTBILLENTVE: NYÍLIK A KAPU",
		"ACCESS GRANTED" => "HOZZÁFÉRÉS ENGEDÉLYEZVE", "WRONG ORDER: RESET" => "ROSSZ SORREND: ELÖLRŐL", "KEY FOUND" => "KULCS MEGVAN", "UNLOCKED" => "KINYITVA",
		"POWER CELL: TAKE IT TO THE SOCKET" => "ÁRAMCELLA: VIDD AZ ALJZATHOZ", "LIFT POWERED" => "A LIFT ÁRAMOT KAPOTT",
		"FRIENDS FOLLOW YOU" => "A TÁRSAK KÖVETNEK", "FRIENDS WAIT" => "A TÁRSAK VÁRNAK", "CARRYING: POWER CELL" => "VISZED: ÁRAMCELLA",
		"Q: WAIT/FOLLOW  TAB: SWITCH" => "Q: VÁR/KÖVET  TAB: VÁLTÁS", "LEVER ZAPPED: GATE OPENED" => "KAR ELTALÁLVA: NYÍLIK A KAPU", "NOTHING TO LIFT" => "NINCS MIT FELEMELNI",
		"JET CELL: HOLD JUMP IN THE AIR TO FLY" => "HAJTÓCELLA: TARTSD AZ UGRÁST A LEVEGŐBEN A REPÜLÉSHEZ", "CHECKPOINT" => "MENTÉSI PONT", "GATE OPENED" => "NYÍLIK A KAPU",
		// Tiled-feliratok
		"PUSH THE CRATE INTO THE SLOT" => "TOLD A LÁDÁT A RÉSBE", "SOCKET NEEDS A POWER CELL" => "AZ ALJZATBA ÁRAMCELLA KELL",
		"ONLY THE SMALL ONE FITS" => "CSAK A KICSI FÉR BE", "TOO HIGH. NEED A BOOST" => "TÚL MAGAS. LÖKÉS KELL", "TOO HIGH FOR ANYONE WHO CAN'T FLY" => "TÚL MAGAS, HA NEM TUDSZ REPÜLNI",
		"LEVER OUT OF REACH" => "A KAR ELÉRHETETLEN",
		// mini-játékok, műhely
		"CIRCUIT REPAIR" => "ÁRAMKÖR-JAVÍTÁS", "DOOR LOCK" => "AJTÓZÁR", "MEMORY BANK" => "MEMÓRIABANK", "DEFENSE SIMULATION" => "VÉDELMI SZIMULÁCIÓ",
		"A BROKEN CIRCUIT BOARD. SLIDE THE TILES BACK INTO ORDER." => "TÖRÖTT ÁRAMKÖRI LAP. TOLD VISSZA A LAPKÁKAT A HELYÜKRE.",
		"THE LOCK ASKS FOR ITS OLD SEQUENCE. WATCH, THEN REPEAT IT." => "A ZÁR A RÉGI SORRENDET KÉRI. FIGYELD MEG, AZTÁN ISMÉTELD.",
		"THE ARCHIVE'S MEMORY CARDS ARE SCRAMBLED. FIND ALL THE MATCHING PAIRS." => "AZ ARCHÍVUM KÁRTYÁI ÖSSZEKEVEREDTEK. TALÁLD MEG AZ ÖSSZES PÁRT.",
		"AN OLD TRAINING PROGRAM STILL RUNS. DESTROY ALL THE ENEMY TANKS." => "EGY RÉGI GYAKORLÓPROGRAM MÉG FUT. SEMMISÍTSD MEG AZ ÖSSZES TANKOT.",
		"ARROWS / D-PAD: SLIDE A TILE    ESC / B: LEAVE" => "NYILAK / D-PAD: LAPKA TOLÁSA    ESC / B: KILÉPÉS",
		"ARROWS / D-PAD: REPEAT THE SEQUENCE    ESC / B: LEAVE" => "NYILAK / D-PAD: A SORREND ISMÉTLÉSE    ESC / B: KILÉPÉS",
		"ARROWS / D-PAD: MOVE    SPACE / A: FLIP A CARD    ESC / B: LEAVE" => "NYILAK / D-PAD: MOZGÁS    SPACE / A: FORDÍTÁS    ESC / B: KILÉPÉS",
		"ARROWS / D-PAD: DRIVE    SPACE / A: FIRE    ESC / B: LEAVE" => "NYILAK / D-PAD: VEZETÉS    SPACE / A: LÖVÉS    ESC / B: KILÉPÉS",
		"WATCH..." => "FIGYELJ...", "GOOD" => "JÓ", "WRONG: WATCH AGAIN" => "ROSSZ: FIGYELJ ÚJRA", "FIND THE PAIRS" => "KERESD A PÁROKAT",
		"YOU WERE HIT: RESTARTING" => "TALÁLAT ÉRT: ÚJRAKEZDÉS", "CONTINUE" => "TOVÁBB", "ALREADY AT MAX LEVEL" => "MÁR A LEGMAGASABB SZINTEN VAN",
		"NOT ENOUGH ATOMS" => "NINCS ELÉG ATOM", "WORKSHOP" => "MŰHELY",
		"THE ATOMS YOU COLLECTED POWER UPGRADES. SPEND THEM ON AN IMPROVED PART." => "AZ ÖSSZEGYŰJTÖTT ATOMOKBÓL FEJLESZTHETSZ. KÖLTSD EL ŐKET EGY JOBB ALKATRÉSZRE.",
		"UP / DOWN: SELECT    SPACE / A: UPGRADE    ESC / B: CONTINUE" => "FEL / LE: VÁLASZT    SPACE / A: FEJLESZT    ESC / B: TOVÁBB",
		// alkatrész-hatások (Parts.INFO / INFO2 / UP)
		"FULL JUMP + FAST RUN" => "TELJES UGRÁS + GYORS FUTÁS", "POWER ONLINE: BATTERY DRAINS SLOWER" => "LASSABBAN MERÜL AZ AKKU",
		"CLEAR SIGHT AROUND YOU" => "TISZTA LÁTÁS KÖRÜLÖTTED", "DASH: X / SHIFT" => "SZÖKELLÉS: X / SHIFT", "CLING TO WALLS + WALL JUMP" => "FALRA KAPASZKODÁS + FALUGRÁS",
		"FIRE: V / J / RIGHT CLICK" => "LÖVÉS: V / J / JOBB KATT", "CONTROLS RESPOND FASTER" => "FÜRGÉBB IRÁNYÍTÁS",
		"AIR CONTROL + STRONGER BOUNCE" => "LÉGI IRÁNYÍTÁS + PATTANÁS", "RADAR ONLINE" => "RADAR BEKAPCSOLVA", "FLIGHT: HOLD JUMP" => "REPÜLÉS: TARTSD AZ UGRÁST",
		"HIGHER JUMP, FASTER RUN" => "MAGASABB UGRÁS, GYORSABB FUTÁS", "BATTERY DRAINS EVEN SLOWER" => "MÉG LASSABBAN MERÜL AZ AKKU",
		"LENS: SEE FARTHER, SECRET ATOMS GLOW" => "LENCSE: MESSZEBB LÁTSZ + TITKOS ATOMOK", "BOOSTER: TWO DASHES PER JUMP" => "GYORSÍTÓ: 2 SZÖKELLÉS UGRÁSONKÉNT",
		"GRIP: SLOWER WALL SLIDE" => "FOGÁS: LASSABBAN CSÚSZOL", "RAPID FIRE" => "GYORSTÜZELÉS", "SNAPPIER STILL" => "MÉG FÜRGÉBB",
		"EVEN BETTER AIR CONTROL" => "MÉG JOBB LÉGI IRÁNYÍTÁS", "RADAR SHOWS ENEMIES TOO" => "RADAR: AZ ELLENSÉGEK IS", "LONGER FLIGHT" => "HOSSZABB REPÜLÉS",
		"TURBO LEGS: HIGHER, FASTER" => "TURBÓLÁB: MAGASABBRA, GYORSABBAN", "RACING LEGS: HIGHER, FASTER" => "VERSENYLÁB: MAGASABBRA, GYORSABBAN",
		"PEAK LEGS: HIGHER, FASTER" => "CSÚCSLÁB: MAGASABBRA, GYORSABBAN", "HITS DRAIN LESS BATTERY" => "A TALÁLAT KEVESEBB AKKUT VISZ",
		"LONGER PROTECTION AFTER A HIT" => "HOSSZABB VÉDELEM TALÁLAT UTÁN", "TOUGHEST: LEAST DAMAGE, QUICK RECOVERY" => "A LEGSZÍVÓSABB: KEVÉS SEBZÉS",
		"SEE FARTHER, SECRET ATOMS +4" => "MESSZEBBRE LÁTSZ, TITKOS ATOM +4", "SEE EVEN FARTHER, ATOMS +5" => "MÉG MESSZEBBRE LÁTSZ, ATOM +5",
		"FULL CLEAR VISION, ATOMS +6" => "TELJESEN TISZTA LÁTÁS, ATOM +6", "THREE DASHES PER JUMP" => "HÁROM SZÖKELLÉS UGRÁSONKÉNT",
		"FASTER DASH RECHARGE" => "GYORSABBAN TÖLT A SZÖKELLÉS", "FOUR DASHES PER JUMP" => "NÉGY SZÖKELLÉS UGRÁSONKÉNT", "HIGHER WALL JUMP" => "MAGASABB FALUGRÁS",
		"IRON GRIP: BARELY SLIDES" => "VASMARKOLAT: ALIG CSÚSZIK", "MASTER CLIMBER: WALL JUMP++" => "MESTERMÁSZÓ: FALUGRÁS++", "FASTER FIRE" => "GYORSABB TÜZELÉS",
		"FASTER STILL" => "MÉG GYORSABB", "MAXIMUM FIRE RATE" => "MAXIMÁLIS TŰZGYORSASÁG", "SHARPER GROUND CONTROL" => "PONTOSABB IRÁNYÍTÁS A FÖLDÖN",
		"RAZOR REFLEXES" => "BOROTVAÉLES REFLEXEK", "PERFECT REFLEXES" => "TÖKÉLETES REFLEXEK", "AIR CONTROL +, BOUNCIER" => "LÉGI IRÁNYÍTÁS +, PATTANÓSABB",
		"AIR CONTROL ++, BOUNCIER" => "LÉGI IRÁNYÍTÁS ++, PATTANÓSABB", "AIR MASTER" => "A LEVEGŐ MESTERE", "RADAR SHOWS SECRET ATOMS" => "RADAR: A TITKOS ATOMOK IS",
		"RADAR SHOWS ALL ATOMS" => "RADAR: MINDEN ATOM", "FLIGHT +50%" => "REPÜLÉS +50%", "FLIGHT +100%" => "REPÜLÉS +100%", "MAXED OUT" => "MAXIMUMON"
	];

	// --- Minták (változó részekkel) ---
	static final RULES:Array<{re:EReg, f:EReg->String}> = [
		{re: ~/^LIVES (.*)$/, f: r -> "ÉLET " + r.matched(1)},
		{re: ~/^ATOMS (\d+)\/(\d+)  BANK (\d+)$/, f: r -> "ATOM " + r.matched(1) + "/" + r.matched(2) + "  BANK " + r.matched(3)},
		{re: ~/^ATOMS (\d+)\/(\d+)(  ALL FOUND \+500)?$/, f: r -> "ATOM " + r.matched(1) + "/" + r.matched(2) + (r.matched(3) != null ? "  MIND MEGVAN +500" : "")},
		{re: ~/^ATOMS (\d+)$/, f: r -> "ATOM " + r.matched(1)},
		{re: ~/^ATOM BANK (\d+)(  \(WORKSHOP READY\))?$/, f: r -> "ATOMBANK " + r.matched(1) + (r.matched(2) != null ? "  (A MŰHELY NYITVA)" : "")},
		{re: ~/^SCORE (\d+)$/, f: r -> "PONT " + r.matched(1)},
		{re: ~/^FINAL SCORE (\d+)$/, f: r -> "VÉGSŐ PONTSZÁM " + r.matched(1)},
		{re: ~/^TIME (.+)$/, f: r -> "IDŐ " + r.matched(1)},
		{re: ~/^PARTS (\d+)\/(\d+)$/, f: r -> "ALKATRÉSZ " + r.matched(1) + "/" + r.matched(2)},
		{re: ~/^PARTS (.+)$/, f: r -> "ALKATRÉSZEK: " + names(r.matched(1))},
		{re: ~/^JET (.*)$/, f: r -> "REPÜLÉS " + r.matched(1)},
		{re: ~/^NEXT (.+) (>>|<<|\^\^|vv) (\d+)M$/, f: r -> "KÖVETKEZŐ: " + names(r.matched(1)) + " " + r.matched(2) + " " + r.matched(3) + "M"},
		{re: ~/^(< |\^ |v )(.+) (\d+)M$/, f: r -> r.matched(1) + names(r.matched(2)) + " " + r.matched(3) + "M"},
		{re: ~/^(.+) (\d+)M >$/, f: r -> names(r.matched(1)) + " " + r.matched(2) + "M >"},
		{re: ~/^NEED (\d+) MORE PARTS? FOR (.+)$/, f: r -> names(r.matched(2)) + ": MÉG " + r.matched(1) + " ALKATRÉSZ KELL"},
		{re: ~/^NEED (\d+) MORE PARTS?$/, f: r -> "MÉG " + r.matched(1) + " ALKATRÉSZ KELL"},
		{re: ~/^CONTROL: (.+)$/, f: r -> "IRÁNYÍTOTT: " + names(r.matched(1))},
		{re: ~/^TAB: SWITCH  Q: (FOLLOW|WAIT)$/, f: r -> "TAB: VÁLTÁS  Q: " + (r.matched(1) == "FOLLOW" ? "KÖVETNEK" : "VÁRNAK")},
		{re: ~/^FRIEND BUILT: (.+)$/, f: r -> "TÁRS MEGÉPÍTVE: " + r.matched(1)},
		{re: ~/^SECRET ATOM \+(\d+)$/, f: r -> "TITKOS ATOM +" + r.matched(1)},
		{re: ~/^A PART FOR YOUR FRIEND (.+)$/, f: r -> "ALKATRÉSZ A TÁRSADNAK: " + r.matched(1)},
		{re: ~/^FOUND: (.+)$/, f: r -> "MEGVAN: " + names(r.matched(1))},
		{re: ~/^UPGRADED: (.+)$/, f: r -> "FEJLESZTVE: " + info(r.matched(1))},
		{re: ~/^BACKUPS LEFT: (\d+)$/, f: r -> "MARADÉK MENTÉS: " + r.matched(1)},
		{re: ~/^LEVEL (\d+) CLEAR$/, f: r -> r.matched(1) + ". PÁLYA TELJESÍTVE"},
		{re: ~/^FIND (\d+) PARTS: (.+)$/, f: r -> "KERESS " + r.matched(1) + " ALKATRÉSZT: " + names(r.matched(2))},
		{re: ~/^FRIEND PARTS: (.+)$/, f: r -> "TÁRS-ALKATRÉSZEK: " + names(r.matched(1))},
		{re: ~/^ORDER: (.+)$/, f: r -> "SORREND: " + r.matched(1)},
		{re: ~/^ENEMIES (\d+)   ONE HIT AND YOU RESTART$/, f: r -> "ELLENSÉG: " + r.matched(1) + "   EGY TALÁLAT ÉS ÚJRAKEZDED"},
		{re: ~/^YOUR TURN  (\d+)\/(\d+)$/, f: r -> "TE JÖSSZ  " + r.matched(1) + "/" + r.matched(2)},
		{re: ~/^(.+?) ([IV]+)>([IV]+) \[(\d+)\] (.+)$/, f: r -> names(r.matched(1)) + " " + r.matched(2) + ">" + r.matched(3) + " [" + r.matched(4) + "] " + info(r.matched(5))},
		{re: ~/^(.+?)  ([IV]+)  \(MAX\)$/, f: r -> names(r.matched(1)) + "  " + r.matched(2) + "  (MAX)"},
		{re: ~/^MUSIC(\s+)(.*)$/, f: r -> "ZENE" + r.matched(1) + r.matched(2)},
		{re: ~/^SFX(\s+)(.*)$/, f: r -> "EFFEKT" + r.matched(1).substr(1) + r.matched(2)},
		{re: ~/^FULLSCREEN(\s+)(ON|OFF)$/, f: r -> "TELJES KÉPERNYŐ" + r.matched(1) + (r.matched(2) == "ON" ? "BE" : "KI")}
	];
}
