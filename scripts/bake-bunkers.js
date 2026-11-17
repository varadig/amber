// A BuildingRoom téglalapok falainak "beégetése" a levels/level*.tmj `solid` rétegébe, hogy a Tiled-ben is látszódjanak és kézzel szerkeszthetők legyenek.
// Minden (walls != false vagy clear != false) BuildingRoom köré 1 csempe vastag téglafal (3-as csempe) kerül, a belseje kiürül; utána a szoba
// walls = false és clear = false értéket kap, így a játék betöltéskor nem írja felül a kézi módosításaidat (nyílás a falon, belső szerkezet).
// Átméretezés után: állítsd vissza a szoba walls / clear értékét true-ra (a régi falat töröld kézzel), és futtasd újra.
// Használat: node scripts/bake-bunkers.js [levels-mappa]
const fs = require("fs");
const path = require("path");
const dir = path.resolve(process.argv[2] || path.join(__dirname, "..", "levels"));
const T = 16;
let total = 0;
for (const f of fs.readdirSync(dir).filter((n) => /^level\d+\.tmj$/.test(n))) {
  const p = path.join(dir, f);
  const m = JSON.parse(fs.readFileSync(p, "utf8").replace(/^\uFEFF/, ""));
  const solid = m.layers.find((l) => l.type === "tilelayer" && l.name === "solid");
  if (!solid || !Array.isArray(solid.data)) { console.warn(`${f}: nincs CSV 'solid' réteg, kihagyva`); continue; }
  let n = 0;
  const visit = (layers) => {
    for (const l of layers) {
      if (l.type === "group") visit(l.layers);
      if (l.type !== "objectgroup") continue;
      for (const o of l.objects) {
        const cls = o.class || o.type;
        if (cls !== "BuildingRoom") continue;
        o.properties = o.properties || [];
        const get = (k) => { const q = o.properties.find((x) => x.name === k); return q ? q.value : true; };
        const set = (k, v) => { const q = o.properties.find((x) => x.name === k); if (q) { q.value = v; q.type = "bool"; } else o.properties.push({ name: k, type: "bool", value: v }); };
        const walls = get("walls") !== false, clear = get("clear") !== false;
        if (!walls && !clear) continue;
        const x0 = Math.round(o.x / T), y0 = Math.round(o.y / T), w = Math.round(o.width / T), h = Math.round(o.height / T);
        for (let y = y0 - 1; y < y0 + h + 1; y++)
          for (let x = x0 - 1; x < x0 + w + 1; x++) {
            if (x < 0 || x >= m.width || y < 0 || y >= m.height) continue;
            const edge = y === y0 - 1 || y === y0 + h || x === x0 - 1 || x === x0 + w;
            if (edge && walls) solid.data[y * m.width + x] = 3;
            else if (!edge && clear) solid.data[y * m.width + x] = 0;
          }
        set("walls", false);
        set("clear", false);
        n++;
      }
    }
  };
  visit(m.layers);
  if (n > 0) fs.writeFileSync(p, JSON.stringify(m));
  console.log(`${f}: ${n} szoba beégetve`);
  total += n;
}
console.log(`összesen: ${total}`);
