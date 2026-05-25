const express = require('express');
const { v4: uuid } = require('uuid');
const db = require('../../db');
const { authRequired } = require('../../middleware/auth');
const { ownerFilter, assertOwner } = require('../../utils/permissions');

const router = express.Router();
router.use(authRequired);

router.get('/', (req, res) => {
  const { clause, params } = ownerFilter(req.user);
  const rows = db
    .prepare(
      `SELECT ct.*, c.name AS customer_name FROM contracts ct JOIN customers c ON c.id = ct.customer_id WHERE ${clause.replace('owner_id', 'ct.owner_id')} ORDER BY ct.created_at DESC`
    )
    .all(...params);
  res.json({ items: rows });
});

router.get('/:id', (req, res) => {
  const contract = db
    .prepare('SELECT ct.*, c.name AS customer_name FROM contracts ct JOIN customers c ON c.id = ct.customer_id WHERE ct.id = ?')
    .get(req.params.id);
  if (!contract) return res.status(404).json({ error: '合同不存在', code: 404 });
  if (!assertOwner(req.user, contract.owner_id)) return res.status(403).json({ error: '无权限', code: 403 });
  const approvals = db
    .prepare('SELECT a.*, u.name AS requester_name FROM approvals a JOIN users u ON u.id = a.requester_id WHERE contract_id = ? ORDER BY created_at DESC')
    .all(contract.id);
  res.json({ ...contract, approvals });
});

router.post('/', (req, res) => {
  const { customerId, opportunityId, title, amount } = req.body || {};
  if (!customerId || !title || amount == null) {
    return res.status(400).json({ error: '客户、标题、金额必填', code: 400 });
  }
  const id = uuid();
  const amt = Number(amount);
  let status = 'draft';
  let approvalStatus = null;
  if (amt > 100000) {
    status = 'pending_approval';
    approvalStatus = 'pending';
  }
  db.prepare(
    'INSERT INTO contracts (id, customer_id, opportunity_id, owner_id, title, amount, status, approval_status) VALUES (?,?,?,?,?,?,?,?)'
  ).run(id, customerId, opportunityId || null, req.user.id, title, amt, status, approvalStatus);

  if (amt > 100000) {
    db.prepare(
      'INSERT INTO approvals (id, contract_id, requester_id, status) VALUES (?,?,?,?)'
    ).run(uuid(), id, req.user.id, 'pending');
  }
  res.status(201).json(db.prepare('SELECT * FROM contracts WHERE id = ?').get(id));
});

router.post('/:id/submit', (req, res) => {
  const contract = db.prepare('SELECT * FROM contracts WHERE id = ?').get(req.params.id);
  if (!contract) return res.status(404).json({ error: '合同不存在', code: 404 });
  if (!assertOwner(req.user, contract.owner_id)) return res.status(403).json({ error: '无权限', code: 403 });
  if (contract.amount > 100000) {
    db.prepare('UPDATE contracts SET status = ?, approval_status = ? WHERE id = ?').run(
      'pending_approval',
      'pending',
      contract.id
    );
    const existing = db.prepare('SELECT id FROM approvals WHERE contract_id = ? AND status = ?').get(contract.id, 'pending');
    if (!existing) {
      db.prepare('INSERT INTO approvals (id, contract_id, requester_id, status) VALUES (?,?,?,?)').run(
        uuid(),
        contract.id,
        req.user.id,
        'pending'
      );
    }
  } else {
    db.prepare('UPDATE contracts SET status = ?, effective_at = datetime(\'now\') WHERE id = ?').run('active', contract.id);
  }
  res.json(db.prepare('SELECT * FROM contracts WHERE id = ?').get(contract.id));
});

module.exports = router;
