package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.tile.FlxBaseTilemap.FlxTilemapAutoTiling;
import flixel.tile.FlxTilemap;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.util.FlxDirectionFlags;
import LevelData.LampDef;
import Puzzle;
import MiniGames;

/** Egy felvehető / dekorációs tárgy (gyémánt, szív, alkatrész, repülő-cella, ellenőrzőpont). */
class Pickup extends FlxSprite
{
	public var baseY:Float;
	public var t:Float = Math.random() * 6;
	public var bob:Bool = true;
	public var icon:Int = -1;
	public var label:String = "";
	public var idx:Int = -1;
	public var friend:Int = -1;
	/** Titkos atom: láthatatlan, amíg nincs LENS (VISOR II. szint); 3 atomot ér a bankban. */
	public var secret:Bool = false;

	override public function update(elapsed:Float):Void
	{
		t += elapsed;
		if (bob)
			y = baseY + Math.sin(t * 3) * 1.5;
		super.update(elapsed);
	}
}

/** Pici részecske (por, szikra, törmelék). */
class Particle extends FlxSprite
{
	var life:Float = 0;
	var maxLife:Float = 0.5;

	public function new()
	{
		super();
		makeGraphic(2, 2, 0xFFFFFFFF);
	}

	public function fire(px:Float, py:Float, vx:Float, vy:Float, grav:Float, life:Float, color:Int):Void
	{
		reset(px, py);
		velocity.set(vx, vy);
		acceleration.y = grav;
		this.life = 0;
		maxLife = life;
		this.color = color;
		alpha = 1;
	}

	override public function update(elapsed:Float):Void
	{
		life += elapsed;
		if (life >= maxLife)
		{
			kill();
			return;
		}
		alpha = 1 - life / maxLife;
		super.update(elapsed);
	}
}

/** A blaszter lövedéke: egyenesen repül, a szilárd csempében megáll. */
class Bullet extends FlxSprite
{
	public var level:LevelData;
	var life:Float = 0;

	public function new()
	{
		super();
		makeGraphic(6, 2, 0xFFFFFFFF);
	}

	public function fire(px:Float, py:Float, dir:Int, lvl:LevelData):Void
	{
		reset(px - 3, py);
		velocity.set(dir * 250, 0);
		life = 0;
		level = lvl;
	}

	override public function update(elapsed:Float):Void
	{
		life += elapsed;
		if (life > 1.4 || level.isSolid(Std.int((x + 3) / LevelData.T), Std.int((y + 1) / LevelData.T)))
		{
			kill();
			return;
		}
		super.update(elapsed);
	}
}

/** Leszakadó platform: a ráállás után rövid remegés, aztán lehullik; később újra megjelenik. */
class Crumble extends FlxSprite
{
	var ox:Float;
	var oy:Float;
	var state:Int = 0;
	var timer:Float = 0;
	public var onCrack:Void->Void;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		ox = x;
		oy = y;
		loadGraphic(Art.crumble(), false, 48, 10, false, "crumble");
		immovable = true;
		allowCollisions = FlxDirectionFlags.UP;
		height = 6;
		offset.y = 0;
	}

	public function trigger():Void
	{
		if (state == 0)
		{
			state = 1;
			timer = 0.55;
			if (onCrack != null)
				onCrack();
		}
	}

	override public function update(elapsed:Float):Void
	{
		switch (state)
		{
			case 1:
				timer -= elapsed;
				x = ox + (Math.random() * 2 - 1) * 1.2;
				if (timer <= 0)
				{
					state = 2;
					timer = 3.2;
					allowCollisions = FlxDirectionFlags.NONE;
					immovable = false;
					acceleration.y = 520;
				}
			case 2:
				timer -= elapsed;
				if (timer <= 0)
				{
					state = 0;
					acceleration.y = 0;
					velocity.set(0, 0);
					x = ox;
					y = oy;
					immovable = true;
					allowCollisions = FlxDirectionFlags.UP;
					alpha = 1;
				}
				else if (y > oy + 60)
					alpha = Math.max(0, alpha - elapsed * 3);
		}
		super.update(elapsed);
	}
}

/** Mozgó platform: vízszintes ide-oda, vagy függőleges emelő (az áramcella behelyezése indítja). A `dx` az utolsó lépés elmozdulása (a rajta álló hőst a PlayState viszi vele). */
class Mover extends FlxSprite
{
	public var dx:Float = 0;
	/** Vízszintes sebesség (px/s): a követő társak ebből számolják az ugrás célpontját. */
	public var vx:Float = 0;
	public var gid:Int = -1;
	public var powered:Bool = true;
	var ox:Float;
	var oy:Float;
	var range:Float;
	var omega:Float;
	var vertical:Bool;
	var t:Float = 0;

	public function new(def:LevelData.MoverDef)
	{
		super(def.x, def.y);
		ox = def.x;
		oy = def.y;
		range = def.range;
		omega = Math.PI * def.speed / def.range;
		vertical = def.axis == "y";
		gid = def.id != null ? def.id : -1;
		powered = def.active != false;
		loadGraphic(Art.mover(), false, 48, 8, false, "mover");
		immovable = true;
		allowCollisions = FlxDirectionFlags.UP;
		moves = false;
		height = 6;
	}

	override public function update(elapsed:Float):Void
	{
		dx = 0;
		if (powered)
		{
			t += elapsed;
			var k = (1 - Math.cos(t * omega)) / 2 * range;
			if (vertical)
				y = oy - k;
			else
			{
				var nx = ox + k;
				dx = nx - x;
				x = nx;
			}
		}
		vx = elapsed > 0 ? dx / elapsed : 0;
		super.update(elapsed);
	}
}

/**
 * A játék: egy pálya (generált szegmensekből és küldetés-szobákból). A robot csupaszon indul, és a pálya különböző pontjain kell megtalálnia
 * az alkatrészeit; az ajtó csak akkor nyílik, ha mind megvan. Az alkatrészek képességeket adnak (ugrás, dash, fal-karmok, blaszter);
 * a repülő-cella ideiglenes repülést. Puzzle-elemek: repedezett fal (lőni kell), kapu + nyomólap, leszakadó és mozgó platformok.
 */
class PlayState extends FlxState
{
	public static var level:Int = 0;
	public static var totalScore:Int = 0;

	var data:LevelData;
	var solidMap:FlxTilemap;
	var platMap:FlxTilemap;
	var player:Player;
	var enemies:FlxTypedGroup<Enemy>;
	var grounded:FlxGroup;
	var gems:FlxTypedGroup<Pickup>;
	var hearts:FlxTypedGroup<Pickup>;
	var partItems:FlxTypedGroup<Pickup>;
	var cells:FlxTypedGroup<Pickup>;
	var checkpoints:FlxTypedGroup<Pickup>;
	var spikes:FlxTypedGroup<FlxSprite>;
	var cracked:FlxTypedGroup<FlxSprite>;
	var gates:FlxTypedGroup<Gate>;
	var plates:FlxTypedGroup<Plate>;
	var levers:FlxTypedGroup<Lever>;
	var switches:FlxTypedGroup<SwitchPad>;
	var crates:FlxTypedGroup<Crate>;
	var grates:FlxTypedGroup<FlxSprite>;
	var sockets:FlxTypedGroup<Socket>;
	var keysG:FlxTypedGroup<Pickup>;
	var powerCells:FlxTypedGroup<Pickup>;
	var benches:FlxTypedGroup<FlxSprite>;
	var companions:FlxTypedGroup<Companion>;
	var seqState:Map<Int, Int> = new Map();
	var keysHeld:Map<Int, Bool> = new Map();
	var carryCell:Int = -1;
	var friendFound:Array<Int> = [0, 0, 0];
	var benchBuilt:Bool = false;
	var selComp:Int = 0;
	var hudComp:FlxText;
	var playerGone:Bool = false;
	/** Az éppen irányított robot (a hős vagy egy társ). */
	var ctrl:FlxSprite;
	var followAll:Bool = true;
	var heroExited:Bool = false;
	/** Valamelyik robot belépett a kijáratba: a pálya hamarosan véget ér. */
	var exiting:Bool = false;
	var exitT:Float = 0;
	var heroStuckT:Float = 0;
	var terminals:FlxTypedGroup<FlxSprite>;
	var termGame:Map<Int, Int> = new Map();
	var termSolved:Map<Int, Bool> = new Map();
	var marker:FlxText;
	var crumbles:FlxTypedGroup<Crumble>;
	var movers:FlxTypedGroup<Mover>;
	var bullets:FlxTypedGroup<Bullet>;
	var door:FlxSprite;
	/** Épület-ajtók: a felszíni (be) és a belső (ki) ajtók; mindegyik a célpontját tudja. */
	var bDoors:Array<{spr:FlxSprite, tx:Float, ty:Float, toInside:Bool, ?fromInside:Bool}> = [];
	var inside:Bool = false;
	var teleporting:Bool = false;
	var particles:FlxTypedGroup<Particle>;
	var ghosts:FlxTypedGroup<FlxSprite>;

	var hudHearts:Array<FlxSprite> = [];
	var hudParts:Array<FlxSprite> = [];
	var hudGems:FlxText;
	var hudScore:FlxText;
	var hudParts2:FlxText;
	var hudScan:FlxText;
	/** Képernyőszéli nyíl a következő cél felé, ha az nem látszik. */
	var navArrow:FlxText;
	var hudFuel:FlxText;
	var radarSpr:FlxSprite;
	var radarT:Float = 0;
	var glowT:Int = -1;
	var batts:FlxTypedGroup<Pickup>;
	var hudBatt:Array<FlxSprite> = [];
	var battIcon:FlxSprite;
	var wasDown:Bool = false;
	var lowT:Float = 0;
	/** Az információs panel (alul, doboz): a pálya-bemutató, a felugró üzenetek (toast), a helyzet-súgó (hint) és a közeli táblák szövege. */
	var bannerStr:String = "";
	var bannerT:Float = 0;
	var infoBorder:FlxSprite;
	var infoFill:FlxSprite;
	var infoText:FlxText;
	var worldTexts:Array<{x:Float, y:Float, s:String, solved:Bool}> = [];
	var switchLabels:Array<{t:FlxText, gid:Int}> = [];
	var lampShader:LampShader;
	var lampOverlay:FlxSprite;
	var lampZones:Array<{x:Float, y:Float, w:Float, h:Float}> = [];
	var lampClock:Float = 0;
	var hint:FlxText;
	var overlay:FlxText;
	var toast:FlxText;
	var toastT:Float = 0;

	var respawn:FlxPoint;
	var found:Array<Bool> = [];
	var partsFound:Int = 0;
	var gemsTotal:Int = 0;
	var gemsGot:Int = 0;
	var score:Int = 0;
	var combo:Int = 0;
	var time:Float = 0;
	var hitstop:Float = 0;
	var mode:Int = 0; // 0 játék, 1 pálya kész, 2 vége (halál), 3 belép az ajtón
	var paused:Bool = false;
	/** A földet érés hangja egy kicsit késik: ha közben ugrás jön (pergő ugrás), elmarad, így nem szólal meg egyszerre az ugrással. */
	var landT:Float = 0;
	var landVol:Float = 0;
	var modeT:Float = 0;
	var thrustT:Float = 0;
	var worldW:Int;
	var worldH:Int;

	// A HUD külön kamerán (hudCam) rajzol, amin nincs shader: a sérülés-kisülés, a fáradtság-elmosás és a homályos látás a játékot érinti,
	// a fontos információ (szívek, akku, alkatrészek) viszont mindig tisztán olvasható.
	var hudCam:flixel.FlxCamera;
	var hudLayer:flixel.group.FlxGroup;
	var hudAdding:Bool = false;

	/** A hudAdding közben létrehozott elemek a HUD-rétegre (hudCam) kerülnek, a többi a játékra. */
	override public function add(basic:flixel.FlxBasic):flixel.FlxBasic
	{
		if (hudAdding && hudLayer != null)
			return hudLayer.add(basic);
		return super.add(basic);
	}

	/** Menü / minijáték a HUD-kamerán rajzol (effektmentesen); közben a HUD rejtve van (az update-ben újra látszik). */
	override public function openSubState(subState:flixel.FlxSubState):Void
	{
		if (hudLayer != null)
			hudLayer.visible = false;
		// a menük és minijátékok is a HUD-kamerán rajzolnak: a sérülés-kisülés, az elmosás és a sötétítés őket sem érinti
		if (hudCam != null)
			subState.cameras = [hudCam];
		super.openSubState(subState);
	}

	override public function create():Void
	{
		super.create();
		Audio.init();
		Audio.playMusic(level);
		bgColor = 0xFF000000;
		Parts.restore();
		Companions.restore();
		data = LevelLoader.load(level);
		worldW = data.w * LevelData.T;
		worldH = LevelData.H * LevelData.T;
		score = totalScore;
		found = [for (_ in data.parts) false];

		// háttér: csillagok és két réteg távoli rom (paralaxis)
		// pályánként más: égitest + távoli és közeli réteg stílusa (romok, gyár, árbocok, kupolák, hűtőtornyok, fogaskerekek, barlang, akvadukt, kábelek, felhőkarcolók)
		var li = level % 10;
		addBackdrop(Art.stars(480 + Std.int(worldW * 0.05), 7 + level * 5, [1, 0, 2, 3, 0, 1, 0, 2, 3, 1][li]), 0.05, 0.03, -70);
		addBackdrop(Art.backdrop(480 + Std.int(worldW * 0.18), 11 + level, "5", 30, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9][li]), 0.18, 0.12, -70);
		addBackdrop(Art.backdrop(480 + Std.int(worldW * 0.34), 29 + level, "6", 60, [0, 0, 9, 1, 2, 1, 6, 2, 3, 4][li]), 0.34, 0.2, -60);

