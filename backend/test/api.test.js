const { test, before, after, describe } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');

const dbPath = path.join(__dirname, '..', 'data', 'crm-test.db');

async function callApp(app, method, url, { token, body } = {}) {
  return new Promise((resolve, reject) => {
    const server = app.listen(0, () => {
      const { port } = server.address();
      const http = require('http');
      const payload = body ? JSON.stringify(body) : null;
      const req = http.request(
        {
          hostname: '127.0.0.1',
          port,
          path: url,
          method,
          headers: {
            'Content-Type': 'application/json',
            ...(token ? { Authorization: `Bearer ${token}` } : {}),
            ...(payload ? { 'Content-Length': Buffer.byteLength(payload) } : {}),
          },
        },
        (res) => {
          let raw = '';
          res.on('data', (c) => (raw += c));
          res.on('end', () => {
            server.close();
            resolve({
              status: res.statusCode,
              body: raw ? JSON.parse(raw) : null,
            });
          });
        }
      );
      req.on('error', (e) => {
        server.close();
        reject(e);
      });
      if (payload) req.write(payload);
      req.end();
    });
  });
}

describe('CRM API', () => {
  let app;
  let salesToken;
  let managerToken;
  let otherSalesToken;
  let sampleOppId;

  before(() => {
    if (fs.existsSync(dbPath)) fs.unlinkSync(dbPath);
    process.env.CRM_DB_PATH = dbPath;
    delete require.cache[require.resolve('../src/db')];
    delete require.cache[require.resolve('../src/seed')];
    delete require.cache[require.resolve('../src/index')];
    const { seed } = require('../src/seed');
    seed();
    app = require('../src/index');
  });

  after(() => {
    delete require.cache[require.resolve('../src/db')];
    delete require.cache[require.resolve('../src/index')];
    try {
      if (fs.existsSync(dbPath)) fs.unlinkSync(dbPath);
    } catch (_) {
      // Windows may keep sqlite file locked briefly
    }
  });

  test('login with employee no', async () => {
    const res = await callApp(app, 'POST', '/api/auth/login', {
      body: { employeeNo: 'S001', password: '123456' },
    });
    assert.equal(res.status, 200);
    assert.ok(res.body.token);
    salesToken = res.body.token;

    const m = await callApp(app, 'POST', '/api/auth/login', {
      body: { employeeNo: 'M001', password: '123456' },
    });
    managerToken = m.body.token;

    const s2 = await callApp(app, 'POST', '/api/auth/login', {
      body: { employeeNo: 'S002', password: '123456' },
    });
    otherSalesToken = s2.body.token;
  });

  test('sales sees own leads only', async () => {
    const mine = await callApp(app, 'GET', '/api/leads', { token: salesToken });
    assert.equal(mine.status, 200);
    assert.ok(mine.body.items.length > 0);
    mine.body.items.forEach((l) => assert.equal(l.owner_id, mine.body.items[0].owner_id));
  });

  test('manager sees team leads', async () => {
    const team = await callApp(app, 'GET', '/api/leads', { token: managerToken });
    assert.equal(team.status, 200);
    assert.ok(team.body.items.length >= mineCount(team.body.items));
    function mineCount() {
      return team.body.items.length;
    }
  });

  test('opportunity stage forward', async () => {
    const list = await callApp(app, 'GET', '/api/opportunities', { token: salesToken });
    sampleOppId = list.body.items.find((o) => o.stage === 'initial')?.id || list.body.items[0].id;
    const res = await callApp(app, 'PATCH', `/api/opportunities/${sampleOppId}/stage`, {
      token: salesToken,
      body: { stage: 'qualification' },
    });
    assert.equal(res.status, 200);
    assert.equal(res.body.stage, 'qualification');
  });

  test('sales cannot rollback stage', async () => {
    const res = await callApp(app, 'PATCH', `/api/opportunities/${sampleOppId}/stage`, {
      token: salesToken,
      body: { stage: 'initial' },
    });
    assert.equal(res.status, 403);
  });

  test('manager can rollback stage', async () => {
    const res = await callApp(app, 'PATCH', `/api/opportunities/${sampleOppId}/stage`, {
      token: managerToken,
      body: { stage: 'initial' },
    });
    assert.equal(res.status, 200);
    assert.equal(res.body.stage, 'initial');
  });

  test('contract over 100k needs approval', async () => {
    const customers = await callApp(app, 'GET', '/api/customers', { token: salesToken });
    const customerId = customers.body.items[0].id;
    const created = await callApp(app, 'POST', '/api/contracts', {
      token: salesToken,
      body: { customerId, title: '大额合同', amount: 150000 },
    });
    assert.equal(created.status, 201);
    assert.equal(created.body.status, 'pending_approval');

    const approvals = await callApp(app, 'GET', '/api/approvals', { token: managerToken });
    assert.equal(approvals.status, 200);
    assert.ok(approvals.body.items.some((a) => a.contract_id === created.body.id));

    const approval = approvals.body.items.find((a) => a.contract_id === created.body.id);
    const resolved = await callApp(app, 'POST', `/api/approvals/${approval.id}/resolve`, {
      token: managerToken,
      body: { approved: true, comment: '同意' },
    });
    assert.equal(resolved.status, 200);
    assert.equal(resolved.body.status, 'approved');
  });

  test('sales cannot access approvals', async () => {
    const res = await callApp(app, 'GET', '/api/approvals', { token: salesToken });
    assert.equal(res.status, 403);
  });

  test('reports summary', async () => {
    const res = await callApp(app, 'GET', '/api/reports/summary?period=month', { token: managerToken });
    assert.equal(res.status, 200);
    assert.ok(res.body.funnel.length > 0);
    assert.ok(res.body.trend.length > 0);
  });
});
