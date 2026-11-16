// Cadence fejlesztői szerver: statikus kiszolgálás a megadott mappából, 0.0.0.0-n (így telefonról is elérhető), gyorsítótár nélkül.
//   node scripts/devserver.js <mappa> [port]
// A scripts/play.ps1 indítja (a Node-ot a PATH-ból, vagy a lime csomagolt példányából veszi).
const http = require('http');
const fs = require('fs');
const path = require('path');

const root = path.resolve(process.argv[2] || 'bin');
const port = parseInt(process.argv[3] || '3200', 10);
const types = {
  '.html': 'text/html; charset=utf-8', '.js': 'application/javascript', '.json': 'application/json', '.png': 'image/png', '.css': 'text/css',
  '.ico': 'image/x-icon', '.svg': 'image/svg+xml', '.map': 'application/json', '.wav': 'audio/wav', '.mp3': 'audio/mpeg',
};

const server = http.createServer((req, res) => {
  const url = decodeURIComponent((req.url || '/').split('?')[0]);
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

server.on('error', (e) => {
  console.error('A szerver nem indult el (' + e.code + '): ' + e.message);
  process.exit(1);
});
server.listen(port, '0.0.0.0', () => console.log('Kiszolgálás: http://0.0.0.0:' + port + '/  (mappa: ' + root + ')'));
