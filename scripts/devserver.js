// Amber fejlesztői szerver: statikus kiszolgálás a megadott mappából, 0.0.0.0-n (így telefonról is elérhető), gyorsítótár nélkül,
// + élő újratöltés a megnyitott DEV játék-példányoknak, ha új DEV build készül.
//   node scripts/devserver.js <mappa> [port]
// A scripts/play.ps1 indítja (a Node-ot a PATH-ból, vagy a lime csomagolt példányából veszi).
//
// Élő újratöltés (szándékosan szigorú, hogy következetes legyen):
//   - a böngészőben futó DEV játék (cheat-build, nem teszt) az `EventSource('/__reload?kind=dev')` végponthoz kapcsolódik (DevReload.hx);
//   - a build végén a scripts/build.ps1 (scripts/reload.ps1) `POST /__built?kind=<dev|test|release>`-t küld;
//   - a szerver CSAK az azonos fajtájú (kind) kapcsolatokat értesíti: dev build -> dev példányok újratöltenek; release / teszt build nem érinti őket.
//   GET /__clients: a csatlakozott példányok száma fajtánként (JSON).
const http = require('http');
const fs = require('fs');
const path = require('path');

const root = path.resolve(process.argv[2] || 'bin');
const port = parseInt(process.argv[3] || '3200', 10);
const types = {
  '.html': 'text/html; charset=utf-8', '.js': 'application/javascript', '.json': 'application/json', '.png': 'image/png', '.css': 'text/css',
  '.ico': 'image/x-icon', '.svg': 'image/svg+xml', '.map': 'application/json', '.wav': 'audio/wav', '.mp3': 'audio/mpeg',
};

/** Élő újratöltésre feliratkozott böngésző-példányok: {res, kind}. */
const clients = new Set();

function countByKind() {
  const r = {};
  for (const c of clients) r[c.kind] = (r[c.kind] || 0) + 1;
  return r;
}

const mockScores = [];
const server = http.createServer((req, res) => {
  const u = new URL(req.url || '/', 'http://localhost');
  const url = decodeURIComponent(u.pathname);

  // Fejlesztői mock a ranglistához (Supabase REST /rest/v1/<tábla>): memóriában tárol, újraindításkor elvész.
  // Tesztelés (cheat-build): ?lburl=http://127.0.0.1:<port>&lbkey=x  (lásd docs/LEADERBOARD.md)
  if (url.startsWith('/rest/v1/')) {
    const cors = { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': '*', 'Access-Control-Allow-Methods': 'GET,POST,OPTIONS' };
    if (req.method === 'OPTIONS') { res.writeHead(204, cors); res.end(); return; }
    if (req.method === 'POST') {
      let body = '';
      req.on('data', (ch) => { body += ch; });
      req.on('end', () => {
        try {
          const r = JSON.parse(body);
          if (typeof r.name !== 'string' || !/^[A-Z]{3}$/.test(r.name) || !(r.score >= 0)) throw new Error('bad row');
          mockScores.push({ name: r.name, score: r.score | 0, level: r.level | 0, atoms: r.atoms | 0, completed: !!r.completed });
          console.log('[ranglista] ' + r.name + ' ' + r.score + ' pálya ' + r.level + (r.completed ? ' (kész)' : ''));
          res.writeHead(201, cors); res.end();
        } catch (e) { res.writeHead(400, cors); res.end('bad request'); }
      });
      return;
    }
    const limit = parseInt(u.searchParams.get('limit') || '10', 10);
    const rows = mockScores.slice().sort((a, b) => b.score - a.score).slice(0, limit);
    res.writeHead(200, Object.assign({ 'Content-Type': 'application/json' }, cors));
    res.end(JSON.stringify(rows));
    return;
  }

  // --- élő újratöltés ---
  if (url === '/__reload') {
    const kind = u.searchParams.get('kind') || 'dev';
    res.writeHead(200, { 'Content-Type': 'text/event-stream', 'Cache-Control': 'no-store', 'Connection': 'keep-alive', 'Access-Control-Allow-Origin': '*' });
    res.write('retry: 1000\n\n');
    const c = { res, kind };
    clients.add(c);
    console.log('[reload] +1 ' + kind + ' példány (' + JSON.stringify(countByKind()) + ')');
    req.on('close', () => { clients.delete(c); console.log('[reload] -1 ' + kind + ' példány (' + JSON.stringify(countByKind()) + ')'); });
    return;
  }
  if (url === '/__built' && req.method === 'POST') {
    const kind = u.searchParams.get('kind') || 'release';
    let n = 0;
    for (const c of clients) if (c.kind === kind) { c.res.write('event: reload\ndata: ' + kind + '\n\n'); n++; }
    console.log('[reload] ' + kind + ' build kész: ' + n + ' példány újratölt (összes: ' + JSON.stringify(countByKind()) + ')');
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ kind, reloaded: n }));
    return;
  }
  if (url === '/__clients') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(countByKind()));
    return;
  }

  // --- statikus kiszolgálás ---
  const file = path.normalize(path.join(root, url === '/' ? '/index.html' : url));
  if (!file.startsWith(root)) { res.writeHead(403); res.end(); return; }
  fs.readFile(file, (err, data) => {
    if (err) { res.writeHead(404); res.end('not found'); console.log('404 ' + url); return; }
    res.writeHead(200, {
      'Content-Type': types[path.extname(file).toLowerCase()] || 'application/octet-stream',
      'Cache-Control': 'no-store',
    });
    res.end(data);
  });
});

// a proxyk / böngészők ne zárják le a csendes kapcsolatot
setInterval(() => { for (const c of clients) c.res.write(': ping\n\n'); }, 20000);

server.on('error', (e) => {
  console.error('A szerver nem indult el (' + e.code + '): ' + e.message);
  process.exit(1);
});
server.listen(port, '0.0.0.0', () => console.log('Kiszolgálás: http://0.0.0.0:' + port + '/  (mappa: ' + root + ')'));
