const { createServer } = require('node:http');
const { execFile } = require('node:child_process');
const { promisify } = require('node:util');

const exec = promisify(execFile);

function createApp({ checkDatabase, version }) {
  return createServer(async (request, response) => {
    response.setHeader('Content-Type', 'application/json; charset=utf-8');
    if (request.method !== 'GET' || request.url !== '/health') {
      response.writeHead(404).end(JSON.stringify({ error: 'Route introuvable' }));
      return;
    }

    try {
      await checkDatabase();
      response.writeHead(200).end(JSON.stringify({ status: 'ok', database: 'ok', version }));
    } catch {
      response.writeHead(503).end(JSON.stringify({ status: 'unavailable', database: 'error', version }));
    }
  });
}

if (require.main === module) {
  createApp({
    checkDatabase: () => exec('psql', ['-XAtw', '-c', 'SELECT 1'], { timeout: 2000 }),
    version: process.env.APP_VERSION || 'dev',
  }).listen(3000, '0.0.0.0');
}

module.exports = { createApp };
