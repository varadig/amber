// A játék ikonja (a HaxeFlixel alapikonja helyett): AMBER, a hős, a játék borostyán színeiben, CRT-pásztázó csíkokkal.
// Kimenet: assets/icon/icon-<méret>.png (16 ... 1024); a Project.xml <icon> sorai ezekből készítik a favicont, a Windows .ico-t és a macOS .icns-t.
// Futtatás: node scripts/make-icon.js   (külső csomag nem kell: a PNG-t a beépített zlib-bel írja)
// A pixel-art az Art.hx BODY + álló láb mintája (minden alkatrésszel: világító szem és mag), pixelre pontos (nem elmosott) nagyítással.
const fs = require("fs");
const path = require("path");
const zlib = require("zlib");

// A hős 12x14 (Art.BODY + "stand" láb), '.' átlátszó, '0'..'4' a szürke-lépcsők
const HERO = [
	".....44.....",
	"..33333333..",
	"..34422443..",
	"..34022043..",
	"..32222223..",
	"..33333333..",
	".2233333322.",
	".2232442322.",
	".2232332322.",
	"..22222222..",
	"...22..22...",
	"...32..23...",
	"...22..22...",
	"..333..333..",
];
// A borostyán-shader rámpája (a szürke-lépcsők színe a játékban)
const PAL = { "0": [18, 8, 0], "1": [90, 48, 0], "2": [163, 92, 0], "3": [224, 138, 0], "4": [255, 213, 106] };
const BG_IN = [34, 17, 3], BG_OUT = [10, 5, 0], RIM = [255, 176, 0];

/** Logikai rács (g x g): a hős `s`-szeresen, középre; háttér: lekerekített négyzet sötét belsővel és borostyán kerettel. */
function design(g, s) {
	const px = [];
	const r = Math.round(g * 0.19); // a sarok sugara
	const inside = (x, y, inset) => {
		const lo = inset, hi = g - 1 - inset, rr = r - inset;
		const cx = x < lo + rr ? lo + rr : x > hi - rr ? hi - rr : x;
		const cy = y < lo + rr ? lo + rr : y > hi - rr ? hi - rr : y;
		return x >= lo && x <= hi && y >= lo && y <= hi && (x - cx) ** 2 + (y - cy) ** 2 <= rr * rr + rr * 0.6;
	};
	const ox = Math.floor((g - 12 * s) / 2), oy = Math.floor((g - 14 * s) / 2) + (s > 1 ? 1 : 0);
	for (let y = 0; y < g; y++) {
		const row = [];
		for (let x = 0; x < g; x++) {
			let c = null;
			if (inside(x, y, 0)) {
				// belül: középről kifelé sötétedő háttér, a szélén borostyán keret
				const d = Math.hypot(x + 0.5 - g / 2, y + 0.5 - g / 2) / (g * 0.7);
				c = BG_IN.map((v, i) => Math.round(v + (BG_OUT[i] - v) * Math.min(1, d)));
				const rim = Math.max(1, Math.round(g / 16)); // a keret vastagsága a rácshoz arányos
				if (!inside(x, y, rim)) c = RIM;
				else if (g >= 32 && !inside(x, y, rim + 1)) c = [120, 64, 0];
			}
			const hx = Math.floor((x - ox) / s), hy = Math.floor((y - oy) / s);
			if (c && hx >= 0 && hx < 12 && hy >= 0 && hy < 14 && x >= ox && y >= oy) {
				const ch = HERO[hy][hx];
				if (ch !== ".") c = PAL[ch];
			}
			row.push(c);
		}
		px.push(row);
	}
	// halvány fény a hős mögött (a szem / mag ragyogása)
	return px;
}

/** A logikai rács nagyítása N px-re (egész szorzó), pásztázó-csíkokkal a nagy méreteken; RGBA puffer. */
function render(px, n) {
	const g = px.length, k = n / g;
	const buf = Buffer.alloc(n * n * 4);
	for (let y = 0; y < n; y++)
		for (let x = 0; x < n; x++) {
			const c = px[Math.floor(y / k)][Math.floor(x / k)];
			const o = (y * n + x) * 4;
			if (!c) continue;
			// CRT-hatás: minden logikai pixel alsó negyede kissé sötétebb (csak ahol egy logikai pixel legalább 4 px)
			const scan = k >= 4 && (y % k) >= k * 0.75 ? 0.72 : 1;
			buf[o] = Math.round(c[0] * scan);
			buf[o + 1] = Math.round(c[1] * scan);
			buf[o + 2] = Math.round(c[2] * scan);
			buf[o + 3] = 255;
		}
	return buf;
}

function crc32(b) {
	let c, crc = 0xffffffff;
	for (let i = 0; i < b.length; i++) {
		c = (crc ^ b[i]) & 0xff;
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
function png(rgba, n) {
	const raw = Buffer.alloc((n * 4 + 1) * n);
	for (let y = 0; y < n; y++) { raw[y * (n * 4 + 1)] = 0; rgba.copy(raw, y * (n * 4 + 1) + 1, y * n * 4, (y + 1) * n * 4); }
	const ihdr = Buffer.alloc(13);
	ihdr.writeUInt32BE(n, 0); ihdr.writeUInt32BE(n, 4); ihdr[8] = 8; ihdr[9] = 6; ihdr[10] = 0; ihdr[11] = 0; ihdr[12] = 0;
	return Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]), chunk("IHDR", ihdr), chunk("IDAT", zlib.deflateSync(raw, { level: 9 })), chunk("IEND", Buffer.alloc(0))]);
}

const out = path.join(__dirname, "..", "assets", "icon");
fs.mkdirSync(out, { recursive: true });
const small = design(16, 1); // 16 / 48: a hős 1x a 16-os rácson
const mid = design(32, 2); // 32 / 96: a hős 2x a 32-es rácson
const big = design(64, 3); // 64 ... 1024: a hős 3x a 64-es rácson (körülötte több hely)
for (const [n, d] of [[16, small], [24, design(24, 1)], [32, mid], [48, small], [64, big], [96, mid], [128, big], [192, big], [256, big], [512, big], [1024, big]]) {
	fs.writeFileSync(path.join(out, `icon-${n}.png`), png(render(d, n), n));
}
console.log("Kész: " + out);
