const express = require('express');
const { v4: uuid } = require('uuid');
const db = require('../../db');
const { authRequired } = require('../../middleware/auth');
const { ownerFilter, assertOwner } = require('../../utils/permissions');

const router = express.Router();
router.use(authRequired);

function mapVisit(row) {
  return { ...row, photoUrls: JSON.parse(row.photo_urls_json || '[]') };
}

router.get('/', (req, res) => {
  const { clause, params } = ownerFilter(req.user);
  const rows = db
    .prepare(
      `SELECT v.*, c.name AS customer_name FROM visits v JOIN customers c ON c.id = v.customer_id WHERE ${clause.replace('owner_id', 'v.owner_id')} ORDER BY v.planned_at ASC`
    )
    .all(...params)
    .map(mapVisit);
  res.json({ items: rows });
});

router.get('/:id', (req, res) => {
  const visit = db
    .prepare('SELECT v.*, c.name AS customer_name FROM visits v JOIN customers c ON c.id = v.customer_id WHERE v.id = ?')
    .get(req.params.id);
  if (!visit) return res.status(404).json({ error: '拜访不存在', code: 404 });
  if (!assertOwner(req.user, visit.owner_id)) return res.status(403).json({ error: '无权限', code: 403 });
  res.json(mapVisit(visit));
});

router.post('/', (req, res) => {
  const { customerId, title, plannedAt, address } = req.body || {};
  if (!customerId || !title || !plannedAt) {
    return res.status(400).json({ error: '客户、标题、计划时间必填', code: 400 });
  }
  const customer = db.prepare('SELECT * FROM customers WHERE id = ?').get(customerId);
  if (!customer) return res.status(404).json({ error: '客户不存在', code: 404 });
  const id = uuid();
  db.prepare(
    'INSERT INTO visits (id, customer_id, owner_id, title, planned_at, address) VALUES (?,?,?,?,?,?)'
  ).run(id, customerId, req.user.id, title, plannedAt, address || customer.address || '');
  res.status(201).json(mapVisit(db.prepare('SELECT * FROM visits WHERE id = ?').get(id)));
});

router.post('/:id/check-in', (req, res) => {
  const visit = db.prepare('SELECT * FROM visits WHERE id = ?').get(req.params.id);
  if (!visit) return res.status(404).json({ error: '拜访不存在', code: 404 });
  if (!assertOwner(req.user, visit.owner_id)) return res.status(403).json({ error: '无权限', code: 403 });
  const { address } = req.body || {};
  const now = new Date().toISOString();
  db.prepare('UPDATE visits SET status = ?, check_in_at = ?, address = COALESCE(?, address) WHERE id = ?').run(
    'in_progress',
    now,
    address,
    visit.id
  );
  res.json(mapVisit(db.prepare('SELECT * FROM visits WHERE id = ?').get(visit.id)));
});

router.patch('/:id', (req, res) => {
  const visit = db.prepare('SELECT * FROM visits WHERE id = ?').get(req.params.id);
  if (!visit) return res.status(404).json({ error: '拜访不存在', code: 404 });
  if (!assertOwner(req.user, visit.owner_id)) return res.status(403).json({ error: '无权限', code: 403 });
  const { status, summary, photoUrls } = req.body || {};
  db.prepare(
    'UPDATE visits SET status = COALESCE(?, status), summary = COALESCE(?, summary), photo_urls_json = COALESCE(?, photo_urls_json) WHERE id = ?'
  ).run(status, summary, photoUrls ? JSON.stringify(photoUrls) : null, visit.id);
  if (status === 'completed' && !visit.check_in_at) {
    db.prepare('UPDATE visits SET check_in_at = datetime(\'now\') WHERE id = ?').run(visit.id);
  }
  res.json(mapVisit(db.prepare('SELECT * FROM visits WHERE id = ?').get(visit.id)));
});

module.exports = router;
