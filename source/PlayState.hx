package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.tile.FlxBaseTilemap.FlxTilemapAutoTiling;
import flixel.tile.FlxTilemap;
import flixel.tweens.FlxTween;
import flixel.util.FlxDirectionFlags;

/** Egy felvehető / dekorációs tárgy (gyémánt, szív, kulcs, ellenőrzőpont). */
class Pickup extends FlxSprite
{
	public var baseY:Float;
	public var t:Float = Math.random() * 6;
	public var bob:Bool = true;

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

/**
 * A játék: egy pálya (generált szegmensekből). Gyémántok és szívek gyűjtése, kulcs a toronyban, ellenségekre ugrálás, szökellés, ajtó a végén.
 * Ütközés-sorrend: a játékos és az ellenségek frissítése, utána a csempe-ütközések, majd az átfedések.
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
	var checkpoints:FlxTypedGroup<Pickup>;
	var spikes:FlxTypedGroup<FlxSprite>;
	var keyItem:Pickup;
	var door:FlxSprite;
	var particles:FlxTypedGroup<Particle>;
	var ghosts:FlxTypedGroup<FlxSprite>;

	var hudHearts:Array<FlxSprite> = [];
	var hudGems:FlxText;
	var hudScore:FlxText;
	var hudKey:FlxSprite;
	var banner:FlxText;
	var hint:FlxText;
	var overlay:FlxText;

	var respawn:FlxPoint;
	var gemsTotal:Int = 0;
	var gemsGot:Int = 0;
	var score:Int = 0;
	var combo:Int = 0;
	var hasKey:Bool = false;
	var time:Float = 0;
	var hitstop:Float = 0;
	var mode:Int = 0; // 0 játék, 1 pálya kész, 2 vége (halál)
	var paused:Bool = false;
	var modeT:Float = 0;
	var worldW:Int;
	var worldH:Int;

	override public function create():Void
	{
		super.create();
		Audio.init();
		Audio.playMusic();
		bgColor = 0xFF000000;
		data = LevelData.generate(level);
		worldW = data.w * LevelData.T;
		worldH = LevelData.H * LevelData.T;
		score = totalScore;

		// háttér: csillagok és két réteg távoli rom (paralaxis)
		addBackdrop(Art.stars(480 + Std.int(worldW * 0.05), 7), 0.05, 0.03, -70);
		addBackdrop(Art.backdrop(480 + Std.int(worldW * 0.18), 11 + level, "5", 30), 0.18, 0.12, -70);
		addBackdrop(Art.backdrop(480 + Std.int(worldW * 0.34), 29 + level, "6", 60), 0.34, 0.2, -60);

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

		keyItem = makePickup(data.key.x, data.key.y, Art.key(), 10, 8, "key");
		add(keyItem);

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
			FlxG.camera.shake(0.004, 0.08);
		};
		player.onTrail = spawnGhost;
		add(player);
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
		banner = label(data.name, 112, 1, 0xFFFFFFFF);
		banner.screenCenter(X);
		FlxTween.tween(banner, {alpha: 0}, 0.8, {startDelay: 1.8});
		#if test
		js.Syntax.code("window.__ps = {0}; window.__cam = {1}", this, FlxG.camera);
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
		for (i in 0...player.maxHearts)
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
		hudKey = new FlxSprite(110, 5);
		hudKey.loadGraphic(Art.key(), false, 10, 8, false, "key");
		hudKey.scrollFactor.set(0, 0);
		add(hudKey);
		hint = label("KEY NEEDED", 100, 8, 0xFFFFFFFF);
		hint.visible = false;
		overlay = label("", 96, 8, 0xFFFFFFFF);
		overlay.visible = false;
		refreshHud();
	}

	function refreshHud():Void
	{
		for (i in 0...hudHearts.length)
			hudHearts[i].loadGraphic(i < player.hearts ? Art.heart() : Art.heartEmpty(), false, 8, 8, false, i < player.hearts ? "heart" : "heartEmpty");
		hudGems.text = "GEMS " + gemsGot + "/" + gemsTotal;
		hudScore.text = "SCORE " + score;
		hudKey.alpha = hasKey ? 1 : 0.25;
	}

	// --- Effektek ---

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
		var t = new FlxText(x - 20, y, 40, txt, 8);
		t.setFormat(null, 8, 0xFFFFFFFF, CENTER);
		add(t);
		FlxTween.tween(t, {y: y - 16, alpha: 0}, 0.7, {onComplete: _ -> t.kill()});
	}

	// --- Játék ---

	override public function update(elapsed:Float):Void
	{
		if (Input.pausePressed() && mode == 0)
		{
			paused = !paused;
			if (paused)
				Audio.pauseMusic();
			else
				Audio.resumeMusic();
			overlay.text = "PAUSED\n\nESC / P: RESUME      R: RESPAWN";
			overlay.visible = paused;
		}
		if (paused)
			return;
		if (hitstop > 0)
		{
			hitstop -= elapsed;
			return;
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

		time += elapsed;
		super.update(elapsed);

		FlxG.collide(player, solidMap);
		if (player.dropT <= 0)
			FlxG.collide(player, platMap);
		FlxG.collide(grounded, solidMap);
		FlxG.collide(grounded, platMap);
		if (player.onFloor || player.isTouching(FlxDirectionFlags.FLOOR))
			combo = 0;

		FlxG.overlap(player, enemies, onEnemy);
		FlxG.overlap(player, gems, onGem);
		FlxG.overlap(player, hearts, onHeart);
		FlxG.overlap(player, spikes, onSpike);
		FlxG.overlap(player, checkpoints, onCheckpoint);
		if (keyItem.alive && FlxG.overlap(player, keyItem))
			onKey();
		var nearDoor = Math.abs((player.x + 4) - (door.x + 8)) < 14 && Math.abs((player.y + 6) - (door.y + 12)) < 18;
		hint.visible = nearDoor && !hasKey;
		hint.y = 100;
		if (nearDoor && hasKey)
			levelClear();

		if (player.y > worldH + 40)
			fall();
		if (Input.restartPressed())
			toCheckpoint(false);
		refreshHud();
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

	function onKey():Void
	{
		keyItem.kill();
		hasKey = true;
		score += 100;
		Audio.play("key", 1);
		burst(keyItem.x + 5, keyItem.y + 4, 14, 0xFFFFFFFF, 90);
		door.animation.play("open");
		FlxG.camera.flash(0xFFFFFFFF, 0.2);
		popText("DOOR OPEN", door.x + 8, door.y - 10);
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
		player.respawnAt(respawn.x, respawn.y);
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

	function levelClear():Void
	{
		mode = 1;
		modeT = 0;
		Audio.play("door", 1);
		var bonus = gemsGot == gemsTotal ? 500 : 0;
		score += bonus + Std.int(Math.max(0, 600 - time) * 2);
		player.visible = false;
		var m = Std.int(time / 60), s = Std.int(time % 60);
		var lines = "LEVEL " + (level + 1) + " CLEAR\n\n" + "GEMS " + gemsGot + "/" + gemsTotal + (bonus > 0 ? "  ALL FOUND +500" : "") + "\nTIME " + m + ":" + (s < 10 ? "0" : "") + s + "\nSCORE " + score + "\n\nPRESS JUMP";
		overlay.text = lines;
		overlay.visible = true;
		hint.visible = false;
		refreshHud();
	}

	function nextLevel():Void
	{
		totalScore = score;
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
