// Lámpák hozzáadása a Tiled-pályákhoz: minden olyan BuildingRoom-ba, amiben még nincs Lamp objektum, a mennyezet alá lámpák kerülnek (a régi, falpapírra festett lámpák helyén).
// Idempotens, a többi objektumot nem bántja. Ezen kívül (újra)létrehozza a levels/sprites/lamp.png-t és felveszi a lámpát az objects.tsj-be, ha még nincs benne.
// A lámpa a Tiled-ben bárhová tehető (Insert Tile az objects készletből, osztály: Lamp; tulajdonságok: radius, color, intensity, flicker).
// Használat: node scripts/add-lamps.js [levels-mappa]
const fs = require("fs");
const path = require("path");
const zlib = require("zlib");
const dir = path.resolve(process.argv[2] || path.join(__dirname, "..", "levels"));
const T = 16;
const LAMP_IDX = 40; // a LevelFormat.SPRITES lista sorszáma (a lista végén)

// --- lamp.png (borostyán árnyalat, mint a többi sprite) ---
const ART = ["...22...", "...22...", "..2222..", ".233332.", "23344332", ".234432.", "..3443..", "...44..."];
const LEVEL = { "1": 0x44, "2": 0x77, "3": 0xbb, "4": 0xff };
function crc32(buf) {
  let c, crc = 0xffffffff;
  for (let n = 0; n < buf.length; n++) {
    c = (crc ^ buf[n]) & 0xff;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    crc = (crc >>> 8) ^ c;
  }
  return (crc ^ 0xffffffff) >>> 0;
}
function chunk(type, data) {
  const len = Buffer.alloc(4); len.writeUInt32BE(data.length);
  const td = Buffer.concat([Buffer.from(type), data]);
  const crc = Buffer.alloc(4); crc.writeUInt32BE(crc32(td));
  return Buffer.concat([len, td, crc]);
}
function lampPng() {
  const w = 8, h = 8, raw = [];
  for (let y = 0; y < h; y++) {
    raw.push(0);
    for (let x = 0; x < w; x++) {
      const l = LEVEL[ART[y][x]];
      if (l === undefined) raw.push(0, 0, 0, 0);
      else raw.push(Math.min(255, Math.round(l * 1.1)), Math.round(l * 0.66), Math.round(l * 0.1), 255);
    }
  }
  const ihdr = Buffer.alloc(13); ihdr.writeUInt32BE(w, 0); ihdr.writeUInt32BE(h, 4); ihdr[8] = 8; ihdr[9] = 6;
  return Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]), chunk("IHDR", ihdr), chunk("IDAT", zlib.deflateSync(Buffer.from(raw))), chunk("IEND", Buffer.alloc(0))]);
}
fs.mkdirSync(path.join(dir, "sprites"), { recursive: true });
fs.writeFileSync(path.join(dir, "sprites", "lamp.png"), lampPng());

// --- objects.tsj ---
const tsjPath = path.join(dir, "objects.tsj");
const tsj = JSON.parse(fs.readFileSync(tsjPath, "utf8").replace(/^﻿/, ""));
// A lámpa tulajdonságai: radius (a nyaláb hatótávja px), intensity, flicker, angle (fok, 90 = lefelé), spread (a kúp nyílásszöge fok)
const LAMP_PROPS = () => [
  { name: "angle", type: "float", value: 90 }, { name: "flicker", type: "bool", value: true },
  { name: "intensity", type: "float", value: 1 }, { name: "radius", type: "int", value: 110 }, { name: "spread", type: "float", value: 50 }
];
let lt = tsj.tiles.find((t) => t.class === "Lamp");
if (!lt) {
  lt = { id: LAMP_IDX, image: "sprites/lamp.png", imagewidth: 8, imageheight: 8, class: "Lamp" };
  tsj.tiles.push(lt);
  tsj.tilecount = tsj.tiles.length;
}
lt.properties = LAMP_PROPS();
fs.writeFileSync(tsjPath, JSON.stringify(tsj, null, "	"));
console.log("objects.tsj: Lamp frissítve");

// --- pályák ---
let total = 0;
for (const f of fs.readdirSync(dir).filter((n) => /^level\d+\.tmj$/.test(n))) {
  const p = path.join(dir, f);
  const m = JSON.parse(fs.readFileSync(p, "utf8").replace(/^﻿/, ""));
  const ts = m.tilesets.find((t) => String(t.source || "").indexOf("objects") >= 0);
  const gid = (ts ? ts.firstgid : 5) + LAMP_IDX;
  const objs = [];
  const visit = (ls) => { for (const l of ls) { if (l.type === "group") visit(l.layers); if (l.type === "objectgroup") objs.push(l); } };
  visit(m.layers);
  const items = objs.find((l) => l.name === "items") || objs[0];
  const lamps = [];
  const rooms = [];
  for (const l of objs) for (const o of l.objects) {
    const cls = o.class || o.type;
    if (cls === "Lamp" || (o.properties || []).some((q) => q.name === "radius")) lamps.push(o);
    if (cls === "BuildingRoom") rooms.push(o);
  }
  // régi lámpák átállítása az új tulajdonságokra (nyaláb): a color kikerül, az angle / spread bekerül, a régi 76-os sugár 110 lesz
  for (const o of lamps) {
    o.properties = (o.properties || []).filter((q) => q.name !== "color");
    const has = (n) => o.properties.some((q) => q.name === n);
    if (!has("angle")) o.properties.push({ name: "angle", type: "float", value: 90 });
    if (!has("spread")) o.properties.push({ name: "spread", type: "float", value: 50 });
    const rq = o.properties.find((q) => q.name === "radius");
    if (rq && rq.value === 76) rq.value = 110;
  }
  if (lamps.length) fs.writeFileSync(p, JSON.stringify(m));
  let added = 0;
  for (const r of rooms) {
    if (lamps.some((o) => o.x >= r.x && o.x <= r.x + r.width && o.y >= r.y && o.y <= r.y + r.height + 8)) continue;
    // ugyanott, ahol korábban a falpapírra festett lámpák voltak (40 px-től 90 px-enként)
    for (let lx = 40; lx < r.width - 20; lx += 90) {
      const cx = r.x + lx + 1, cy = r.y + 8; // lámpa közepe
      items.objects.push({
        id: m.nextobjectid++, name: "", class: "Lamp", x: cx - 4, y: cy + 4, width: 8, height: 8, gid, rotation: 0, visible: true,
        properties: LAMP_PROPS()
      });
      added++;
    }
  }
  if (added) fs.writeFileSync(p, JSON.stringify(m));
  console.log(`${f}: ${added} lámpa hozzáadva (${rooms.length} terem)`);
  total += added;
}
console.log(`összesen: ${total}`);