		// épületek: homlokzat a felszínen, falpapír a belső termekben (a csempék mögé)
		for (d in data.decor)
		{
			var f = new FlxSprite(d.x * 16, d.y * 16);
			f.loadGraphic(Art.facade(d.w * 16, d.h * 16), false, 0, 0, false, "facade" + d.x + "_" + d.y);
			add(f);
		}
		for (b in data.buildings)
		{
			var wp = new FlxSprite(b.x0 * 16, b.y0 * 16);
			wp.loadGraphic(Art.wallpaper(b.w * 16, b.h * 16), false, 0, 0, false, "wp" + b.x0);
			add(wp);
		}
		solidMap = new FlxTilemap();
		solidMap.loadMapFromArray(data.solid, data.w, LevelData.H, Art.tiles(), 16, 16, FlxTilemapAutoTiling.OFF, 0, 1, 1);
		add(solidMap);
		platMap = new FlxTilemap();
		platMap.loadMapFromArray(data.plats, data.w, LevelData.H, Art.tiles(), 16, 16, FlxTilemapAutoTiling.OFF, 0, 1, 1);
		platMap.setTileProperties(4, FlxDirectionFlags.UP);
		add(platMap);
		addLamps();

		spikes = new FlxTypedGroup();
		for (s in data.spikes)
		{
			var sp = new FlxSprite(s.x, s.y);
			sp.loadGraphic(Art.spikes(), false, 16, 8, false, "spikes");
			sp.width = 12;
			sp.height = 5;
			sp.offset.set(2, 3);
			sp.x += 2;
			sp.y += 3;
			sp.immovable = true;
			spikes.add(sp);
		}
		add(spikes);

		// puzzle-elemek
		cracked = new FlxTypedGroup();
		for (c in data.crackeds)
		{
			var b = new FlxSprite(c.x, c.y);
			b.loadGraphic(Art.cracked(), false, 16, 16, false, "cracked");
			b.immovable = true;
			cracked.add(b);
		}
		add(cracked);
		gates = new FlxTypedGroup();
		for (g in data.gates)
			gates.add(new Gate(g.x, g.y, g.id, g.lock));
		add(gates);
		grates = new FlxTypedGroup();
		for (g in data.grates)
		{
			var b = new FlxSprite(g.x, g.y);
			b.loadGraphic(Art.grate(), false, 16, 16, false, "grate");
			b.immovable = true;
			grates.add(b);
		}
		add(grates);
		plates = new FlxTypedGroup();
		for (p in data.plates)
			plates.add(new Plate(p.x, p.y, p.id, p.hold));
		add(plates);
		levers = new FlxTypedGroup();
		for (l in data.levers)
			levers.add(new Lever(l.x, l.y, l.id));
		add(levers);
		switches = new FlxTypedGroup();
		for (s in data.switches)
		{
			switches.add(new SwitchPad(s.x, s.y, s.id, s.idx, s.label));
			var lb = new FlxText(s.x - 2, s.y - 11, 16, s.label, 8);
			lb.setFormat(null, 8, 0xFFFFFFFF, CENTER);
			add(lb);
			switchLabels.push({t: lb, gid: s.id});
		}
		add(switches);
		crates = new FlxTypedGroup();
		for (c in data.crates)
			crates.add(new Crate(c.x, c.y));
		add(crates);
		sockets = new FlxTypedGroup();
		for (s in data.sockets)
			sockets.add(new Socket(s.x, s.y, s.id));
		add(sockets);
		keysG = new FlxTypedGroup();
		for (k in data.keys)
		{
			var it = makePickup(k.x, k.y, Art.key(), 10, 8, "key");
			it.idx = k.id;
			keysG.add(it);
		}
		add(keysG);
		powerCells = new FlxTypedGroup();
		for (c in data.powerCells)
		{
			var it = makePickup(c.x, c.y, Art.powerCell(), 8, 12, "powercell");
			it.idx = c.id;
			powerCells.add(it);
		}
		add(powerCells);
		benches = new FlxTypedGroup();
		for (b in data.benches)
		{
			var s = new FlxSprite(b.x, b.y);
			s.loadGraphic(Art.bench(), false, 24, 16, false, "bench");
			s.ID = b.comp;
			benches.add(s);
		}
		add(benches);
		terminals = new FlxTypedGroup();
		for (tm in data.terminals)
		{
			var s = new FlxSprite(tm.x, tm.y);
			s.loadGraphic(Art.terminal(), true, 16, 16, false, "terminal");
			s.animation.add("on", [1], 1);
			s.animation.add("done", [2], 1);
			s.animation.play("on");
			s.ID = tm.id;
			termGame.set(tm.id, tm.game);
			terminals.add(s);
			var lb = new FlxText(tm.x - 24, tm.y - 12, 64, "COMPUTER", 8);
			lb.setFormat(null, 8, 0xFF999999, CENTER);
			add(lb);
		}
		add(terminals);
		for (tx in data.texts)
		{
			worldTexts.push({x: tx.x, y: tx.y, s: tx.text, solved: false});
		}
		crumbles = new FlxTypedGroup();
		for (c in data.crumbles)
		{
			var cr = new Crumble(c.x, c.y);
			cr.onCrack = () -> Audio.play("crumble", 0.8);
			crumbles.add(cr);
		}
		add(crumbles);
		movers = new FlxTypedGroup();
		for (m in data.movers)
			movers.add(new Mover(m));
		add(movers);

		checkpoints = new FlxTypedGroup();
		for (c in data.checkpoints)
		{
			var cp = new Pickup(c.x, c.y);
			cp.loadGraphic(Art.checkpoint(), true, 8, 16, false, "checkpoint");
			cp.animation.add("off", [0], 1);
			cp.animation.add("on", [1], 1);
			cp.animation.play("off");
			cp.bob = false;
			checkpoints.add(cp);
		}
		add(checkpoints);

		door = new FlxSprite(data.door.x, data.door.y);
		door.loadGraphic(Art.door(), true, 16, 24, false, "door");
		door.animation.add("closed", [0], 1);
		door.animation.add("open", [1, 2], 6);
		door.animation.play("closed");
		add(door);
		if (data.doors.length > 0)
		{
			// Tiled-pályán: tetszőleges ajtók, mindegyik a célajtó (target) elé visz (bunkerből bunkerbe is)
			for (dd in data.doors)
			{
				var tg = null;
				for (o in data.doors)
					if (o.id == dd.target)
						tg = o;
				if (tg == null)
					continue;
				var sp = new FlxSprite(dd.x, dd.y);
				sp.loadGraphic(Art.bdoor(), false, 16, 24, false, "bdoor");
				add(sp);
				bDoors.push({spr: sp, tx: tg.x + 4, ty: tg.y + 24 - 30, toInside: tg.inside, fromInside: dd.inside});
			}
		}
		else
			for (b in data.buildings)
			{
				var outer = new FlxSprite(b.sx, b.sy);
				outer.loadGraphic(Art.bdoor(), false, 16, 24, false, "bdoor");
				add(outer);
				var inner = new FlxSprite(b.ix, b.iy);
				inner.loadGraphic(Art.bdoor(), false, 16, 24, false, "bdoor");
				add(inner);
				bDoors.push({spr: outer, tx: b.ix + 4, ty: b.iy + 24 - 30, toInside: true, fromInside: false});
				bDoors.push({spr: inner, tx: b.sx + 4, ty: b.sy + 24 - 30, toInside: false, fromInside: true});
			}

		gems = new FlxTypedGroup();
		var gi = 0;
		gemsTotal = 0;
		for (g in data.gems)
		{
			var p = makePickup(g.x, g.y, Art.atom(), 8, 8, "gem");
			p.animation.add("spin", [0, 1, 2, 3], 6);
			p.animation.play("spin");
			// minden 6. atom titkos: csak a LENS (VISOR II. szint) mutatja, 3 atomot ér, és nem számít a pálya "összes atom" számlálójába
			p.secret = gi % 6 == 5;
			if (p.secret)
				p.alpha = 0;
			else
				gemsTotal++;
			gems.add(p);
			gi++;
		}
		add(gems);

		hearts = new FlxTypedGroup();
		for (h in data.hearts)
			hearts.add(makePickup(h.x, h.y, Art.heart(), 8, 8, "heart"));
		add(hearts);

		// alkatrészek (a küldetés) és repülő-cellák
		partItems = new FlxTypedGroup();
		for (i in 0...data.parts.length)
		{
			var pt = data.parts[i];
			var it = makePickup(pt.x, pt.y, Art.partIcons(), 10, 10, "parts");
			it.animation.frameIndex = pt.icon;
			it.icon = pt.icon;
			it.label = pt.label;
			it.friend = pt.friend != null ? pt.friend : -1;
			it.idx = i;
			partItems.add(it);
		}
		add(partItems);
		cells = new FlxTypedGroup();
		for (c in data.cells)
		{
			var it = makePickup(c.x, c.y, Art.partIcons(), 10, 10, "parts");
			it.animation.frameIndex = Parts.JET;
			it.icon = Parts.JET;
			cells.add(it);
		}
		add(cells);

		batts = new FlxTypedGroup();
		for (b in data.batteries)
		{
			var it = makePickup(b.x, b.y, Art.battery(), 8, 10, "battery");
			it.animation.add("glow", [0, 1], 3);
			it.animation.play("glow");
			batts.add(it);
		}
		add(batts);

		enemies = new FlxTypedGroup();
		grounded = new FlxGroup();
		for (e in data.enemies)
		{
			var en = new Enemy(e.kind, e.x, e.y, data);
			enemies.add(en);
			if (e.kind != LevelData.FLYER)
				grounded.add(en);
		}
		add(enemies);

		ghosts = new FlxTypedGroup();
		add(ghosts);
		bullets = new FlxTypedGroup();
		add(bullets);

		player = new Player(data.spawn.x, data.spawn.y);
		player.onJump = () ->
		{
			landT = 0;
			Audio.play("jump", player.controlled ? 0.8 : 0.25); // a követő (nem irányított) hős ugrása halkabb
			player.squash(0.78, 1.25);
			dust(player.x + 4, player.y + 12, 3);
		};
		player.onWallJump = () ->
		{
			Audio.play("walljump", 0.9);
			player.squash(0.8, 1.2);
			dust(player.x + 4, player.y + 8, 4);
		};
		player.onLand = (vy:Float) ->
		{
			landT = 0.07;
			landVol = player.controlled ? 0.6 : 0.2;
			player.squash(1.3, 0.75);
			dust(player.x + 4, player.y + 12, 4);
		};
		player.onDash = () ->
		{
			Audio.play("dash", 0.9);
			Parts.battery -= 4;
			FlxG.camera.shake(0.004, 0.08);
		};
		player.onTrail = spawnGhost;
		player.onThrust = () ->
		{
			thrustT -= FlxG.elapsed;
			if (thrustT <= 0)
			{
				thrustT = 0.03;
				var p = particles.recycle(Particle);
				p.fire(player.x + 4 + (Math.random() * 4 - 2), player.y + 12, (Math.random() - 0.5) * 24, 70 + Math.random() * 40, 0, 0.3, Math.random() < 0.5 ? 0xFFFFFFFF : 0xFFBBBBBB);
			}
		};
		player.onSlide = (dir:Int) ->
		{
			// kapaszkodás közben szikrák a karmoknál
			var p = particles.recycle(Particle);
			p.fire(player.x + (dir > 0 ? player.width : 0), player.y + 3 + Math.random() * 4, -dir * (8 + Math.random() * 12), 10 + Math.random() * 20, 120, 0.25, 0xFFBBBBBB);
		};
		player.onShoot = (x:Float, y:Float, dir:Int) ->
		{
			var b = bullets.recycle(Bullet);
			b.fire(x, y, dir, data);
			Audio.play("shoot", 0.7);
			Parts.battery -= 1.2;
			FlxG.camera.shake(0.002, 0.05);
		};
		add(player);
		player.level = data;
		ctrl = player;
		companions = new FlxTypedGroup();
		add(companions);
		for (k in 0...Companions.COUNT)
			if (Companions.owned[k])
				spawnCompanion(k, data.spawn.x - 18 * (k + 1), data.spawn.y);
		respawn = FlxPoint.get(data.spawn.x, data.spawn.y);

		particles = new FlxTypedGroup();
		add(particles);

		// kamera
		FlxG.camera.setScrollBoundsRect(0, 0, worldW, worldH, true);
		FlxG.camera.follow(player, PLATFORMER, 0.16);
		FlxG.camera.followLead.set(10, 0);
		FlxG.camera.pixelPerfectRender = true;
		FlxG.camera.focusOn(player.getMidpoint());
		FlxG.camera.fade(0xFF000000, 0.35, true);

