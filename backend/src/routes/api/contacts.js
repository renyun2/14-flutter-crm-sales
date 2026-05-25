const express = require('express');
const { v4: uuid } = require('uuid');
const db = require('../../db');
const { authRequired } = require('../../middleware/auth');
const { assertOwner } = require('../../utils/permissions');

const router = express.Router();
router.use(authRequired);

router.get('/', (req, res) => {
  const { customerId } = req.query;
  if (!customerId) return res.status(400).json({ error: 'customerId 必填', code: 400 });
  const customer = db.prepare('SELECT * FROM customers WHERE id = ?').get(customerId);
  if (!customer) return res.status(404).json({ error: '客户不存在', code: 404 });
  if (!assertOwner(req.user, customer.owner_id)) return res.status(403).json({ error: '无权限', code: 403 });
  const items = db.prepare('SELECT * FROM contacts WHERE customer_id = ?').all(customerId);
  res.json({ items });
});

router.post('/', (req, res) => {
  const { customerId, name, phone, email, title, isPrimary } = req.body || {};
  if (!customerId || !name) return res.status(400).json({ error: '客户和姓名必填', code: 400 });
  const customer = db.prepare('SELECT * FROM customers WHERE id = ?').get(customerId);
  if (!customer) return res.status(404).json({ error: '客户不存在', code: 404 });
  if (!assertOwner(req.user, customer.owner_id)) return res.status(403).json({ error: '无权限', code: 403 });
  const id = uuid();
  db.prepare(
    'INSERT INTO contacts (id, customer_id, name, phone, email, title, is_primary) VALUES (?,?,?,?,?,?,?)'
  ).run(id, customerId, name, phone || '', email || '', title || '', isPrimary ? 1 : 0);
  res.status(201).json(db.prepare('SELECT * FROM contacts WHERE id = ?').get(id));
});

module.exports = router;
