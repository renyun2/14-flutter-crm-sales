const express = require('express');
const db = require('../../db');
const { authRequired, requireRole } = require('../../middleware/auth');

const router = express.Router();
router.use(authRequired);
router.use(requireRole('manager', 'admin'));

router.get('/', (req, res) => {
  const members = db
    .prepare(
      `SELECT u.id, u.employee_no, u.name, u.role,
              (SELECT COUNT(*) FROM leads WHERE owner_id = u.id) AS lead_count,
              (SELECT COUNT(*) FROM opportunities WHERE owner_id = u.id) AS opp_count,
              (SELECT COALESCE(SUM(amount),0) FROM opportunities WHERE owner_id = u.id AND stage = 'won') AS won_amount
       FROM users u
       WHERE u.manager_id = ? OR u.id = ?
       ORDER BY u.role DESC, u.name ASC`
    )
    .all(req.user.id, req.user.id);
  res.json({ items: members });
});

module.exports = router;
