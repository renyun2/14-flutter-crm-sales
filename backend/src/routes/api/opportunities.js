const express = require('express');
const { v4: uuid } = require('uuid');
const db = require('../../db');
const { authRequired } = require('../../middleware/auth');
const { ownerFilter, assertOwner } = require('../../utils/permissions');
const { STAGES, STAGE_LABELS, canMoveStage, weightedAmount } = require('../../utils/stages');

const router = express.Router();
router.use(authRequired);

function mapOpp(row) {
  return { ...row, stageLabel: STAGE_LABELS[row.stage] || row.stage };
}

router.get('/', (req, res) => {
  const { clause, params } = ownerFilter(req.user);
  const rows = db.prepare(`SELECT o.*, c.name AS customer_name FROM opportunities o JOIN customers c ON c.id = o.customer_id WHERE ${clause.replace('owner_id', 'o.owner_id')} ORDER BY o.updated_at DESC`).all(...params).map(mapOpp);
  const byStage = {};
  STAGES.forEach((s) => {
    byStage[s] = rows.filter((r) => r.stage === s);
  });
  res.json({ items: rows, byStage, stages: STAGES.map((s) => ({ key: s, label: STAGE_LABELS[s] })) });
});

router.get('/:id', (req, res) => {
  const opp = db
    .prepare('SELECT o.*, c.name AS customer_name FROM opportunities o JOIN customers c ON c.id = o.customer_id WHERE o.id = ?')
    .get(req.params.id);
  if (!opp) return res.status(404).json({ error: '商机不存在', code: 404 });
  if (!assertOwner(req.user, opp.owner_id)) return res.status(403).json({ error: '无权限', code: 403 });
  const quotes = db.prepare('SELECT * FROM quotes WHERE opportunity_id = ? ORDER BY created_at DESC').all(opp.id);
  res.json({ ...mapOpp(opp), quotes });
});

router.post('/', (req, res) => {
  const { title, customerId, amount, stage, expectedClose } = req.body || {};
  if (!title || !customerId) return res.status(400).json({ error: '标题和客户必填', code: 400 });
  const id = uuid();
  const s = stage || 'initial';
  const amt = Number(amount) || 0;
  db.prepare(
    'INSERT INTO opportunities (id, title, customer_id, owner_id, stage, amount, weighted_amount, expected_close) VALUES (?,?,?,?,?,?,?,?)'
  ).run(id, title, customerId, req.user.id, s, amt, weightedAmount(amt, s), expectedClose || null);
  res.status(201).json(mapOpp(db.prepare('SELECT * FROM opportunities WHERE id = ?').get(id)));
});

router.patch('/:id/stage', (req, res) => {
  const opp = db.prepare('SELECT * FROM opportunities WHERE id = ?').get(req.params.id);
  if (!opp) return res.status(404).json({ error: '商机不存在', code: 404 });
  if (!assertOwner(req.user, opp.owner_id)) return res.status(403).json({ error: '无权限', code: 403 });
  const { stage } = req.body || {};
  if (!stage) return res.status(400).json({ error: '阶段必填', code: 400 });
  if (!canMoveStage(opp.stage, stage, req.user.role)) {
    return res.status(403).json({ error: '不可回退阶段，需经理权限', code: 403 });
  }
  const now = new Date().toISOString();
  db.prepare(
    'UPDATE opportunities SET stage = ?, weighted_amount = ?, updated_at = ? WHERE id = ?'
  ).run(stage, weightedAmount(opp.amount, stage), now, opp.id);
  res.json(mapOpp(db.prepare('SELECT * FROM opportunities WHERE id = ?').get(opp.id)));
});

router.put('/:id', (req, res) => {
  const opp = db.prepare('SELECT * FROM opportunities WHERE id = ?').get(req.params.id);
  if (!opp) return res.status(404).json({ error: '商机不存在', code: 404 });
  if (!assertOwner(req.user, opp.owner_id)) return res.status(403).json({ error: '无权限', code: 403 });
  const { title, amount, expectedClose } = req.body || {};
  const amt = amount != null ? Number(amount) : opp.amount;
  db.prepare(
    'UPDATE opportunities SET title = COALESCE(?, title), amount = ?, weighted_amount = ?, expected_close = COALESCE(?, expected_close), updated_at = datetime(\'now\') WHERE id = ?'
  ).run(title, amt, weightedAmount(amt, opp.stage), expectedClose, opp.id);
  res.json(mapOpp(db.prepare('SELECT * FROM opportunities WHERE id = ?').get(opp.id)));
});

module.exports = router;