		createLightOverlay();
		hudCam = new flixel.FlxCamera(0, 0, FlxG.width, FlxG.height);
		hudCam.bgColor = 0x00000000;
		hudCam.pixelPerfectRender = true;
		hudCam.antialiasing = false;
		hudCam.filters = [new openfl.filters.ShaderFilter(new HudShader())]; // borostyán árnyalat, de effektek nélkül
		FlxG.cameras.add(hudCam, false);
		hudLayer = new flixel.group.FlxGroup();
		hudLayer.cameras = [hudCam];
		super.add(hudLayer);
		buildHud();
		var own = [for (p in data.parts) if (p.friend == null || p.friend < 0) p.label];
		var fr = [for (p in data.parts) if (p.friend != null && p.friend >= 0) p.label];
		var names = own.join("  ") + (fr.length > 0 ? "\nFRIEND PARTS: " + fr.join("  ") : "");
		var off:Array<String> = [];
		if (!Parts.has(Parts.LEGS))
			off.push("JUMP");
		if (!Parts.has(Parts.VISOR))
			off.push("VISION");
		if (!Parts.has(Parts.CHIP))
			off.push("CONTROLS");
		if (!Parts.has(Parts.GEAR))
			off.push("AIR CONTROL");
		var offLine = off.length > 0 ? "\nSYSTEMS OFFLINE: " + off.join(", ") : "";
		bannerStr = (data.name + (data.buildings.length > 0 ? "\n(UP / E ENTERS DOORS)" : "") + "\nMISSION: FIND THE " + data.parts.length + " MISSING PARTS\n" + names + offLine);
		bannerT = 4.2;
		#if cheats
		applyDevGoto();
		#end
		#if test
		js.Syntax.code("window.__ps = {0}; window.__cam = {1}; window.__parts = {2}; window.__setBatt = {3}; window.__getBatt = {4}; window.__LevelLoader = {5}; window.__Audio = {6}; window.__Parts = {7}", this, FlxG.camera, Parts.owned, (v:Float) -> Parts.battery = v, () -> Parts.battery, LevelLoader, Audio, Parts);
		#end
	}

	/** Lámpák (Tiled: Lamp): lámpatestek; a fényt (nyaláb + sötétség) a createLightOverlay rajzolja a LampShaderrel. */
	function addLamps():Void
	{
		for (l in data.lamps)
		{
			var body = new FlxSprite(l.x - 4, l.y - 4);
			body.loadGraphic(Art.lamp(), false, 8, 8, false, "lamp");
			add(body);
		}
	}

	/** Teljes képernyős fény-réteg (a világ felett, a HUD alatt): nyalábok, ragyogás és sötétség a lámpás termekben. */
	function createLightOverlay():Void
	{
		if (data.lamps.length == 0)
			return;
		// sötét zónák: azok a termek (fal-kerettel), amikben van lámpa
		for (b in data.buildings)
		{
			var zx = (b.x0 - 1) * 16.0, zy = (b.y0 - 1) * 16.0, zw = (b.w + 2) * 16.0, zh = (b.h + 2) * 16.0;
			for (l in data.lamps)
				if (l.x >= zx && l.x <= zx + zw && l.y >= zy && l.y <= zy + zh)
				{
					lampZones.push({x: zx, y: zy, w: zw, h: zh});
					break;
				}
		}
		lampShader = new LampShader();
		lampOverlay = new FlxSprite(0, 0);
		lampOverlay.makeGraphic(480, 270, 0xFFFFFFFF, false, "lampoverlay");
		lampOverlay.scrollFactor.set(0, 0);
		lampOverlay.shader = lampShader;
		add(lampOverlay);
	}

	/** A képernyőn lévő (legközelebbi 8) lámpa és a 2 legközelebbi sötét zóna átadása a shadernek (rajzolás előtt, a kamera végleges görgetésével). */
	function updateLampUniforms():Void
	{
		var sx = Math.round(FlxG.camera.scroll.x), sy = Math.round(FlxG.camera.scroll.y);
		var cx = sx + 240, cy = sy + 135;
		var vis:Array<{l:LampDef, d:Float}> = [];
		for (l in data.lamps)
			if (l.x + l.radius > sx && l.x - l.radius < sx + 480 && l.y + l.radius > sy && l.y - l.radius < sy + 270)
				vis.push({l: l, d: (l.x - cx) * (l.x - cx) + (l.y - cy) * (l.y - cy)});
		vis.sort((p, q) -> p.d < q.d ? -1 : (p.d > q.d ? 1 : 0));
		for (i in 0...8)
		{
			var A = Reflect.field(lampShader.data, "uA" + i);
			var B = Reflect.field(lampShader.data, "uB" + i);
			if (i < vis.length)
			{
				var l = vis[i].l;
				var a = l.angle * Math.PI / 180;
				A.value = [l.x - sx, l.y - sy, l.radius, l.intensity];
				B.value = [Math.cos(a), Math.sin(a), Math.cos(l.spread * Math.PI / 360), (l.flicker ? 1.0 : -1.0) * (1.0 + i * 1.7)];
			}
			else
			{
				A.value = [0.0, 0.0, 0.0, 0.0];
				B.value = [0.0, 1.0, 0.0, 0.0];
			}
		}
		var zs:Array<{x:Float, y:Float, w:Float, h:Float, d:Float}> = [];
		for (z in lampZones)
			if (z.x + z.w > sx && z.x < sx + 480 && z.y + z.h > sy && z.y < sy + 270)
				zs.push({x: z.x, y: z.y, w: z.w, h: z.h, d: (z.x + z.w / 2 - cx) * (z.x + z.w / 2 - cx)});
		zs.sort((p, q) -> p.d < q.d ? -1 : (p.d > q.d ? 1 : 0));
		for (i in 0...2)
		{
			var Z = Reflect.field(lampShader.data, "uZ" + i);
			Z.value = i < zs.length ? [zs[i].x - sx, zs[i].y - sy, zs[i].w, zs[i].h] : [0.0, 0.0, 0.0, 0.0];
		}
		lampShader.uTime.value = [lampClock];
	}

	override public function draw():Void
	{
		if (lampShader != null)
			updateLampUniforms();
		super.draw();
	}

	function addBackdrop(bmp:openfl.display.BitmapData, fx:Float, fy:Float, y:Float):Void
	{
		var s = new FlxSprite(0, y);
		s.loadGraphic(bmp, false, 0, 0, false, "bd" + fx + "_" + level);
		s.scrollFactor.set(fx, fy);
		add(s);
	}

	function makePickup(x:Float, y:Float, bmp:openfl.display.BitmapData, w:Int, h:Int, key:String):Pickup
	{
		var p = new Pickup(x, y);
		p.loadGraphic(bmp, true, w, h, false, key);
		p.baseY = y;
		p.immovable = true;
		return p;
	}

	function label(txt:String, y:Float, size:Int, color:Int, w:Int = 480):FlxText
	{
		var t = new FlxText(0, y, w, txt, size);
		t.setFormat(null, size, color, CENTER);
		t.scrollFactor.set(0, 0);
		add(t);
		return t;
	}

	function buildHud():Void
	{
		hudAdding = true;
		for (i in 0...5)
		{
			var h = new FlxSprite(6 + i * 10, 6);
			h.loadGraphic(Art.heart(), false, 8, 8, false, "heart");
			h.scrollFactor.set(0, 0);
			add(h);
			hudHearts.push(h);
		}
		hudGems = new FlxText(6, 17, 160, "", 8);
		hudGems.scrollFactor.set(0, 0);
		add(hudGems);
		hudScore = new FlxText(480 - 166, 6, 160, "", 8);
		hudScore.setFormat(null, 8, 0xFFFFFFFF, RIGHT);
		hudScore.scrollFactor.set(0, 0);
		add(hudScore);
		// az alkatrész-foglalatok (a küldetés): üres = hiányzik, teli = megvan
		var n = data.parts.length;
		for (i in 0...n)
		{
			var s = new FlxSprite(240 - n * 7 + i * 14, 4);
			s.loadGraphic(Art.partIcons(), true, 10, 10, false, "parts");
			s.animation.frameIndex = data.parts[i].icon;
			s.scrollFactor.set(0, 0);
			s.alpha = 0.25;
			add(s);
			hudParts.push(s);
		}
		hudParts2 = label("", 16, 8, 0xFFBBBBBB);
		hudScan = new FlxText(6, 39, 200, "", 8);
		hudScan.scrollFactor.set(0, 0);
		add(hudScan);
		navArrow = new FlxText(0, 0, 150, "", 8);
		navArrow.scrollFactor.set(0, 0);
		navArrow.visible = false;
		add(navArrow);
		hudFuel = new FlxText(6, 50, 200, "", 8);
		hudFuel.scrollFactor.set(0, 0);
		add(hudFuel);
		// akku-kijelző: ikon + 10 blokk (az idővel és a műveletekkel fogy; lemerülve a robot egy időre leáll)
		battIcon = new FlxSprite(6, 27);
		battIcon.loadGraphic(Art.battery(), true, 8, 10, false, "battery");
		battIcon.scrollFactor.set(0, 0);
		add(battIcon);
		for (i in 0...10)
		{
			var s = new FlxSprite(17 + i * 5, 29);
			s.makeGraphic(4, 6, 0xFFFFFFFF);
			s.scrollFactor.set(0, 0);
			add(s);
			hudBatt.push(s);
		}
		// radar-sáv (ANTENNA): a pálya hossza, az alkatrészek, az ajtó és a hős
		radarSpr = new FlxSprite(160, 259);
		radarSpr.makeGraphic(160, 7, 0xFF000000, true);
		radarSpr.scrollFactor.set(0, 0);
		radarSpr.visible = false;
		add(radarSpr);
		hudComp = new FlxText(6, 258, 400, "", 8);
		hudComp.scrollFactor.set(0, 0);
		add(hudComp);
		marker = new FlxText(0, 0, 12, "v", 8); // a vezérelt robot jelölője a világban van, nem a HUD-on
		marker.setFormat(null, 8, 0xFFFFFFFF, CENTER);
		hudAdding = false;
		add(marker);
		hudAdding = true;
		toast = label("", 46, 8, 0xFFFFFFFF);
		toast.visible = false;
		toast.alpha = 0;
		hint = label("", 100, 8, 0xFFFFFFFF);
		hint.visible = false;
		hint.alpha = 0;
		infoBorder = new FlxSprite(0, 0);
		infoBorder.makeGraphic(1, 1, 0xFF777777);
		infoBorder.visible = false;
		add(infoBorder);
		infoFill = new FlxSprite(0, 0);
		infoFill.makeGraphic(1, 1, 0xF0080808);
		infoFill.visible = false;
		add(infoFill);
		infoText = new FlxText(46, 0, 388, "", 8);
		infoText.setFormat(null, 8, 0xFFFFFFFF, CENTER);
		infoText.visible = false;
		add(infoText);
		for (s in [infoBorder, infoFill, infoText])
			s.scrollFactor.set(0, 0);
		overlay = label("", 96, 8, 0xFFFFFFFF);
		overlay.visible = false;
		#if cheats
		var devTag = new FlxText(480 - 130, 260, 126, "DEV BUILD  F9: CHEATS", 8);
		devTag.setFormat(null, 8, 0xFF777777, RIGHT);
		devTag.scrollFactor.set(0, 0);
		add(devTag);
		#end
		hudAdding = false;
		refreshHud();
	}

	/**
	 * A következő cél: a sorrendben (balról jobbra) legközelebbi hiányzó alkatrész, majd a szerelőasztal, végül a kijárat.
	 * Ha a cél épületben van és a hős kívül (vagy fordítva), a megfelelő épület-ajtóra mutat.
	 */
	function navTarget():{x:Float, y:Float, label:String}
	{
		var tx:Float = door.x, ty:Float = door.y, label = "EXIT";
		if (partsFound < data.parts.length)
		{
			var best:Pickup = null;
			for (it in partItems)
				if (it.alive && (best == null || it.x < best.x))
					best = it;
			if (best != null)
			{
				tx = best.x;
				ty = best.y;
				label = best.label;
			}
		}
		else if (data.benches.length > 0 && !benchBuilt)
		{
			for (b in benches)
			{
				tx = b.x;
				ty = b.y;
				label = "WORKBENCH";
				break;
			}
		}
		var tIn = ty > data.killRow * 16;
		if (tIn != inside)
		{
			var bestD:Dynamic = null;
			var bd = 1e9;
			for (d in bDoors)
				if (d.toInside == tIn)
				{
					var dist = Math.abs(d.spr.x - (tIn ? tx : player.x));
					if (dist < bd)
					{
						bd = dist;
						bestD = d;
					}
				}
			if (bestD != null)
			{
				tx = bestD.spr.x;
				ty = bestD.spr.y;
				label += " (" + (tIn ? "ENTER BUILDING" : "LEAVE BUILDING") + ")";
			}
		}
		return {x: tx, y: ty, label: label};
	}

	/** Képernyőszéli nyíl: ha a cél nem látszik, a képernyő szélén jelzi az irányt és a távolságot. */
	function updateNavArrow(nt:{x:Float, y:Float, label:String}):Void
	{
		var sx = nt.x - FlxG.camera.scroll.x, sy = nt.y - FlxG.camera.scroll.y;
		var offX = sx < 2 ? -1 : (sx > 476 ? 1 : 0);
		var offY = sy < 2 ? -1 : (sy > 266 ? 1 : 0);
		if (offX == 0 && offY == 0 || teleporting)
		{
			navArrow.visible = false;
			return;
		}
		var dist = Std.int(Math.sqrt((nt.x - player.x) * (nt.x - player.x) + (nt.y - player.y) * (nt.y - player.y)) / 16);
		navArrow.visible = true;
		navArrow.alpha = 0.6 + 0.4 * Math.abs(Math.sin(time * 4));
		if (offX != 0)
		{
			navArrow.alignment = offX < 0 ? LEFT : RIGHT;
			navArrow.text = offX < 0 ? "< " + nt.label + " " + dist + "M" : nt.label + " " + dist + "M >";
			navArrow.x = offX < 0 ? 2 : 480 - 150 - 2;
			navArrow.y = Math.max(52, Math.min(246, sy - 4));
		}
		else
		{
			navArrow.alignment = CENTER;
			navArrow.text = (offY < 0 ? "^ " : "v ") + nt.label + " " + dist + "M";
			navArrow.x = Math.max(2, Math.min(328, sx - 75));
			navArrow.y = offY < 0 ? 52 : 246;
		}
	}

	function refreshHud():Void
	{
		for (i in 0...hudHearts.length)
			hudHearts[i].visible = i < maxHeartsOf(ctrl);
		for (i in 0...hudHearts.length)
			hudHearts[i].loadGraphic(i < heartsOf(ctrl) ? Art.heart() : Art.heartEmpty(), false, 8, 8, false, i < heartsOf(ctrl) ? "heart" : "heartEmpty");
		for (i in 0...hudParts.length)
			hudParts[i].alpha = found[i] ? 1 : 0.25;
		hudGems.text = "ATOMS " + gemsGot + "/" + gemsTotal + "  BANK " + Parts.atoms;
		hudScore.text = "SCORE " + score;
		hudParts2.text = "PARTS " + partsFound + "/" + data.parts.length;
		// iránymutatás: a következő cél (alkatrész / szerelőasztal / kijárat), mindig látszik
		var nt = navTarget();
		var ndx = nt.x - player.x, ndy = nt.y - player.y;
		var narrow = Math.abs(ndx) > Math.abs(ndy) ? (ndx > 0 ? ">>" : "<<") : (ndy < 0 ? "^^" : "vv");
		hudScan.text = "NEXT " + nt.label + " " + narrow + " " + Std.int(Math.sqrt(ndx * ndx + ndy * ndy) / 16) + "M";
		updateNavArrow(nt);
		updateRadar();
		updateBatteryHud();
		hudFuel.text = player.flightT > 0 ? "JET " + StringTools.rpad("", "#", Std.int(Math.ceil(player.flightT * 2))) : "";
	}

	/** A térkép-sáv (minimap) mindig látszik: a következő cél villog; az ANTENNA az összes alkatrészt, a II. szint az ellenségeket is mutatja. */
	function updateRadar():Void
	{
		radarSpr.visible = true;
		if (time - radarT < 0.1)
			return;
		radarT = time;
		var bd = radarSpr.pixels;
		bd.fillRect(new openfl.geom.Rectangle(0, 0, 160, 7), 0xFF444444);
		bd.fillRect(new openfl.geom.Rectangle(1, 1, 158, 5), 0xFF000000);
		function mx(px:Float):Int
			return 1 + Std.int(Math.max(0, Math.min(157, px / worldW * 158)));
		if (Parts.tier(Parts.ANTENNA) >= 2)
			for (e in enemies)
				if (e.alive && e.dying < 0)
					bd.fillRect(new openfl.geom.Rectangle(mx(e.x), 3, 1, 2), 0xFF777777);
		if (Parts.tier(Parts.ANTENNA) >= 2)
			for (b in batts)
				if (b.alive)
					bd.fillRect(new openfl.geom.Rectangle(mx(b.x), 1, 1, 2), 0xFFBBBBBB);
		bd.fillRect(new openfl.geom.Rectangle(mx(door.x), 1, 2, 5), 0xFFBBBBBB);
		if (Std.int(time * 4) % 2 == 0)
		{
			if (Parts.has(Parts.ANTENNA))
				for (it in partItems)
					if (it.alive)
						bd.fillRect(new openfl.geom.Rectangle(mx(it.x), 2, 2, 3), 0xFFFFFFFF);
			var rt = navTarget();
			bd.fillRect(new openfl.geom.Rectangle(mx(rt.x) - 1, 0, 4, 7), 0xFFFFFFFF);
		}
		bd.fillRect(new openfl.geom.Rectangle(mx(player.x) - 1, 0, 3, 7), 0xFFFFFFFF);
		radarSpr.dirty = true;
	}

	// --- Effektek ---

	/** Összeállítja az alsó információs panelt: bemutató, üzenet, súgó, közeli tábla (ebben a sorrendben); üres szöveg esetén elrejti. */
	function composeInfo(elapsed:Float):Void
	{
		if (bannerT > 0)
			bannerT -= elapsed;
		var lines:Array<String> = [];
		if (bannerT > 0)
			lines.push(bannerStr);
		if (toast.visible && toast.text != "")
			lines.push(toast.text);
		if (hint.visible && hint.text != "")
			lines.push(hint.text);
		else if (ctrl != null && bannerT <= 0)
			for (w in worldTexts)
				if (!w.solved && Math.abs(ctrl.x - (w.x + 100)) < 150 && Math.abs(ctrl.y - w.y) < 90)
				{
					lines.push(w.s);
					break;
				}
		var on = lines.length > 0 && !(mode == 1 || mode == 2) && !paused;
		infoBorder.visible = infoFill.visible = infoText.visible = on;
		if (!on)
			return;
		infoText.text = lines.join("\n");
		var h = Math.max(14, infoText.height) + 8;
		var w = 400;
		var py = 250 - h;
		infoBorder.setGraphicSize(w, Std.int(h));
		infoBorder.updateHitbox();
		infoBorder.setPosition(40, py);
		infoFill.setGraphicSize(w - 2, Std.int(h) - 2);
		infoFill.updateHitbox();
		infoFill.setPosition(41, py + 1);
		infoText.setPosition(46, py + 4);
	}

	function showToast(txt:String, secs:Float = 2.8):Void
	{
		toast.text = txt;
		toast.visible = true;
		toastT = secs;
	}

	function dust(x:Float, y:Float, n:Int):Void
	{
		for (i in 0...n)
		{
			var p = particles.recycle(Particle);
			p.fire(x + Math.random() * 4 - 2, y, (Math.random() - 0.5) * 50, -Math.random() * 25, 60, 0.3, 0xFF777777);
		}
	}

	function burst(x:Float, y:Float, n:Int, color:Int, speed:Float = 80):Void
	{
		for (i in 0...n)
		{
			var a = Math.random() * Math.PI * 2;
			var s = speed * (0.4 + Math.random() * 0.6);
			var p = particles.recycle(Particle);
			p.fire(x, y, Math.cos(a) * s, Math.sin(a) * s - 30, 220, 0.4 + Math.random() * 0.3, color);
		}
	}

	function spawnGhost():Void
	{
		var g = ghosts.recycle(FlxSprite);
		g.loadGraphicFromSprite(player);
		g.reset(player.x - player.offset.x, player.y - player.offset.y);
		g.animation.frameIndex = player.animation.frameIndex;
		g.flipX = player.flipX;
		g.alpha = 0.5;
		g.solid = false;
		FlxTween.tween(g, {alpha: 0}, 0.2, {onComplete: _ -> g.kill()});
	}

	function popText(txt:String, x:Float, y:Float):Void
	{
		var t = new FlxText(x - 30, y, 60, txt, 8);
		t.setFormat(null, 8, 0xFFFFFFFF, CENTER);
		add(t);
		FlxTween.tween(t, {y: y - 16, alpha: 0}, 0.8, {onComplete: _ -> t.kill()});
	}

	// --- Játék ---

	override public function update(elapsed:Float):Void
	{
		Audio.guard();
		lampClock += elapsed;
		composeInfo(elapsed);
		// látás: VISOR nélkül homályos kép (a shader uSight értéke); a LENS (II. szint) kicsit fényesít
		Main.sightTarget = Parts.has(Parts.VISOR) ? (Parts.tier(Parts.VISOR) >= 2 ? 1.2 : 1.0) : 0.4;
		// fáradtság: a lemerülő akku fokozatosan elsötétíti és elmossa a képet; leálláskor erősen
		Main.tiredTarget = player != null && player.powerDown > 0 ? 1.0 : (Parts.battery < 25 ? (25 - Parts.battery) / 25 * 0.75 : 0.0);
		if (subState == null && hudLayer != null)
			hudLayer.visible = true;
		#if cheats
		cheatUpdate();
		#end
		if (Input.pausePressed() && mode == 0)
		{
			paused = !paused;
			if (paused)
				Audio.pauseMusic();
			else
				Audio.resumeMusic();
			overlay.text = "PAUSED\n\nESC / P / START: RESUME\nR / SQUARE / SHARE: RESPAWN AT CHECKPOINT\nO / TRIANGLE: SETTINGS (MUSIC, SFX VOLUME)";
			overlay.visible = paused;
		}
		if (paused)
		{
			Audio.keepHeld();
			if (FlxG.keys.justPressed.O || Input.just(flixel.input.gamepad.FlxGamepadInputID.Y))
			{
				openSubState(new SettingsSubState());
				return;
			}
			if (Input.respawnPausedPressed())
			{
				paused = false;
				overlay.visible = false;
				Audio.resumeMusic();
				toCheckpoint(false);
			}
			return;
		}
		if (landT > 0)
		{
			landT -= elapsed;
			if (landT <= 0)
				Audio.play("land", landVol);
		}
		if (hitstop > 0)
		{
			hitstop -= elapsed;
			return;
		}
		if (toastT > 0)
		{
			toastT -= elapsed;
			if (toastT <= 0)
				toast.visible = false;
		}
		if (mode == 1)
		{
			modeT += elapsed;
			super.update(elapsed);
			collideFriends();
			if (modeT > 0.6 && Input.confirmPressed())
				finishLevel();
			return;
		}
		if (mode == 2)
		{
			modeT += elapsed;
			super.update(elapsed);
			if (modeT > 1.2)
				FlxG.resetState();
			return;
		}
		if (mode == 3)
		{
			super.update(elapsed);
			collideFriends();
			if (playerGone)
			{
				// a pálya vége: a társak is bemennek az ajtón, utána jön az összesítő
				modeT += elapsed;
				var any = false;
				companions.forEachAlive(c ->
				{
					if (c.mode == 3)
						any = true;
				});
				if (!any || modeT > 4.5)
					levelClear();
			}
			return;
		}

		time += elapsed;
		super.update(elapsed);
		if (Parts.tier(Parts.VISOR) >= 2)
		{
			// LENS: a rejtett repedezett falak villognak, az alkatrészekről szikrák szállnak
			cracked.forEachAlive(c -> c.alpha = 0.55 + 0.45 * Math.abs(Math.sin(time * 5)));
			// a titkos atomok világítanak
			gems.forEachAlive(g ->
			{
				if (g.secret)
					g.alpha = 0.5 + 0.5 * Math.abs(Math.sin(time * 4 + g.t));
			});
			if (Std.int(time * 4) != glowT)
			{
				glowT = Std.int(time * 4);
				partItems.forEachAlive(p -> burst(p.x + 5, p.y + 5, 1, 0xFFFFFFFF, 18));
			}
		}

		updateBattery(elapsed);
		updatePitRescue(elapsed);
		FlxG.collide(player, solidMap);
		if (player.dropT <= 0)
		{
			FlxG.collide(player, platMap);
			FlxG.collide(player, crumbles, onCrumble);
			FlxG.collide(player, movers, onMover);
		}
		FlxG.collide(player, cracked);
		FlxG.collide(player, gates);
		FlxG.collide(player, grates);
		FlxG.collide(player, crates);
		FlxG.collide(crates, solidMap);
		FlxG.collide(crates, platMap);
		FlxG.collide(crates, gates);
		FlxG.collide(crates, grates);
		FlxG.collide(crates, cracked);
		collideFriends();
		clampRobots();
		FlxG.collide(grounded, solidMap);
		FlxG.collide(grounded, platMap);
		FlxG.collide(grounded, cracked);
		FlxG.collide(grounded, gates);
		if (player.isTouching(FlxDirectionFlags.FLOOR))
			combo = 0;

		// minden robot (a hős és a társak) ugyanúgy felvesz, sérül és ellenségre ugrik; csak a repülő-cella a hősé
		for (r in robots())
		{
			FlxG.overlap(r, enemies, onEnemy);
			FlxG.overlap(r, gems, onGem);
			FlxG.overlap(r, hearts, onHeart);
			FlxG.overlap(r, partItems, onPart);
			FlxG.overlap(r, batts, onBatt);
			FlxG.overlap(r, spikes, onSpike);
			FlxG.overlap(r, checkpoints, onCheckpoint);
		}
		FlxG.overlap(player, cells, onCell);
		updateFriendSkills();
		updatePuzzles();
		FlxG.overlap(bullets, enemies, onBulletEnemy);
		FlxG.overlap(bullets, cracked, onBulletCracked);
		FlxG.overlap(bullets, gates, (b:Bullet, g:Gate) ->
		{
			if (!g.isOpen)
				b.kill();
		});
		FlxG.overlap(bullets, grates, (b:Bullet, g:FlxSprite) -> b.kill());

		var partsDone = partsFound >= data.parts.length;
		var allFound = partsDone && (data.benches.length == 0 || benchBuilt);
		var nearDoor = nearTo(ctrl, door, 14, 20);
		hint.visible = nearDoor;
		hint.text = allFound ? "WALK INTO THE EXIT" : (partsDone ? "BUILD YOUR FRIEND AT THE WORKBENCH FIRST" : "NEED " + (data.parts.length - partsFound) + " MORE PART" + (data.parts.length - partsFound == 1 ? "" : "S"));
		// a kijáratnál nem kell felfelé nyomni: elég nekimenni (az irányított robot belép, ha minden megvan)
		if (nearDoor && allFound && !exiting && !(ctrl == player && heroExited))
			robotEnters(ctrl);
		// elég egyetlen robotnak bemennie: a többi magától követi az ajtóhoz, a pálya akkor ér véget, ha mind beolvadt
		if (exiting)
		{
			exitT += FlxG.elapsed;
			// a nem irányított hős (AI) az ajtóhoz sétál, és ott belép (időtúllépéskor akkor is)
			if (!heroExited && (nearTo(player, door, 14, 20) || exitT > 4))
				robotEnters(player);
			if (allRobotsExited() || exitT > 9)
				levelClear();
		}
		// a társak leesése: a mentési pontra kerülnek vissza
		companions.forEachAlive(c ->
		{
			if (c.mode != 3 && ((c.y > data.killRow * 16 && !inAnyRoom(c)) || c.y > worldH + 40))
			{
				c.reset(respawn.x - 4, respawn.y);
				c.velocity.set(0, 0);
			}
		});
		// a követő hős lemaradása / elakadása: a kiválasztott robot mellé kerül
		if (ctrl != player && followAll && !ctrlFlies() && !heroExited)
		{
			var hd = Math.abs(player.x - ctrl.x);
			if (hd > 100 && player.onFloor && Math.abs(player.velocity.x) < 4)
				heroStuckT += FlxG.elapsed;
			else
				heroStuckT = 0;
			if (hd > 300 || Math.abs(player.y - ctrl.y) > 180 || heroStuckT > 1.6)
			{
				heroStuckT = 0;
				player.reset(ctrl.x - 18, ctrl.y - 6);
				player.velocity.set(0, 0);
				player.invuln = 0.5;
			}
		}
		marker.visible = companions.countLiving() > 0 && !heroExitedAll();
		marker.x = ctrl.x + ctrl.width / 2 - 6;
		marker.y = ctrl.y - 12 + Math.sin(time * 6) * 2;

		// épület-ajtók: a hős az ajtó előtt Fel / E gombbal lép be / ki
		var nearB:Int = -1;
		for (i in 0...bDoors.length)
		{
			var d = bDoors[i].spr;
			if (nearTo(ctrl, d, 12, 18))
			{
				nearB = i;
				break;
			}
		}
		if (nearB >= 0 && !hint.visible)
		{
			hint.visible = true;
			var bd = bDoors[nearB];
			hint.text = bd.fromInside == true && bd.toInside ? "UP / E: GO THROUGH" : (bd.toInside ? "UP / E: ENTER BUILDING" : "UP / E: LEAVE BUILDING");
		}
		if (nearB >= 0 && Input.interactPressed() && !teleporting)
			useDoor(bDoors[nearB]);

		if (!inside && player.y > data.killRow * 16)
			fall();
		else if (inside && player.y > worldH + 40)
			fall();
		if (Input.restartPressed())
			toCheckpoint(false);
		refreshHud();
	}

	/** Átmenet az épület ajtaján: rövid elsötétülés, a hős a célajtó elé kerül (a felvétel-pont is ott lesz). */
	function useDoor(d:{spr:FlxSprite, tx:Float, ty:Float, toInside:Bool}):Void
	{
		teleporting = true;
		var r = ctrl;
		var isHero = r == player;
		if (isHero)
			player.frozen = true;
		r.velocity.set(0, 0);
		Audio.play("door", 0.5);
		FlxG.camera.fade(0xFF000000, 0.18, false, () ->
		{
			if (isHero)
			{
				player.frozen = false;
				player.reset(d.tx - 4, d.ty);
				player.invuln = 0.4;
				inside = d.toInside;
				respawn.set(d.tx - 4, d.ty);
			}
			else
				r.reset(d.tx - 4, d.ty);
			r.velocity.set(0, 0);
			FlxG.camera.focusOn(r.getMidpoint());
			FlxG.camera.fade(0xFF000000, 0.18, true);
			new FlxTimer().start(0.25, _ -> teleporting = false);
		});
	}


	/** Az akku fogyása: idővel és a műveletekkel; kimerülve a robot ~4 mp-re leáll (sötét kép), majd kevés töltéssel újraindul. */
	var pitT:Float = 0;
	var rescuing:Bool = false;

	/**
	 * Gödör-mentés: ha a hős egy nyitott tetejű gödörben ül (mindkét oldalon fal), amiből ugrással és karmok nélkül nem jut ki
	 * (pl. a 3. pálya kútja a CLAWS előtt), kb. 2 mp után a vészlift a legközelebbi peremre emeli (kevés akkuba kerül).
	 */
	function updatePitRescue(dt:Float):Void
	{
		if (rescuing || ctrl != player || heroExited || exiting || !player.onFloor || player.frozen || Parts.has(Parts.CLAWS) || player.flightT > 0 || inAnyRoom(player))
		{
			pitT = 0;
			return;
		}
		var T = LevelData.T;
		var pc = Std.int((player.x + player.width / 2) / T);
		var fr = Std.int((player.y + player.height - 1) / T);
		var minRise = 999;
		var rimCol = 0;
		var rimRow = 0;
		var s = -1;
		while (s <= 1)
		{
			var c = pc;
			var n = 0;
			while (n < 5 && !data.isSolid(c, fr))
			{
				c += s;
				n++;
			}
			if (!data.isSolid(c, fr))
			{
				pitT = 0; // az egyik oldal nyitott: simán kisétál
				return;
			}
			var r = fr;
			while (r > fr - 14 && data.isSolid(c, r - 1))
				r--;
			var rise = fr + 1 - r;
			if (rise < minRise && !data.isSolid(c, r - 1) && !data.isSolid(c, r - 2))
			{
				minRise = rise;
				rimCol = c;
				rimRow = r;
			}
			s += 2;
		}
		// a perem elérhető ugrással, vagy nincs használható perem, vagy tető van fölöttünk (terem): nem csapda
		var open = minRise < 999 && minRise * T > player.jumpReach() + 10;
		if (open)
			for (k in 1...minRise + 1)
				if (data.isSolid(pc, fr - k))
					open = false;
		if (!open)
		{
			pitT = 0;
			return;
		}
		pitT += dt;
		if (pitT < 2.0)
			return;
		pitT = 0;
		rescuing = true;
		player.frozen = true;
		player.moves = false;
		player.velocity.set(0, 0);
		Parts.battery = Math.max(0, Parts.battery - 5);
		Audio.play("dash", 0.9);
		showToast("TRAPPED! EMERGENCY LIFT ENGAGED", 2.4);
		var tx = rimCol * T + T / 2 - player.width / 2;
		var ty = rimRow * T - player.height;
		var steps = 0;
		FlxTween.tween(player, {x: tx, y: ty}, 0.9, {ease: FlxEase.cubeInOut, onUpdate: _ ->
		{
			// fúvóka-láng a láb alatt
			if (steps++ % 2 == 0)
				burst(player.x + player.width / 2, player.y + player.height, 2, 0xFFFFFFFF, 40);
		}, onComplete: _ ->
		{
			player.frozen = false;
			player.moves = true;
			player.velocity.set(0, 0);
			player.invuln = Math.max(player.invuln, 0.5);
			rescuing = false;
			ring(player.x + player.width / 2, player.y + player.height, 16, 60);
		}});
	}

	function updateBattery(dt:Float):Void
	{
		// az újraindulás: a leállás lejárt (a hős powerDown értéke negatívba fordult), kevés töltéssel indul újra
		if (player.powerDown < 0 && Parts.battery <= 0.001)
		{
			Parts.battery = 18;
			player.powerDown = 0;
			wasDown = false;
			Audio.play("checkpoint", 1);
			showToast("REBOOT COMPLETE", 2.2);
			burst(player.x + 4, player.y + 6, 12, 0xFFFFFFFF, 80);
			return;
		}
		if (player.powerDown > 0)
			return;
		var drain = 0.7;
		if (player.flightT > 0 && Input.jumpHeld())
			drain += 2.5;
		Parts.battery -= drain * dt;
		if (Parts.battery <= 0)
		{
			Parts.battery = 0;
			player.powerDown = 4.2;
			wasDown = true;
			Audio.play("fall", 0.9);
			showToast("BATTERY EMPTY: REBOOTING...", 4.0);
			FlxG.camera.shake(0.01, 0.25);
		}
		else if (Parts.battery < 20)
		{
			lowT -= dt;
			if (lowT <= 0)
			{
				lowT = 1.6;
				Audio.play("blip", 0.9);
			}
		}
	}

	function updateBatteryHud():Void
	{
		var n = Std.int(Math.ceil(Parts.battery / 10));
		var low = Parts.battery < 20;
		var blink = !low || Std.int(time * 5) % 2 == 0;
		for (i in 0...hudBatt.length)
			hudBatt[i].alpha = i < n ? (blink ? 1 : 0.4) : 0.15;
		battIcon.animation.frameIndex = low && !blink ? 1 : 0;
	}

	function onBatt(p:FlxSprite, b:Pickup):Void
	{
		if (player.powerDown > 0)
			return;
		b.kill();
		Parts.battery = Math.min(100, Parts.battery + 35);
		Audio.play("heal", 0.9);
		ring(b.x + 4, b.y + 5, 16, 70);
		burst(b.x + 4, b.y + 5, 10, 0xFFFFFFFF, 70);
		showToast("BATTERY PACK +35%", 2.0);
		score += 30;
	}

	/** Látványos alkatrész-felvétel: lassítás, táguló gyűrűk, a nagy ikon középre pattan, majd a HUD foglalatába repül. */
	function partFx(it:Pickup):Void
	{
		hitstop = 0.2;
		ring(it.x + 5, it.y + 5, 28, 55);
		ring(it.x + 5, it.y + 5, 24, 100);
		ring(it.x + 5, it.y + 5, 18, 150);
		burst(it.x + 5, it.y + 5, 30, 0xFFFFFFFF, 170);
		var big = new FlxSprite(235, 92);
		big.loadGraphic(Art.partIcons(), true, 10, 10, false, "parts");
		big.animation.frameIndex = it.icon;
		big.scrollFactor.set(0, 0);
		big.scale.set(0.2, 0.2);
		hudAdding = true;
		add(big);
		hudAdding = false;
		var n = data.parts.length;
		var sx = 240 - n * 7 + it.idx * 14;
		FlxTween.tween(big.scale, {x: 7, y: 7}, 0.4, {ease: FlxEase.backOut});
		FlxTween.tween(big, {x: sx, y: 4.0}, 0.6, {startDelay: 1.4, ease: FlxEase.cubeIn});
		FlxTween.tween(big.scale, {x: 1, y: 1}, 0.6, {startDelay: 1.4, ease: FlxEase.cubeIn, onComplete: _ ->
		{
			big.kill();
			FlxG.camera.flash(0xFFFFFFFF, 0.12);
		}});
	}

	/** Táguló részecske-gyűrű. */
	function ring(x:Float, y:Float, n:Int, speed:Float):Void
	{
		for (k in 0...n)
		{
			var a = k * Math.PI * 2 / n;
			var p = particles.recycle(Particle);
			p.fire(x, y, Math.cos(a) * speed, Math.sin(a) * speed, 0, 0.55, 0xFFFFFFFF);
		}
	}

	/** A társak ütközése a talajjal, platformokkal és kapukkal (a pálya-vég animáció alatt is, különben leesnének). */
	/** A terminál mini-játéka (házanként más: kirakó, sorrend, lámpák, tank); a megoldás kinyitja a belső terem kapuját. */
	function openTerminal(s:FlxSprite):Void
	{
		var id = s.ID;
		ctrl.velocity.x = 0;
		var g = MiniGames.make(termGame.get(id), level + 1, (won:Bool) ->
		{
			if (won)
			{
				termSolved.set(id, true);
				s.animation.play("done");
				setGate(id, true);
				score += 300;
				showToast("TERMINAL SOLVED: THE INNER DOOR OPENS", 3.0);
			}
		});
		openSubState(g);
	}

	function collideFriends():Void
	{
		FlxG.collide(companions, solidMap);
		FlxG.collide(companions, platMap);
		FlxG.collide(companions, gates);
		// a leszakadó platform a társ alatt is elindul (ezért gyorsan át kell kelniük rajta)
		FlxG.collide(companions, crumbles, (c:Companion, cr:Crumble) ->
		{
			if (c.isTouching(FlxDirectionFlags.FLOOR))
				cr.trigger();
		});
		FlxG.collide(companions, crates);
		FlxG.collide(companions, movers);
		// a mozgó platform viszi a rajta álló társat (a talp a platform tetején, vízszintesen átfedik egymást); az ütközés-callback erre nem volt megbízható
		companions.forEachAlive(c ->
		{
			if (c.velocity.y < -1)
				return;
			for (i in 0...movers.length)
			{
				var m = movers.members[i];
				if (m != null && m.alive && m.exists && Math.abs((c.y + c.height) - m.y) < 3.5 && c.x + c.width > m.x && c.x < m.x + m.width)
				{
					c.x += m.dx;
					break;
				}
			}
		});
		companions.forEachAlive(c ->
		{
			if (c.kind == Companions.TALL)
			{
				FlxG.collide(c, grates);
				if (c.mode == 1)
				{
					// a várakozó TALL feje platform: a hős és a többi társ rá tud állni
					FlxG.collide(player, c);
					companions.forEachAlive(o ->
					{
						if (o != c)
							FlxG.collide(o, c);
					});
				}
			}
		});
	}

	/** Egy társ létrehozása a megadott helyen. */
	function spawnCompanion(kind:Int, x:Float, y:Float):Companion
	{
		var c = new Companion(kind, x, y, data, ctrl != null ? ctrl : player);
		c.mode = followAll ? 0 : 1;
		c.onSpecial = doSpecial;
		// a mozgó platformok a követő számára: hova ugorhat (és milyen sebességgel megy a platform)
		c.movingStand = (tx:Int, ty:Int) ->
		{
			var T = LevelData.T;
			for (i in 0...movers.length)
			{
				var m = movers.members[i];
				if (m != null && m.alive && m.exists && m.x < tx * T + T && m.x + m.width > tx * T && Math.abs(m.y - ty * T) < 9)
					return m.vx;
			}
			// leszakadó platform (amíg ép): a társ ráugorhat és átkelhet rajta
			for (i in 0...crumbles.length)
			{
				var cr = crumbles.members[i];
				if (cr != null && cr.alive && cr.exists && cr.allowCollisions != FlxDirectionFlags.NONE && cr.x < tx * T + T && cr.x + cr.width > tx * T && Math.abs(cr.y - ty * T) < 9)
					return 0.0;
			}
			return null;
		};
		companions.add(c);
		return c;
	}

	/** Bármelyik (életben lévő, kilépetlen) robot hozzáér-e a tárgyhoz: a kulcsot, az áramcellát és a többi küldetés-tárgyat a társak is felveszik. */
	function anyRobotOverlaps(s:FlxSprite):Bool
	{
		for (r in robots())
			if (r.overlaps(s))
				return true;
		return false;
	}

	/** A pálya szélein láthatatlan fal: a robotok nem eshetnek le a világ széléről. */
	function clampRobots():Void
	{
		for (r in robots())
		{
			if (r.x < 0)
			{
				r.x = 0;
				r.velocity.x = Math.max(0, r.velocity.x);
			}
			else if (r.x + r.width > worldW)
			{
				r.x = worldW - r.width;
				r.velocity.x = Math.min(0, r.velocity.x);
			}
			if (r.y < -64)
			{
				r.y = -64;
				r.velocity.y = Math.max(0, r.velocity.y);
			}
		}
	}

	function nearTo(a:FlxSprite, b:FlxSprite, dx:Float, dy:Float):Bool
		return Math.abs((a.x + a.width / 2) - (b.x + b.width / 2)) < dx && Math.abs((a.y + a.height / 2) - (b.y + b.height / 2)) < dy;

	/** Megoldott rejtvény: a megoldást sejtető feliratok (pl. "ORDER: ...") és a kapcsoló-betűk eltűnnek. */
	function hideSolvedHints(id:Int):Void
	{
		var pts:Array<{x:Float, y:Float}> = [];
		for (s in switches)
			if (s.gid == id)
				pts.push({x: s.x, y: s.y});
		for (l in levers)
			if (l.gid == id)
				pts.push({x: l.x, y: l.y});
		for (p in plates)
			if (p.gid == id)
				pts.push({x: p.x, y: p.y});
		for (s in sockets)
			if (s.gid == id)
				pts.push({x: s.x, y: s.y});
		gates.forEach(g ->
		{
			if (g.gid == id)
				pts.push({x: g.x, y: g.y});
		});
		for (w in worldTexts)
			for (q in pts)
				if (Math.abs(w.x + 100 - q.x) < 220 && Math.abs(w.y - q.y) < 100)
					w.solved = true;
		for (sl in switchLabels)
			if (sl.gid == id)
				sl.t.visible = false;
	}

	function setGate(id:Int, open:Bool):Void
	{
		var changed = false;
		gates.forEach(g ->
		{
			if (g.gid == id && g.isOpen != open)
			{
				g.setOpen(open);
				changed = true;
				if (open)
					burst(g.x + 8, g.y + 8, 3, 0xFFBBBBBB, 40);
			}
		});
		if (changed && open)
			hideSolvedHints(id);
		if (changed)
		{
			Audio.play(open ? "plate" : "crumble", 0.9);
			FlxG.camera.shake(0.005, 0.15);
		}
	}

	/**
	 * A rejtvény-elemek logikája: nyomólapok (a hős, láda vagy társ lenyomja), karok (ORB / hős), sorrend-kapcsolók, kulcs + zárt kapu,
	 * áramcella + aljzat + emelő, szerelőasztal (társ megépítése), társ-parancsok.
	 */
	function updatePuzzles():Void
	{
		var act = Input.interactPressed();
		// számítógép-terminál: az irányított robot használja (mini-játék a játékban)
		for (s in terminals)
			if (!termSolved.exists(s.ID) && nearTo(ctrl, s, 14, 20))
			{
				if (!hint.visible)
				{
					hint.visible = true;
					hint.text = "UP / E: USE THE COMPUTER";
				}
				if (act && !teleporting)
				{
					openTerminal(s);
					return;
				}
			}
		// nyomólapok
		for (p in plates)
		{
			var on = (p.overlaps(player) && player.isTouching(FlxDirectionFlags.FLOOR)) || p.overlaps(crates) || p.overlaps(companions);
			if (p.hold)
			{
				if (on != p.pressed)
				{
					p.setPressed(on);
					setGate(p.gid, on);
					if (on)
						showToast("GATE OPENED", 1.8);
					else
						showToast("GATE CLOSED", 1.2);
				}
			}
			else if (on && !p.pressed)
			{
				p.setPressed(true);
				setGate(p.gid, true);
				showToast("GATE OPENED", 2.2);
			}
		}
		// karok: az ORB (vagy a hős Fel / E-vel) átbillenti
		for (l in levers)
			if (!l.flipped)
			{
				var byOrb = false;
				companions.forEachAlive(c ->
				{
					if (c.kind == Companions.ORB && l.overlaps(c))
					{
						byOrb = true;
					}
				});
				if (byOrb || (act && nearTo(ctrl, l, 14, 18)))
				{
					l.flip();
					setGate(l.gid, true);
					Audio.play("plate", 1);
					showToast("LEVER PULLED: GATE OPENED", 2.4);
				}
			}
		// sorrend-kapcsolók
		if (act)
			for (s in switches)
				if (nearTo(ctrl, s, 14, 20))
				{
					var order = data.seqs.get(s.gid);
					var st = seqState.exists(s.gid) ? seqState.get(s.gid) : 0;
					if (order == null || st >= order.length)
						continue;
					if (order[st] == s.idx)
					{
						s.setDown(true);
						Audio.play("blip", 1);
						st++;
						seqState.set(s.gid, st);
						if (st >= order.length)
						{
							setGate(s.gid, true);
							showToast("ACCESS GRANTED", 2.4);
						}
					}
					else
					{
						seqState.set(s.gid, 0);
						switches.forEach(o ->
						{
							if (o.gid == s.gid)
								o.setDown(false);
						});
						Audio.play("hurt", 0.6);
						showToast("WRONG ORDER: RESET", 2.0);
					}
					break;
				}
		// kulcsok és zárt kapuk
		for (k in keysG)
			if (k.alive && anyRobotOverlaps(k))
			{
				k.kill();
				keysHeld.set(k.idx, true);
				Audio.play("key", 0.9);
				burst(k.x + 5, k.y + 4, 10, 0xFFFFFFFF, 60);
				showToast("KEY FOUND", 2.0);
			}
		for (g in gates)
			if (g.locked && !g.isOpen && keysHeld.exists(g.gid) && nearTo(ctrl, g, 20, 60))
			{
				keysHeld.remove(g.gid);
				setGate(g.gid, true);
				showToast("UNLOCKED", 2.0);
			}
		// áramcella + aljzat + emelő
		for (c in powerCells)
			if (c.alive && anyRobotOverlaps(c))
			{
				c.kill();
				carryCell = c.idx;
				Audio.play("heal", 0.9);
				burst(c.x + 4, c.y + 6, 10, 0xFFFFFFFF, 60);
				showToast("POWER CELL: TAKE IT TO THE SOCKET", 2.6);
			}
		if (act && carryCell >= 0)
			for (s in sockets)
				if (!s.filled && s.gid == carryCell && nearTo(ctrl, s, 16, 20))
				{
					s.fill();
					carryCell = -1;
					movers.forEach(m ->
					{
						if (m.gid == s.gid)
							m.powered = true;
					});
					Audio.play("door", 0.8);
					showToast("LIFT POWERED", 2.4);
				}
		// szerelőasztal: a társ megépítése
		if (act)
			for (b in benches)
				if (nearTo(ctrl, b, 20, 24) && !Companions.owned[b.ID])
				{
					if (friendFound[b.ID] >= 3)
						buildFriend(b.ID, b);
					else
						showToast("NEED " + (3 - friendFound[b.ID]) + " MORE PART" + (3 - friendFound[b.ID] == 1 ? "" : "S") + " FOR " + Companions.NAMES[b.ID], 2.4);
				}
		// robotváltás (Lost Vikings): Tab / R1 körbe, 1-4 közvetlenül; Q: a várakozó társak követnek / várnak
		var bots = robots();
		if (bots.indexOf(ctrl) < 0 && bots.length > 0)
			setControl(bots[0]);
		if (Input.cyclePressed() && bots.length > 1)
			setControl(bots[(bots.indexOf(ctrl) + 1) % bots.length]);
		var dg = Input.digitPressed();
		if (dg > 0 && dg <= bots.length && bots[dg - 1] != ctrl)
			setControl(bots[dg - 1]);
		if (Input.commandPressed() && companions.countLiving() > 0)
		{
			followAll = !followAll;
			applyModes();
			showToast(followAll ? "FRIENDS FOLLOW YOU" : "FRIENDS WAIT", 1.6);
		}
		hudComp.text = companions.countLiving() > 0 ? "CONTROL: " + nameOf(ctrl) + "   TAB / 1-4: SWITCH ROBOT   Q: FRIENDS " + (followAll ? "FOLLOW" : "WAIT") : (carryCell >= 0 ? "CARRYING: POWER CELL" : "");
	}

	/** A (még a pályán lévő) robotok: a hős és a társak. */
	function robots():Array<FlxSprite>
	{
		var r:Array<FlxSprite> = [];
		if (!heroExited)
			r.push(player);
		for (c in companions)
			if (c.alive && c.mode != 3)
				r.push(c);
		return r;
	}

	function nameOf(s:FlxSprite):String
		return s == player ? "ROBOT" : Companions.NAMES[cast(s, Companion).kind];

	/** Az irányított robot kiválasztása: a többi vár (vagy követ); a kamera az irányított robotot követi. */
	function setControl(s:FlxSprite):Void
	{
		if (exiting)
			return; // a kijáratnál már az automatikus belépés zajlik
		ctrl = s;
		player.controlled = s == player;
		applyModes();
		FlxG.camera.follow(s, PLATFORMER, 0.16);
		Audio.play("select", 0.6);
	}

	function applyModes():Void
	{
		// követés: a nem irányított hős is a kiválasztott robotot követi (Q)
		// repülő (ORB) irányítása közben a földi robotok nem követik: csak leesnének utána (az ORB-ot viszont a többiek követik)
		var ground = followAll && !ctrlFlies();
		player.followTarget = ctrl != player && ground ? ctrl : null;
		companions.forEachAlive(c ->
		{
			c.target = ctrl;
			if (c.mode != 3)
				c.mode = c == ctrl ? 4 : (followAll && (c.kind == Companions.ORB || !ctrlFlies()) ? 0 : 1);
		});
	}

	/** Az irányított robot repül-e (az ORB lebeg, a többi nem tud követni). */
	function ctrlFlies():Bool
		return ctrl != player && Std.isOfType(ctrl, Companion) && cast(ctrl, Companion).kind == Companions.ORB;

	/** A robot egy épület belső termében (vagy közvetlenül a környékén) van-e (a mélyben a leesés-ellenőrzéshez). */
	function inAnyRoom(c:FlxSprite):Bool
	{
		for (b in data.buildings)
			if (c.x > b.x0 * 16 - 32 && c.x < (b.x0 + b.w) * 16 + 32 && c.y > b.y0 * 16 - 32 && c.y < (b.y0 + b.h) * 16 + 64)
				return true;
		return false;
	}

	function heroExitedAll():Bool
		return heroExited && companions.countLiving() <= 0;

	function allRobotsExited():Bool
		return heroExited && !player.visible && companions.countLiving() <= 0;

	/** A társ összeépítése a szerelőasztalnál: látványos felvillanás, a társ megjelenik és csatlakozik. */
	function buildFriend(kind:Int, bench:FlxSprite):Void
	{
		Companions.owned[kind] = true;
		benchBuilt = true;
		var c = spawnCompanion(kind, bench.x + 8, bench.y - 20);
		hitstop = 0.25;
		ring(bench.x + 12, bench.y + 4, 30, 60);
		ring(bench.x + 12, bench.y + 4, 24, 110);
		burst(bench.x + 12, bench.y + 4, 30, 0xFFFFFFFF, 170);
		FlxG.camera.flash(0xFFFFFFFF, 0.4);
		Audio.play("door", 1);
		showToast("YOU BUILT A FRIEND: " + Companions.NAMES[kind] + "\nQ: SEND / WAIT   TAB: SWITCH FRIEND", 4.5);
		if (partsFound >= data.parts.length)
			door.animation.play("open");
	}

	function onCrumble(p:Player, c:Crumble):Void
	{
		if (p.isTouching(FlxDirectionFlags.FLOOR))
			c.trigger();
	}

	function onMover(p:Player, m:Mover):Void
	{
		if (p.isTouching(FlxDirectionFlags.FLOOR))
			p.x += m.dx;
	}

	/** Ellenségre ugrás / ütközés: a hősre és a társakra ugyanaz a szabály (a WHEELIE turbó közben kiüti, a többiek rálépnek vagy megsérülnek). */
	function onEnemy(p:FlxSprite, e:Enemy):Void
	{
		if (p == player)
		{
			onEnemyHero(player, e);
			return;
		}
		var c = cast(p, Companion);
		if (!e.alive || e.dying >= 0)
			return;
		if (c.turboT > 0)
		{
			defeat(e, 150);
			return;
		}
		var above = c.velocity.y > 20 && (c.last.y + c.height) <= e.y + 6;
		if (e.stompable && above)
		{
			defeat(e, 100);
			c.velocity.y = -260;
			hitstop = 0.05;
			return;
		}
		// az ellenség csak azt a robotot sebzi, akit éppen irányítunk
		if (c == ctrl && c.takeHit(e.x + e.width / 2))
			damagedCompanion(c);
	}

	function damagedCompanion(c:Companion):Void
	{
		Main.hitFx = 1;
		Audio.play("hurt", 0.8);
		FlxG.camera.shake(0.008, 0.15);
		burst(c.x + 4, c.y + 4, 8, 0xFFFFFFFF, 80);
		if (c.hearts <= 0)
		{
			c.hearts = c.maxHearts;
			c.reset(respawn.x - 4, respawn.y);
			c.velocity.set(0, 0);
			showToast(Companions.NAMES[c.kind] + " WAS DEFEATED: BACK AT THE CHECKPOINT", 2.6);
		}
	}

	function heartsOf(s:FlxSprite):Int
		return s == player ? player.hearts : cast(s, Companion).hearts;

	function maxHeartsOf(s:FlxSprite):Int
		return s == player ? player.maxHearts : cast(s, Companion).maxHearts;

	/** A társak különleges képességei: WHEELIE turbó-gurulás (áttöri a repedezett falat), TALL láda-emelés, ORB szikra (kart billent, ellenséget üt); a szállított láda követi a társat. */
	function updateFriendSkills():Void
	{
		companions.forEachAlive(c ->
		{
			if (c.carrying != null)
			{
				c.carrying.x = c.x + c.width / 2 - 8;
				c.carrying.y = c.y - 17;
			}
			if (c.turboT > 0)
			{
				FlxG.overlap(c, cracked, (a:FlxSprite, b:FlxSprite) ->
				{
					b.kill();
					Audio.play("break", 1);
					burst(b.x + 8, b.y + 8, 12, 0xFFBBBBBB, 90);
					FlxG.camera.shake(0.006, 0.12);
				});
				dust(c.x + 4, c.y + 8, 1);
			}
		});
		FlxG.overlap(bullets, levers, (b:Bullet, l:Lever) ->
		{
			if (!l.flipped)
			{
				b.kill();
				l.flip();
				setGate(l.gid, true);
				Audio.play("plate", 1);
				showToast("LEVER ZAPPED: GATE OPENED", 2.4);
			}
		});
	}

	function doSpecial(c:Companion):Void
	{
		switch (c.kind)
		{
			case Companions.WHEELIE:
				c.turboT = 0.45;
				Audio.play("dash", 0.9);
				FlxG.camera.shake(0.004, 0.08);
			case Companions.TALL:
				if (c.carrying != null)
				{
					var cr = c.carrying;
					c.carrying = null;
					cr.drop(c.x + c.width / 2 + c.face * 12 - 8, c.y + 6);
					Audio.play("land", 0.8);
				}
				else
				{
					var best:Crate = null;
					var bd = 40.0;
					for (cr in crates)
					{
						if (cr.carried)
							continue;
						var d = Math.abs(cr.x + 8 - (c.x + c.width / 2)) + Math.abs(cr.y + 8 - (c.y + c.height - 8));
						if (d < bd)
						{
							bd = d;
							best = cr;
						}
					}
					if (best != null)
					{
						best.carry();
						c.carrying = best;
						Audio.play("key", 0.7);
					}
					else
						showToast("NOTHING TO LIFT", 1.2);
				}
			default:
				var b = bullets.recycle(Bullet);
				b.fire(c.x + c.width / 2 + c.face * 6, c.y + 3, c.face, data);
				Audio.play("shoot", 0.7);
		}
	}

	function onEnemyHero(p:Player, e:Enemy):Void
	{
		if (!e.alive || e.dying >= 0)
			return;
		if (p.dashing)
		{
			defeat(e, 150);
			return;
		}
		var above = p.velocity.y > 20 && (p.last.y + p.height) <= e.y + 6;
		if (e.stompable && above)
		{
			defeat(e, 100);
			p.bounce();
			hitstop = 0.05;
			return;
		}
		// az ellenség csak azt a robotot sebzi, akit éppen irányítunk (a többi átmegy rajta)
		if (p == ctrl && p.takeHit(e.x + e.width / 2))
			damaged();
	}

	function onBulletEnemy(b:Bullet, e:Enemy):Void
	{
		if (!e.alive || e.dying >= 0)
			return;
		b.kill();
		defeat(e, 120);
	}

	function onBulletCracked(b:Bullet, c:FlxSprite):Void
	{
		b.kill();
		c.kill();
		Audio.play("break", 1);
		burst(c.x + 8, c.y + 8, 12, 0xFFBBBBBB, 90);
		FlxG.camera.shake(0.006, 0.12);
	}

	function defeat(e:Enemy, pts:Int):Void
	{
		combo++;
		var gain = pts * combo;
		score += gain;
		burst(e.x + 6, e.y + 4, 10, 0xFFBBBBBB, 90);
		Audio.play(e.kind == LevelData.WALKER ? "stomp" : "kill", 1);
		popText("+" + gain, e.x + 6, e.y - 4);
		FlxG.camera.shake(0.006, 0.1);
		e.defeat();
	}

	function damaged():Void
	{
		Main.hitFx = 1;
		Audio.play("hurt", 1);
		hitstop = 0.08;
		FlxG.camera.shake(0.012, 0.2);
		FlxG.camera.flash(0xFFFFFFFF, 0.12);
		burst(player.x + 4, player.y + 6, 8, 0xFFFFFFFF, 90);
		if (player.hearts <= 0)
			die();
	}

	function onGem(p:FlxSprite, g:Pickup):Void
	{
		g.kill();
		if (g.secret)
		{
			Parts.atoms += 3;
			score += 50;
			Audio.play("key", 0.8);
			burst(g.x + 4, g.y + 4, 14, 0xFFFFFFFF, 90);
			popText("SECRET ATOM +3", g.x + 4, g.y - 6);
		}
		else
		{
			gemsGot++;
			Parts.atoms++;
			score += 10;
			Audio.play("gem", 0.7);
			burst(g.x + 4, g.y + 4, 6, 0xFFFFFFFF, 50);
		}
	}

	function onHeart(p:FlxSprite, h:Pickup):Void
	{
		h.kill();
		var healed = false;
		if (p == player)
		{
			if (player.hearts < player.maxHearts)
			{
				player.hearts++;
				healed = true;
			}
		}
		else
		{
			var c = cast(p, Companion);
			if (c.hearts < c.maxHearts)
			{
				c.hearts++;
				healed = true;
			}
		}
		if (!healed)
			score += 50;
		Audio.play("heal", 0.9);
		burst(h.x + 4, h.y + 4, 8, 0xFFFFFFFF, 60);
	}

	/** Alkatrész felvétele: a küldetés előrehalad, a képesség (ha új) visszatér, a robot megjelenése is változik. */
	function onPart(p:FlxSprite, it:Pickup):Void
	{
		it.kill();
		found[it.idx] = true;
		partsFound++;
		var tier = 1;
		if (it.friend >= 0)
			friendFound[it.friend]++;
		else
		{
			tier = Parts.add(it.icon);
			player.refreshLook();
			player.applyParts();
			if (it.icon == Parts.CORE && player.hearts < player.maxHearts)
				player.hearts++;
		}
		score += 250;
		Audio.play("key", 1);
		burst(it.x + 5, it.y + 5, 16, 0xFFFFFFFF, 100);
		FlxG.camera.flash(0xFFFFFFFF, 0.35);
		partFx(it);
		if (it.friend < 0)
			startShowcase(it.icon, tier);
		var info = it.friend >= 0 ? "A PART FOR YOUR FRIEND " + Companions.NAMES[it.friend] : (tier <= 1 ? Parts.INFO[it.icon] : (Parts.INFO2[it.icon] != "" ? Parts.INFO2[it.icon] : "INSTALLED"));
		var msg = "FOUND: " + it.label + "\n" + info;
		if (partsFound >= data.parts.length)
		{
			if (data.benches.length > 0 && !benchBuilt)
				msg += "\nALL PARTS FOUND: BUILD YOUR FRIEND AT THE WORKBENCH";
			else
			{
				msg += "\nALL PARTS FOUND: GO TO THE DOOR";
				door.animation.play("open");
			}
		}
		if (partsFound < data.parts.length)
			msg += "
NEXT: " + navTarget().label + " >>";
		showToast(msg, 3.6);
	}

	var showcase:Showcase;

	/** Rövid mozgó bemutató az új képességről (a sarokban, a hős valódi kinézetével). */
	function startShowcase(icon:Int, tier:Int):Void
	{
		if (icon >= Parts.COUNT)
			return;
		if (showcase != null)
		{
			hudLayer.remove(showcase, true);
			showcase.destroy();
		}
		showcase = new Showcase(icon, tier, 2.1);
		hudAdding = true;
		add(showcase);
		hudAdding = false;
	}

	function onCell(p:Player, c:Pickup):Void
	{
		c.kill();
		p.flightT = Player.FLIGHT_TIME;
		Audio.play("heal", 0.9);
		burst(c.x + 5, c.y + 5, 10, 0xFFFFFFFF, 70);
		showToast("JET CELL: HOLD JUMP IN THE AIR TO FLY", 3.2);
	}

	function onSpike(p:FlxSprite, s:FlxSprite):Void
	{
		if (p == player)
		{
			if (player.takeHit(s.x + 6))
			{
				player.velocity.y = -230;
				damaged();
			}
		}
		else
		{
			var c = cast(p, Companion);
			if (c.takeHit(s.x + 6))
			{
				c.velocity.y = -230;
				damagedCompanion(c);
			}
		}
	}

	function onCheckpoint(p:FlxSprite, c:Pickup):Void
	{
		if (c.animation.name == "on")
			return;
		c.animation.play("on");
		respawn.set(c.x - 2, c.y - 2);
		Audio.play("checkpoint", 0.9);
		burst(c.x + 4, c.y + 3, 8, 0xFFFFFFFF, 50);
		popText("CHECKPOINT", c.x + 4, c.y - 8);
	}

	/** Nyomólap: a kapu kinyílik (örökre). */
	function onPlate(p:Player, pl:FlxSprite):Void
	{
		if (pl.animation.name == "down" || p.velocity.y < -10)
			return;
		pl.animation.play("down");
		Audio.play("plate", 1);
		showToast("GATE OPENED", 2.2);
		FlxG.camera.shake(0.006, 0.2);
		gates.forEachAlive(g ->
		{
			burst(g.x + 8, g.y + 8, 3, 0xFFBBBBBB, 40);
			g.kill();
		});
	}

	function fall():Void
	{
		Audio.play("fall", 0.9);
		player.hearts--;
		if (player.hearts <= 0)
		{
			die();
			return;
		}
		FlxG.camera.shake(0.01, 0.15);
		toCheckpoint(true);
	}

	function toCheckpoint(penalty:Bool):Void
	{
		if (ctrl != player)
		{
			// az irányított társ a mentési pontra kerül (R)
			ctrl.reset(respawn.x - 4, respawn.y);
			ctrl.velocity.set(0, 0);
			return;
		}
		crates.forEach(c -> c.resetPos());
		player.respawnAt(respawn.x, respawn.y);
		inside = respawn.y > data.killRow * 16 - 40;
		FlxG.camera.focusOn(player.getMidpoint());
		combo = 0;
		refreshHud();
	}

	function die():Void
	{
		mode = 2;
		modeT = 0;
		Audio.play("hurt", 1);
		player.visible = false;
		burst(player.x + 4, player.y + 6, 20, 0xFFFFFFFF, 120);
		overlay.text = "SIGNAL LOST";
		overlay.visible = true;
		FlxG.camera.shake(0.015, 0.3);
	}

	/** Belépés az ajtón: a robot az ajtó közepére megy és beleolvad; a vezérlés a következő robotra ugrik. A pálya akkor ér véget, ha mind bent van. */
	function robotEnters(r:FlxSprite):Void
	{
		var first = !exiting;
		exiting = true;
		if (first)
			exitT = 0;
		hint.visible = false;
		door.animation.play("open");
		Audio.play("door", 1);
		if (r == player)
		{
			heroExited = true;
			player.frozen = true;
			player.moves = false;
			player.velocity.set(0, 0);
			player.acceleration.set(0, 0);
			player.invuln = 0;
			player.visible = true;
			var tx = door.x + 8 - player.width / 2;
			var ty = door.y + door.height - player.height;
			FlxTween.tween(player, {x: tx, y: ty}, 0.3, {onComplete: _ ->
			{
				FlxTween.tween(player.scale, {x: 0.1, y: 0.1}, 0.35);
				FlxTween.tween(player, {alpha: 0}, 0.35, {onComplete: _ -> player.visible = false});
			}});
		}
		else
			cast(r, Companion).enterDoor(door.x + 8, door.y + door.height);
		if (!first)
			return;
		// a többi robot automatikusan követi: a társak az ajtóhoz mennek (mode 3), a hőst az AI viszi oda
		companions.forEachAlive(c ->
		{
			if (c != r && c.mode != 3)
				c.enterDoor(door.x + 8, door.y + door.height);
		});
		if (r != player && !heroExited)
		{
			player.controlled = false;
			player.followTarget = door;
		}
	}

	function levelClear():Void
	{
		mode = 1;
		modeT = 0;
		var bonus = gemsGot == gemsTotal ? 500 : 0;
		score += bonus + Std.int(Math.max(0, 600 - time) * 2);
		var m = Std.int(time / 60), s = Std.int(time % 60);
		var names = [for (p in data.parts) p.label].join(" ");
		var lines = "LEVEL " + (level + 1) + " CLEAR\n\nPARTS " + names + "\nATOMS " + gemsGot + "/" + gemsTotal + (bonus > 0 ? "  ALL FOUND +500" : "") + "\nATOM BANK " + Parts.atoms + (canUpgrade() ? "  (WORKSHOP READY)" : "") + "\nTIME " + m + ":" + (s < 10 ? "0" : "") + s + "\nSCORE " + score + "\n\nPRESS JUMP";
		overlay.text = lines;
		overlay.visible = true;
		refreshHud();
	}

	var workshopShown:Bool = false;

	/** Van-e olyan birtokolt alkatrész, amit az atom-bankból fejleszteni lehet (és elég az atom)? */
	function canUpgrade():Bool
	{
		if (Parts.atoms < Workshop.COST)
			return false;
		for (i in 0...Parts.COUNT)
			if (Parts.has(i) && Parts.INFO2[i] != "" && Parts.tier(i) < 2)
				return true;
		return false;
	}

	/** A pálya végén: ha van mit fejleszteni, megnyílik a műhely (atomokért II. szintű alkatrész), utána jön a következő pálya. */
	function finishLevel():Void
	{
		if (canUpgrade() && !workshopShown)
		{
			workshopShown = true;
			var g = new Workshop();
			g.setup("WORKSHOP", "THE ATOMS YOU COLLECTED POWER UPGRADES. SPEND THEM ON AN IMPROVED PART.", "UP / DOWN: SELECT    SPACE / A: UPGRADE    ESC / B: CONTINUE", 1, (ok:Bool) -> nextLevel());
			openSubState(g);
			return;
		}
		nextLevel();
	}

	function nextLevel():Void
	{
		totalScore = score;
		Parts.commit();
		Companions.commit();
		level++;
		if (level >= LevelData.COUNT)
			FlxG.switchState(() -> new EndState());
		else
			FlxG.switchState(() -> new PlayState());
	}

	#if cheats
	// ---------------------------------------------------------------- cheatek (csak fejlesztői build) ----------------------------------------------------------------
	public var cheatGod:Bool = false;
	public var cheatInfBatt:Bool = false;
	public var cheatSight:Bool = false;
	/** A fáradtság-effekt kézi értéke (-1 = az akkuból számolt). */
	var cheatTired:Float = -1;
	var pendingMini:Int = -1;

	function cheatUpdate():Void
	{
		if (cheatSight)
			Main.sightTarget = 0.1;
		if (cheatTired >= 0)
			Main.tiredTarget = cheatTired;
		if (cheatGod && player != null)
		{
			player.hearts = player.maxHearts;
			player.invuln = Math.max(player.invuln, 0.1);
			for (c in companions)
				c.hearts = c.maxHearts;
		}
		if (cheatInfBatt)
			Parts.battery = 100;
		if (pendingMini >= 0 && subState == null)
		{
			var g = pendingMini;
			pendingMini = -1;
			openSubState(MiniGames.make(g, level + 1, (won:Bool) -> {}));
		}
		// fejlesztői gyorsbillentyűk: PageDown / PageUp: következő / előző ugrási pont a pályán; F7 / F8: előző / következő pálya
		if (subState == null && mode == 0)
		{
			if (FlxG.keys.justPressed.PAGEDOWN)
				cheatStep(1);
			else if (FlxG.keys.justPressed.PAGEUP)
				cheatStep(-1);
			else if (FlxG.keys.justPressed.F8)
				cheatGoto((level + 1) % LevelData.COUNT);
			else if (FlxG.keys.justPressed.F7)
				cheatGoto((level + LevelData.COUNT - 1) % LevelData.COUNT);
		}
		if (subState == null && mode == 0 && (FlxG.keys.justPressed.F9 || Input.r2New))
			openSubState(new CheatSubState(this));
	}

	public function cheatHeal():Void
	{
		player.hearts = player.maxHearts;
		for (c in companions)
			c.hearts = c.maxHearts;
		showToast("CHEAT: HEALED", 1.4);
	}

	public function cheatDamage():Void
	{
		player.hearts = Std.int(Math.max(0, player.hearts - 1));
		player.invuln = 0;
		damaged();
	}

	public function cheatKill():Void
	{
		player.hearts = 0;
		die();
	}

	/** URL-ből (?goto=...&parts=...) kért fejlesztői ugrás: a pálya betöltése után lefut (Main állítja). */
	public static var devGoto:String = null;
	public static var devParts:String = null;
	var spotIdx:Int = -1;

	/** Fejlesztői ugrási pontok a pályán: kulcs (URL-hez), név (menühöz) és a hős helye. */
	public function cheatSpots():Array<{key:String, name:String, x:Float, y:Float}>
	{
		var l:Array<{key:String, name:String, x:Float, y:Float}> = [];
		var ph = player.height;
		l.push({key: "spawn", name: "SPAWN", x: data.spawn.x, y: data.spawn.y});
		for (i in 0...data.checkpoints.length)
			l.push({key: "cp" + (i + 1), name: "CHECKPOINT " + (i + 1), x: data.checkpoints[i].x, y: data.checkpoints[i].y});
		for (i in 0...data.parts.length)
			l.push({key: "part" + (i + 1), name: "PART " + (i + 1) + ": " + data.parts[i].label, x: data.parts[i].x - 2, y: data.parts[i].y - 6});
		for (i in 0...data.buildings.length)
		{
			var b = data.buildings[i];
			l.push({key: "building" + (i + 1), name: "INSIDE BUILDING " + (i + 1), x: b.x0 * 16 + 24, y: (b.y0 + b.h) * 16 - ph - 2});
		}
		for (i in 0...bDoors.length)
		{
			var d = bDoors[i];
			l.push({key: "door" + (i + 1), name: "DOOR " + (i + 1) + (d.fromInside == true ? " (INSIDE)" : " (OUTSIDE)"), x: d.spr.x, y: d.spr.y + d.spr.height - ph});
		}
		for (i in 0...data.terminals.length)
			l.push({key: "terminal" + (i + 1), name: "TERMINAL " + (i + 1), x: data.terminals[i].x, y: data.terminals[i].y + 16 - ph});
		for (i in 0...data.benches.length)
			l.push({key: "bench" + (i + 1), name: "WORKBENCH " + (i + 1), x: data.benches[i].x, y: data.benches[i].y + 16 - ph});
		l.push({key: "exit", name: "EXIT DOOR", x: data.door.x, y: data.door.y + 24 - ph});
		return l;
	}

	/** A hős (és a barátai) odaugrik; a feléledési pont is ide kerül, így a halál után itt folytatódik a teszt. */
	public function cheatTeleportTo(x:Float, y:Float):Void
	{
		player.reset(x, y);
		player.velocity.set(0, 0);
		ctrl = player;
		inside = y > data.killRow * 16 - 40;
		respawn.set(x, y);
		FlxG.camera.focusOn(player.getMidpoint());
		bannerT = 0;
		cheatGather();
	}

	public function cheatStep(d:Int):Void
	{
		var sp = cheatSpots();
		spotIdx = ((spotIdx + d) % sp.length + sp.length) % sp.length;
		cheatTeleportTo(sp[spotIdx].x, sp[spotIdx].y);
		showToast("TELEPORT " + (spotIdx + 1) + "/" + sp.length + ": " + sp[spotIdx].name, 1.6);
	}

	/** Az előző pályák alkatrészei (mintha végigjátszottad volna őket): a pálya-ugrás utáni fejlesztéshez. */
	public function cheatPartsOfEarlierLevels():Void
	{
		for (i in 0...level)
		{
			var d = LevelLoader.load(i);
			for (p in d.parts)
				if ((p.friend == null || p.friend < 0) && p.icon >= 0 && p.icon < Parts.COUNT)
					Parts.add(p.icon);
		}
		Parts.commit();
		player.applyParts();
		player.refreshLook();
		showToast("CHEAT: PARTS OF PREVIOUS LEVELS", 1.6);
	}

	function applyDevGoto():Void
	{
		if (devParts == "prev")
			cheatPartsOfEarlierLevels();
		else if (devParts == "all")
			cheatAllParts();
		devParts = null;
		if (devGoto == null)
			return;
		var g = devGoto;
		devGoto = null;
		var xy = ~/^(-?[0-9.]+),(-?[0-9.]+)$/;
		if (xy.match(g))
		{
			cheatTeleportTo(Std.parseFloat(xy.matched(1)), Std.parseFloat(xy.matched(2)));
			return;
		}
		var sp = cheatSpots();
		for (i in 0...sp.length)
			if (sp[i].key == g)
			{
				spotIdx = i;
				cheatTeleportTo(sp[i].x, sp[i].y);
				showToast("TELEPORT: " + sp[i].name, 2.0);
				return;
			}
		showToast("UNKNOWN GOTO: " + g, 3.0);
	}

	public function cheatToDoor():Void
	{
		player.reset(door.x, door.y + door.height - player.height);
		player.velocity.set(0, 0);
	}

	public function cheatUnstick():Void
	{
		player.reset(player.x, player.y - 40);
		player.velocity.set(0, 0);
	}

	public function cheatPart(id:Int):Void
	{
		Parts.add(id);
		player.applyParts();
		player.refreshLook();
		showToast("CHEAT: " + Parts.NAMES[id] + " TIER " + Parts.tier(id), 1.6);
	}

	public function cheatAllParts():Void
	{
		for (i in 0...Parts.COUNT)
			if (!Parts.has(i))
				Parts.add(i);
		player.applyParts();
		player.refreshLook();
		showToast("CHEAT: ALL PARTS", 1.6);
	}

	public function cheatStripParts():Void
	{
		Parts.owned = [for (_ in 0...Parts.COUNT) false];
		Parts.tiers = [for (_ in 0...Parts.COUNT) 0];
		player.applyParts();
		player.refreshLook();
		showToast("CHEAT: NAKED ROBOT", 1.6);
	}

	public function cheatBattery(v:Float):Void
	{
		Parts.battery = v;
		player.powerDown = 0;
		showToast("CHEAT: BATTERY " + Std.int(v) + "%", 1.4);
	}

	public function cheatPowerDown():Void
	{
		Parts.battery = 0;
		player.powerDown = 4.2;
	}

	public function cheatShock():Void
	{
		Main.hitFx = 1;
		Audio.play("hurt", 1);
	}

	public function cheatCycleTired():Void
	{
		cheatTired = cheatTired < 0 ? 0.0 : (cheatTired < 0.3 ? 0.5 : (cheatTired < 0.8 ? 1.0 : -1.0));
	}

	public function cheatTiredName():String
		return cheatTired < 0 ? "AUTO (FROM BATTERY)" : Std.int(cheatTired * 100) + "%";

	public function cheatCompanion(kind:Int):Void
	{
		Companions.owned[kind] = true;
		for (c in companions)
			if (c.kind == kind && c.alive)
				return;
		spawnCompanion(kind, player.x + 24, player.y - 10);
		showToast("CHEAT: " + Companions.NAMES[kind] + " JOINS", 1.6);
	}

	public function cheatGather():Void
	{
		for (c in companions)
			if (c.alive)
			{
				c.reset(player.x + (c.kind - 1) * 22, player.y - (c.kind == Companions.ORB ? 18 : 4));
				c.velocity.set(0, 0);
			}
	}

	public function cheatFollow():Bool
		return followAll;

	public function cheatToggleFollow():Void
		followAll = !followAll;

	public function cheatHurtFriends():Void
	{
		for (c in companions)
			if (c.alive)
			{
				c.invuln = 0;
				if (c.takeHit(c.x + 20))
					damagedCompanion(c);
			}
	}

	public function cheatOpenGates():Void
	{
		for (g in gates)
			setGate(g.gid, true);
		showToast("CHEAT: GATES OPEN", 1.6);
	}

	public function cheatSolveTerminals():Void
	{
		for (s in terminals)
			solveTerminal(s);
		showToast("CHEAT: TERMINALS SOLVED", 1.6);
	}

	function solveTerminal(s:FlxSprite):Void
	{
		if (termSolved.exists(s.ID))
			return;
		termSolved.set(s.ID, true);
		s.animation.play("done");
		setGate(s.ID, true);
	}

	public function cheatTerminalCount():Int
		return terminals.members.length;

	public function cheatTerminalName(i:Int):String
	{
		var s = terminals.members[i];
		return "TERMINAL " + (i + 1) + ": " + MiniGames.TITLES[termGame.get(s.ID) % MiniGames.COUNT] + (termSolved.exists(s.ID) ? "  (SOLVED)" : "");
	}

	/** Egy terminál azonnali feloldása (kinyílik a belső kapu). */
	public function cheatUnlockTerminal(i:Int):Void
	{
		solveTerminal(terminals.members[i]);
		showToast("CHEAT: TERMINAL " + (i + 1) + " UNLOCKED", 1.6);
	}

	/** A cheat-menü megnyitása egy futó mini-játékból (a HUD-kamerán, hogy az effektek ne érintsék). */
	public function cheatMenuFrom(mini:MiniGames.MiniGame):CheatSubState
	{
		var c = new CheatSubState(this, mini);
		c.cameras = [hudCam];
		return c;
	}

	public function cheatComplete():Void
	{
		if (mode == 0)
			levelClear();
	}

	public function cheatNextLevel():Void
		nextLevel();

	public function cheatPrevLevel():Void
		cheatGoto(Std.int(Math.max(0, level - 1)));

	public function cheatRestart():Void
		cheatGoto(level);

	public function cheatGoto(n:Int):Void
	{
		FlxG.timeScale = 1;
		level = n;
		FlxG.switchState(() -> new PlayState());
	}

	public function cheatEnemy(kind:Int):Void
	{
		var en = new Enemy(kind, player.x + 48 * (player.faceDir >= 0 ? 1 : -1), player.y - 10, data);
		enemies.add(en);
	}

	public function cheatKillEnemies():Void
	{
		for (e in enemies)
			if (e.alive)
				e.kill();
	}

	public function cheatMini(game:Int):Void
	{
		pendingMini = game;
	}
	#end

	override public function destroy():Void
	{
		#if cheats
		FlxG.timeScale = 1;
		#end
		respawn = flixel.util.FlxDestroyUtil.put(respawn);
		super.destroy();
	}
}
