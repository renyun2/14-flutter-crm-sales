const express = require('express');
const db = require('../../db');
const { authRequired, requireRole } = require('../../middleware/auth');

const router = express.Router();
router.use(authRequired);
router.use(requireRole('manager', 'admin'));

router.get('/', (req, res) => {
  const items = db
    .prepare(
      `SELECT a.*, ct.title AS contract_title, ct.amount, u.name AS requester_name
       FROM approvals a
       JOIN contracts ct ON ct.id = a.contract_id
       JOIN users u ON u.id = a.requester_id
       WHERE a.status = 'pending'
       ORDER BY a.created_at ASC`
    )
    .all();
  res.json({ items });
});

router.post('/:id/resolve', (req, res) => {
  const approval = db.prepare('SELECT * FROM approvals WHERE id = ?').get(req.params.id);
  if (!approval) return res.status(404).json({ error: '审批不存在', code: 404 });
  const { approved, comment } = req.body || {};
  const now = new Date().toISOString();
  const status = approved ? 'approved' : 'rejected';
  db.prepare(
    'UPDATE approvals SET status = ?, approver_id = ?, comment = ?, resolved_at = ? WHERE id = ?'
  ).run(status, req.user.id, comment || '', now, approval.id);
  if (approved) {
    db.prepare('UPDATE contracts SET status = ?, approval_status = ?, effective_at = ? WHERE id = ?').run(
      'active',
      'approved',
      now,
      approval.contract_id
    );
  } else {
    db.prepare('UPDATE contracts SET status = ?, approval_status = ? WHERE id = ?').run(
      'draft',
      'rejected',
      approval.contract_id
    );
  }
  res.json(db.prepare('SELECT * FROM approvals WHERE id = ?').get(approval.id));
});

module.exports = router;
