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
import Puzzle;

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
	var crumbles:FlxTypedGroup<Crumble>;
	var movers:FlxTypedGroup<Mover>;
	var bullets:FlxTypedGroup<Bullet>;
	var door:FlxSprite;
	/** Épület-ajtók: a felszíni (be) és a belső (ki) ajtók; mindegyik a célpontját tudja. */
	var bDoors:Array<{spr:FlxSprite, tx:Float, ty:Float, toInside:Bool}> = [];
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
	var hudFuel:FlxText;
	var radarSpr:FlxSprite;
	var radarT:Float = 0;
	var glowT:Int = -1;
	var batts:FlxTypedGroup<Pickup>;
	var hudBatt:Array<FlxSprite> = [];
	var battIcon:FlxSprite;
	var wasDown:Bool = false;
	var lowT:Float = 0;
	var banner:FlxText;
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
	var modeT:Float = 0;
	var thrustT:Float = 0;
	var worldW:Int;
	var worldH:Int;

	override public function create():Void
	{
		super.create();
		Audio.init();
		Audio.playMusic();
		bgColor = 0xFF000000;
		Parts.restore();
		Companions.restore();
		data = LevelData.generate(level);
		worldW = data.w * LevelData.T;
		worldH = LevelData.H * LevelData.T;
		score = totalScore;
		found = [for (_ in data.parts) false];

		// háttér: csillagok és két réteg távoli rom (paralaxis)
		addBackdrop(Art.stars(480 + Std.int(worldW * 0.05), 7), 0.05, 0.03, -70);
		addBackdrop(Art.backdrop(480 + Std.int(worldW * 0.18), 11 + level, "5", 30), 0.18, 0.12, -70);
		addBackdrop(Art.backdrop(480 + Std.int(worldW * 0.34), 29 + level, "6", 60), 0.34, 0.2, -60);

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
		for (tx in data.texts)
		{
			var lb = new FlxText(tx.x, tx.y, 220, tx.text, 8);
			lb.setFormat(null, 8, 0xFF999999, LEFT);
			add(lb);
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
		for (b in data.buildings)
		{
			var outer = new FlxSprite(b.sx, b.sy);
			outer.loadGraphic(Art.bdoor(), false, 16, 24, false, "bdoor");
			add(outer);
			var inner = new FlxSprite(b.ix, b.iy);
			inner.loadGraphic(Art.bdoor(), false, 16, 24, false, "bdoor");
			add(inner);
			bDoors.push({spr: outer, tx: b.ix + 4, ty: b.iy + 24 - 30, toInside: true});
			bDoors.push({spr: inner, tx: b.sx + 4, ty: b.sy + 24 - 30, toInside: false});
		}

		gems = new FlxTypedGroup();
		for (g in data.gems)
		{
			var p = makePickup(g.x, g.y, Art.gem(), 8, 8, "gem");
			p.animation.add("spin", [0, 1, 2, 3], 6);
			p.animation.play("spin");
			gems.add(p);
		}
		gemsTotal = data.gems.length;
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
			Audio.play("jump", 0.8);
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
			Audio.play("land", 0.6);
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
		banner = label(data.name + (data.buildings.length > 0 ? "\n(UP / E ENTERS DOORS)" : "") + "\nMISSION: FIND THE " + data.parts.length + " MISSING PARTS\n" + names + offLine, 84, 8, 0xFFFFFFFF);
		FlxTween.tween(banner, {alpha: 0}, 0.8, {startDelay: 3.4});
		#if test
		js.Syntax.code("window.__ps = {0}; window.__cam = {1}; window.__parts = {2}; window.__setBatt = {3}; window.__getBatt = {4}", this, FlxG.camera, Parts.owned, (v:Float) -> Parts.battery = v, () -> Parts.battery);
		#end
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
		hudComp = new FlxText(6, 258, 300, "", 8);
		hudComp.scrollFactor.set(0, 0);
		add(hudComp);
		toast = label("", 46, 8, 0xFFFFFFFF);
		toast.visible = false;
		hint = label("", 100, 8, 0xFFFFFFFF);
		hint.visible = false;
		overlay = label("", 96, 8, 0xFFFFFFFF);
		overlay.visible = false;
		refreshHud();
	}

	function refreshHud():Void
	{
		for (i in 0...hudHearts.length)
			hudHearts[i].visible = i < player.maxHearts;
		for (i in 0...hudHearts.length)
			hudHearts[i].loadGraphic(i < player.hearts ? Art.heart() : Art.heartEmpty(), false, 8, 8, false, i < player.hearts ? "heart" : "heartEmpty");
		for (i in 0...hudParts.length)
			hudParts[i].alpha = found[i] ? 1 : 0.25;
		hudGems.text = "GEMS " + gemsGot + "/" + gemsTotal;
		hudScore.text = "SCORE " + score;
		hudParts2.text = "PARTS " + partsFound + "/" + data.parts.length;
		// a VISOR iránytűje a legközelebbi hiányzó alkatrész felé
		hudScan.text = "";
		if (Parts.has(Parts.ANTENNA) && partsFound < data.parts.length)
		{
			var best:Pickup = null;
			var bd = 1e9;
			for (it in partItems)
				if (it.alive)
				{
					var d = Math.abs(it.x - player.x) + Math.abs(it.y - player.y);
					if (d < bd)
					{
						bd = d;
						best = it;
					}
				}
			if (best != null)
			{
				var dx = best.x - player.x, dy = best.y - player.y;
				var arrow = Math.abs(dx) > Math.abs(dy) ? (dx > 0 ? ">>" : "<<") : (dy < 0 ? "^^" : "vv");
				hudScan.text = "SCAN " + best.label + " " + arrow + " " + Std.int(Math.sqrt(dx * dx + dy * dy) / 16) + "M";
			}
		}
		updateRadar();
		updateBatteryHud();
		hudFuel.text = player.flightT > 0 ? "JET " + StringTools.rpad("", "#", Std.int(Math.ceil(player.flightT * 2))) : "";
	}

	/** A radar (ANTENNA): térkép-sáv a pálya egészéről; a II. szinten az ellenségek is látszanak. */
	function updateRadar():Void
	{
		radarSpr.visible = Parts.has(Parts.ANTENNA);
		if (!radarSpr.visible || time - radarT < 0.1)
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
			for (it in partItems)
				if (it.alive)
					bd.fillRect(new openfl.geom.Rectangle(mx(it.x), 2, 2, 3), 0xFFFFFFFF);
		bd.fillRect(new openfl.geom.Rectangle(mx(player.x) - 1, 0, 3, 7), 0xFFFFFFFF);
		radarSpr.dirty = true;
	}

	// --- Effektek ---

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
		// látás: VISOR nélkül homályos kép (a shader uSight értéke); a LENS (II. szint) kicsit fényesít
		Main.sightTarget = Parts.has(Parts.VISOR) ? (Parts.tier(Parts.VISOR) >= 2 ? 1.2 : 1.0) : 0.4;
		if (player != null && player.powerDown > 0)
			Main.sightTarget = 0.12;
		if (Input.pausePressed() && mode == 0)
		{
			paused = !paused;
			if (paused)
				Audio.pauseMusic();
			else
				Audio.resumeMusic();
			overlay.text = "PAUSED\n\nESC / P: RESUME      R: RESPAWN AT CHECKPOINT";
			overlay.visible = paused;
		}
		if (paused)
			return;
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
			if (modeT > 0.6 && Input.confirmPressed())
				nextLevel();
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
			return;
		}

		time += elapsed;
		super.update(elapsed);
		if (Parts.tier(Parts.VISOR) >= 2)
		{
			// LENS: a rejtett repedezett falak villognak, az alkatrészekről szikrák szállnak
			cracked.forEachAlive(c -> c.alpha = 0.55 + 0.45 * Math.abs(Math.sin(time * 5)));
			if (Std.int(time * 4) != glowT)
			{
				glowT = Std.int(time * 4);
				partItems.forEachAlive(p -> burst(p.x + 5, p.y + 5, 1, 0xFFFFFFFF, 18));
			}
		}

		updateBattery(elapsed);
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
		FlxG.collide(companions, solidMap);
		FlxG.collide(companions, platMap);
		FlxG.collide(companions, gates);
		companions.forEachAlive(c ->
		{
			if (c.kind == Companions.TALL)
			{
				FlxG.collide(c, grates);
				if (c.mode == 1)
					FlxG.collide(player, c);
			}
		});
		FlxG.collide(grounded, solidMap);
		FlxG.collide(grounded, platMap);
		FlxG.collide(grounded, cracked);
		FlxG.collide(grounded, gates);
		if (player.isTouching(FlxDirectionFlags.FLOOR))
			combo = 0;

		FlxG.overlap(player, enemies, onEnemy);
		FlxG.overlap(player, gems, onGem);
		FlxG.overlap(player, hearts, onHeart);
		FlxG.overlap(player, partItems, onPart);
		FlxG.overlap(player, cells, onCell);
		FlxG.overlap(player, batts, onBatt);
		FlxG.overlap(player, spikes, onSpike);
		FlxG.overlap(player, checkpoints, onCheckpoint);
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
		var nearDoor = Math.abs((player.x + 4) - (door.x + 8)) < 12 && Math.abs((player.y + 6) - (door.y + 12)) < 18;
		hint.visible = nearDoor && !allFound;
		hint.text = partsDone ? "BUILD YOUR FRIEND AT THE WORKBENCH FIRST" : "NEED " + (data.parts.length - partsFound) + " MORE PART" + (data.parts.length - partsFound == 1 ? "" : "S");
		if (nearDoor && allFound)
			enterDoor();

		// épület-ajtók: a hős az ajtó előtt Fel / E gombbal lép be / ki
		var nearB:Int = -1;
		for (i in 0...bDoors.length)
		{
			var d = bDoors[i].spr;
			if (Math.abs((player.x + 4) - (d.x + 8)) < 12 && Math.abs((player.y + 6) - (d.y + 12)) < 18)
			{
				nearB = i;
				break;
			}
		}
		if (nearB >= 0 && !hint.visible)
		{
			hint.visible = true;
			hint.text = bDoors[nearB].toInside ? "UP / E: ENTER BUILDING" : "UP / E: LEAVE BUILDING";
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
		player.frozen = true;
		player.velocity.set(0, 0);
		Audio.play("door", 0.5);
		FlxG.camera.fade(0xFF000000, 0.18, false, () ->
		{
			player.frozen = false;
			player.reset(d.tx - 4, d.ty);
			player.velocity.set(0, 0);
			player.invuln = 0.4;
			inside = d.toInside;
			respawn.set(d.tx - 4, d.ty);
			FlxG.camera.focusOn(player.getMidpoint());
			FlxG.camera.fade(0xFF000000, 0.18, true);
			new FlxTimer().start(0.25, _ -> teleporting = false);
		});
	}

	/** Az akku fogyása: idővel és a műveletekkel; kimerülve a robot ~4 mp-re leáll (sötét kép), majd kevés töltéssel újraindul. */
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

	function onBatt(p:Player, b:Pickup):Void
	{
		if (p.powerDown > 0)
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
		add(big);
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

	/** Egy társ létrehozása a megadott helyen. */
	function spawnCompanion(kind:Int, x:Float, y:Float):Companion
	{
		var c = new Companion(kind, x, y, data, player);
		companions.add(c);
		return c;
	}

	function nearTo(a:FlxSprite, b:FlxSprite, dx:Float, dy:Float):Bool
		return Math.abs((a.x + a.width / 2) - (b.x + b.width / 2)) < dx && Math.abs((a.y + a.height / 2) - (b.y + b.height / 2)) < dy;

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
						c.setStay();
					}
				});
				if (byOrb || (act && nearTo(player, l, 14, 18)))
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
				if (nearTo(player, s, 14, 20))
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
			if (k.alive && k.overlaps(player))
			{
				k.kill();
				keysHeld.set(k.idx, true);
				Audio.play("key", 0.9);
				burst(k.x + 5, k.y + 4, 10, 0xFFFFFFFF, 60);
				showToast("KEY FOUND", 2.0);
			}
		for (g in gates)
			if (g.locked && !g.isOpen && keysHeld.exists(g.gid) && nearTo(player, g, 20, 60))
			{
				keysHeld.remove(g.gid);
				setGate(g.gid, true);
				showToast("UNLOCKED", 2.0);
			}
		// áramcella + aljzat + emelő
		for (c in powerCells)
			if (c.alive && c.overlaps(player))
			{
				c.kill();
				carryCell = c.idx;
				Audio.play("heal", 0.9);
				burst(c.x + 4, c.y + 6, 10, 0xFFFFFFFF, 60);
				showToast("POWER CELL: TAKE IT TO THE SOCKET", 2.6);
			}
		if (act && carryCell >= 0)
			for (s in sockets)
				if (!s.filled && s.gid == carryCell && nearTo(player, s, 16, 20))
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
				if (nearTo(player, b, 20, 24) && !Companions.owned[b.ID])
				{
					if (friendFound[b.ID] >= 3)
						buildFriend(b.ID, b);
					else
						showToast("NEED " + (3 - friendFound[b.ID]) + " MORE PART" + (3 - friendFound[b.ID] == 1 ? "" : "S") + " FOR " + Companions.NAMES[b.ID], 2.4);
				}
		// társ-parancsok
		var list:Array<Companion> = [for (c in companions) if (c.alive) c];
		if (list.length > 0)
		{
			if (selComp >= list.length)
				selComp = 0;
			if (Input.cyclePressed())
				selComp = (selComp + 1) % list.length;
			if (Input.commandPressed())
			{
				var c = list[selComp];
				var dx = (Input.right() ? 1 : 0) - (Input.left() ? 1 : 0);
				c.command(dx, 0);
				Audio.play("blip", 0.8);
			}
			var c = list[selComp];
			hudComp.text = Companions.NAMES[c.kind] + ": " + (c.mode == 0 ? "FOLLOWING" : (c.mode == 1 ? "WAITING" : "SENT")) + "  (Q: SEND/WAIT" + (list.length > 1 ? "  TAB: SWITCH" : "") + ")";
		}
		else
			hudComp.text = carryCell >= 0 ? "CARRYING: POWER CELL" : "";
	}

	/** A társ összeépítése a szerelőasztalnál: látványos felvillanás, a társ megjelenik és csatlakozik. */
	function buildFriend(kind:Int, bench:FlxSprite):Void
	{
		Companions.owned[kind] = true;
		benchBuilt = true;
		var c = spawnCompanion(kind, bench.x + 8, bench.y - 20);
		c.mode = 0;
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

	function onEnemy(p:Player, e:Enemy):Void
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
		if (p.takeHit(e.x + e.width / 2))
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
		Audio.play("hurt", 1);
		hitstop = 0.08;
		FlxG.camera.shake(0.012, 0.2);
		FlxG.camera.flash(0xFFFFFFFF, 0.12);
		burst(player.x + 4, player.y + 6, 8, 0xFFFFFFFF, 90);
		if (player.hearts <= 0)
			die();
	}

	function onGem(p:Player, g:Pickup):Void
	{
		g.kill();
		gemsGot++;
		score += 10;
		Audio.play("gem", 0.7);
		burst(g.x + 4, g.y + 4, 6, 0xFFFFFFFF, 50);
	}

	function onHeart(p:Player, h:Pickup):Void
	{
		h.kill();
		if (player.hearts < player.maxHearts)
			player.hearts++;
		else
			score += 50;
		Audio.play("heal", 0.9);
		burst(h.x + 4, h.y + 4, 8, 0xFFFFFFFF, 60);
	}

	/** Alkatrész felvétele: a küldetés előrehalad, a képesség (ha új) visszatér, a robot megjelenése is változik. */
	function onPart(p:Player, it:Pickup):Void
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
		showToast(msg, 3.6);
	}

	function onCell(p:Player, c:Pickup):Void
	{
		c.kill();
		p.flightT = Player.FLIGHT_TIME;
		Audio.play("heal", 0.9);
		burst(c.x + 5, c.y + 5, 10, 0xFFFFFFFF, 70);
		showToast("JET CELL: HOLD JUMP IN THE AIR TO FLY", 3.2);
	}

	function onSpike(p:Player, s:FlxSprite):Void
	{
		if (p.takeHit(s.x + 6))
		{
			p.velocity.y = -230;
			damaged();
		}
	}

	function onCheckpoint(p:Player, c:Pickup):Void
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

	/** Belépés az ajtón: a hős az ajtó közepére sétál, és beleolvad (nem esik le, nem tűnik el hirtelen). */
	function enterDoor():Void
	{
		mode = 3;
		player.frozen = true;
		player.moves = false;
		player.velocity.set(0, 0);
		player.acceleration.set(0, 0);
		player.invuln = 0;
		player.visible = true;
		hint.visible = false;
		door.animation.play("open");
		Audio.play("door", 1);
		var tx = door.x + 8 - player.width / 2;
		var ty = door.y + door.height - player.height;
		FlxTween.tween(player, {x: tx, y: ty}, 0.3, {onComplete: _ ->
		{
			FlxTween.tween(player.scale, {x: 0.1, y: 0.1}, 0.35);
			FlxTween.tween(player, {alpha: 0}, 0.35, {onComplete: _ -> levelClear()});
		}});
	}

	function levelClear():Void
	{
		mode = 1;
		modeT = 0;
		var bonus = gemsGot == gemsTotal ? 500 : 0;
		score += bonus + Std.int(Math.max(0, 600 - time) * 2);
		var m = Std.int(time / 60), s = Std.int(time % 60);
		var names = [for (p in data.parts) p.label].join(" ");
		var lines = "LEVEL " + (level + 1) + " CLEAR\n\nPARTS " + names + "\nGEMS " + gemsGot + "/" + gemsTotal + (bonus > 0 ? "  ALL FOUND +500" : "") + "\nTIME " + m + ":" + (s < 10 ? "0" : "") + s + "\nSCORE " + score + "\n\nPRESS JUMP";
		overlay.text = lines;
		overlay.visible = true;
		refreshHud();
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

	override public function destroy():Void
	{
		respawn = flixel.util.FlxDestroyUtil.put(respawn);
		super.destroy();
	}
}
