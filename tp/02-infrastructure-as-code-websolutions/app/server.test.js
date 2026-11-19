const { once } = require('node:events');
const assert = require('node:assert/strict');
const { test } = require('node:test');
const { createApp } = require('./server');

async function health(t, checkDatabase) {
  const server = createApp({ checkDatabase, version: 'test' });
  server.listen(0, '127.0.0.1');
  t.after(() => server.close());
  await once(server, 'listening');
  return fetch(`http://127.0.0.1:${server.address().port}/health`);
}

test('returns HTTP 200 and the release when PostgreSQL responds', async (t) => {
  const response = await health(t, async () => {});
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), { status: 'ok', database: 'ok', version: 'test' });
});

test('returns HTTP 503 when PostgreSQL is unavailable', async (t) => {
  const response = await health(t, async () => { throw new Error('offline'); });
  assert.equal(response.status, 503);
  assert.deepEqual(await response.json(), { status: 'unavailable', database: 'error', version: 'test' });
});
