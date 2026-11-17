// A BuildingRoom téglalapok falainak "beégetése" a levels/level*.tmj `solid` rétegébe, hogy a Tiled-ben is látszódjanak.
// Szinkronizál: a térkép `bakedRooms` tulajdonsága tárolja, mit égetett be korábban. Minden futás elején a régi szobák (fal + belső tér)
// visszaállnak tömör talajra (2-es csempe), aztán a jelenlegi szobák köré újra felkerül a téglafal (3) és a belső tér kiürül.
// Így törölt szoba fala eltűnik, átméretezett szobáé az új méretre épül. A szoba walls / clear értéke változatlan (true): a játék betöltéskor
// ugyanezt építi, tehát a kettő konzisztens.
// Kézi szerkesztés (pl. nyílás a falon): állítsd a szoba walls és clear értékét false-ra, ezt a script nem bántja (és nem is törli, ha már nem szerepel a listában).
// Figyelem: a bake a szoba keretét és belsejét felülírja, ezért kézi módosítást csak walls=false szobánál tarts.
// Használat: node scripts/bake-bunkers.js [levels-mappa]
const fs = require("fs");
const path = require("path");
const dir = path.resolve(process.argv[2] || path.join(__dirname, "..", "levels"));
const T = 16;
let total = 0;
for (const f of fs.readdirSync(dir).filter((n) => /^level\d+\.tmj$/.test(n))) {
  const p = path.join(dir, f);
  const m = JSON.parse(fs.readFileSync(p, "utf8").replace(/^﻿/, ""));
  const solid = m.layers.find((l) => l.type === "tilelayer" && l.name === "solid");
  if (!solid || !Array.isArray(solid.data)) { console.warn(`${f}: nincs CSV 'solid' réteg, kihagyva`); continue; }
  m.properties = m.properties || [];
  const prop = m.properties.find((q) => q.name === "bakedRooms");
  const fill = (x0, y0, w, h, ring, inner) => {
    for (let y = y0 - 1; y < y0 + h + 1; y++)
      for (let x = x0 - 1; x < x0 + w + 1; x++) {
        if (x < 0 || x >= m.width || y < 0 || y >= m.height) continue;
        const edge = y === y0 - 1 || y === y0 + h || x === x0 - 1 || x === x0 + w;
        const v = edge ? ring : inner;
        if (v !== null) solid.data[y * m.width + x] = v;
      }
  };
  // 1) a korábban beégetett szobák visszaállítása tömör talajra
  let restored = 0;
  if (prop && prop.value) for (const s of String(prop.value).split(";")) {
    const a = s.split(",").map(Number);
    if (a.length === 4 && a.every((v) => !isNaN(v))) { fill(a[0], a[1], a[2], a[3], 2, 2); restored++; }
  }
  // 2) a jelenlegi szobák beégetése
  const baked = [];
  const visit = (layers) => {
    for (const l of layers) {
      if (l.type === "group") visit(l.layers);
      if (l.type !== "objectgroup") continue;
      for (const o of l.objects) {
        if ((o.class || o.type) !== "BuildingRoom") continue;
        const get = (k) => { const q = (o.properties || []).find((x) => x.name === k); return q ? q.value : true; };
        const walls = get("walls") !== false, clear = get("clear") !== false;
        if (!walls || !clear) continue; // kézi szoba: nem bántjuk
        const x0 = Math.round(o.x / T), y0 = Math.round(o.y / T), w = Math.round(o.width / T), h = Math.round(o.height / T);
        baked.push([x0, y0, w, h]);
      }
    }
  };
  visit(m.layers);
  for (const r of baked) fill(r[0], r[1], r[2], r[3], 3, 0);
  const val = baked.map((r) => r.join(",")).join(";");
  if (prop) prop.value = val; else m.properties.push({ name: "bakedRooms", type: "string", value: val });
  fs.writeFileSync(p, JSON.stringify(m));
  console.log(`${f}: ${baked.length} szoba beégetve (${restored} régi visszaállítva)`);
  total += baked.length;
}
console.log(`összesen: ${total}`);
