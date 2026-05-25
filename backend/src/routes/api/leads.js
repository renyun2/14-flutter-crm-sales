const express = require('express');
const { v4: uuid } = require('uuid');
const db = require('../../db');
const { authRequired } = require('../../middleware/auth');
const { ownerFilter, assertOwner } = require('../../utils/permissions');

const router = express.Router();
router.use(authRequired);

function mapLead(row) {
  const overdue =
    !row.last_follow_at &&
    (Date.now() - new Date(row.created_at).getTime()) / 86400000 > 7;
  const staleFollow =
    row.last_follow_at &&
    (Date.now() - new Date(row.last_follow_at).getTime()) / 86400000 > 7;
  return { ...row, overdue: overdue || staleFollow };
}

router.get('/', (req, res) => {
  const { clause, params } = ownerFilter(req.user);
  const { status, source, overdue } = req.query;
  let sql = `SELECT * FROM leads WHERE ${clause}`;
  const args = [...params];
  if (status) {
    sql += ' AND status = ?';
    args.push(status);
  }
  if (source) {
    sql += ' AND source = ?';
    args.push(source);
  }
  sql += ' ORDER BY created_at DESC';
  let rows = db.prepare(sql).all(...args).map(mapLead);
  if (overdue === '1') rows = rows.filter((r) => r.overdue);
  res.json({ items: rows });
});

router.get('/:id', (req, res) => {
  const lead = db.prepare('SELECT * FROM leads WHERE id = ?').get(req.params.id);
  if (!lead) return res.status(404).json({ error: '线索不存在', code: 404 });
  if (!assertOwner(req.user, lead.owner_id)) return res.status(403).json({ error: '无权限', code: 403 });
  const followUps = db
    .prepare('SELECT f.*, u.name AS user_name FROM lead_follow_ups f JOIN users u ON u.id = f.user_id WHERE lead_id = ? ORDER BY created_at DESC')
    .all(lead.id);
  res.json({ ...mapLead(lead), followUps });
});

router.post('/', (req, res) => {
  const { title, company, source, status } = req.body || {};
  if (!title || !company) return res.status(400).json({ error: '标题和公司必填', code: 400 });
  const id = uuid();
  db.prepare(
    'INSERT INTO leads (id, title, company, source, status, owner_id) VALUES (?,?,?,?,?,?)'
  ).run(id, title, company, source || '官网', status || 'new', req.user.id);
  res.status(201).json(mapLead(db.prepare('SELECT * FROM leads WHERE id = ?').get(id)));
});

router.put('/:id', (req, res) => {
  const lead = db.prepare('SELECT * FROM leads WHERE id = ?').get(req.params.id);
  if (!lead) return res.status(404).json({ error: '线索不存在', code: 404 });
  if (!assertOwner(req.user, lead.owner_id)) return res.status(403).json({ error: '无权限', code: 403 });
  const { title, company, source, status } = req.body || {};
  db.prepare(
    'UPDATE leads SET title = COALESCE(?, title), company = COALESCE(?, company), source = COALESCE(?, source), status = COALESCE(?, status) WHERE id = ?'
  ).run(title, company, source, status, lead.id);
  res.json(mapLead(db.prepare('SELECT * FROM leads WHERE id = ?').get(lead.id)));
});

router.post('/:id/assign', (req, res) => {
  if (req.user.role === 'sales') return res.status(403).json({ error: '无权限', code: 403 });
  const { ownerId } = req.body || {};
  const lead = db.prepare('SELECT * FROM leads WHERE id = ?').get(req.params.id);
  if (!lead) return res.status(404).json({ error: '线索不存在', code: 404 });
  db.prepare('UPDATE leads SET owner_id = ? WHERE id = ?').run(ownerId || req.user.id, lead.id);
  res.json(mapLead(db.prepare('SELECT * FROM leads WHERE id = ?').get(lead.id)));
});

router.post('/:id/follow-ups', (req, res) => {
  const lead = db.prepare('SELECT * FROM leads WHERE id = ?').get(req.params.id);
  if (!lead) return res.status(404).json({ error: '线索不存在', code: 404 });
  if (!assertOwner(req.user, lead.owner_id)) return res.status(403).json({ error: '无权限', code: 403 });
  const { content } = req.body || {};
  if (!content) return res.status(400).json({ error: '跟进内容必填', code: 400 });
  const id = uuid();
  const now = new Date().toISOString();
  db.prepare('INSERT INTO lead_follow_ups (id, lead_id, user_id, content, created_at) VALUES (?,?,?,?,?)').run(
    id,
    lead.id,
    req.user.id,
    content,
    now
  );
  db.prepare('UPDATE leads SET last_follow_at = ? WHERE id = ?').run(now, lead.id);
  res.status(201).json(db.prepare('SELECT * FROM lead_follow_ups WHERE id = ?').get(id));
});

router.post('/:id/convert', (req, res) => {
  const lead = db.prepare('SELECT * FROM leads WHERE id = ?').get(req.params.id);
  if (!lead) return res.status(404).json({ error: '线索不存在', code: 404 });
  if (!assertOwner(req.user, lead.owner_id)) return res.status(403).json({ error: '无权限', code: 403 });
  const customerId = uuid();
  db.prepare(
    'INSERT INTO customers (id, name, industry, address, owner_id) VALUES (?,?,?,?,?)'
  ).run(customerId, lead.company, '', '', lead.owner_id);
  const oppId = uuid();
  db.prepare(
    'INSERT INTO opportunities (id, title, customer_id, owner_id, stage, amount, weighted_amount) VALUES (?,?,?,?,?,?,?)'
  ).run(oppId, lead.title, customerId, lead.owner_id, 'initial', 0, 0);
  db.prepare('UPDATE leads SET status = ?, customer_id = ? WHERE id = ?').run('converted', customerId, lead.id);
  res.json({ customerId, opportunityId: oppId, lead: mapLead(db.prepare('SELECT * FROM leads WHERE id = ?').get(lead.id)) });
});

module.exports = router;
