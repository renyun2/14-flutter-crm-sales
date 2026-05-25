const express = require('express');
const { v4: uuid } = require('uuid');
const db = require('../../db');
const { authRequired } = require('../../middleware/auth');
const { ownerFilter, assertOwner } = require('../../utils/permissions');

const router = express.Router();
router.use(authRequired);

function mapCustomer(row) {
  return { ...row, tags: JSON.parse(row.tags_json || '[]') };
}

router.get('/', (req, res) => {
  const { clause, params } = ownerFilter(req.user);
  const { q, tag } = req.query;
  let sql = `SELECT * FROM customers WHERE ${clause}`;
  const args = [...params];
  if (q) {
    sql += ' AND name LIKE ?';
    args.push(`%${q}%`);
  }
  sql += ' ORDER BY created_at DESC';
  let rows = db.prepare(sql).all(...args).map(mapCustomer);
  if (tag) rows = rows.filter((r) => r.tags.includes(tag));
  res.json({ items: rows });
});

router.get('/:id', (req, res) => {
  const customer = db.prepare('SELECT * FROM customers WHERE id = ?').get(req.params.id);
  if (!customer) return res.status(404).json({ error: '客户不存在', code: 404 });
  if (!assertOwner(req.user, customer.owner_id)) return res.status(403).json({ error: '无权限', code: 403 });
  const leads = db.prepare('SELECT * FROM leads WHERE customer_id = ?').all(customer.id);
  const opportunities = db
    .prepare('SELECT * FROM opportunities WHERE customer_id = ? ORDER BY updated_at DESC')
    .all(customer.id);
  const contracts = db.prepare('SELECT * FROM contracts WHERE customer_id = ?').all(customer.id);
  const visits = db.prepare('SELECT * FROM visits WHERE customer_id = ? ORDER BY planned_at DESC').all(customer.id);
  const contacts = db.prepare('SELECT * FROM contacts WHERE customer_id = ?').all(customer.id);
  res.json({
    ...mapCustomer(customer),
    leads,
    opportunities,
    contracts,
    visits,
    contacts,
  });
});

router.post('/', (req, res) => {
  const { name, industry, address, tags } = req.body || {};
  if (!name) return res.status(400).json({ error: '客户名称必填', code: 400 });
  const id = uuid();
  db.prepare(
    'INSERT INTO customers (id, name, industry, address, tags_json, owner_id) VALUES (?,?,?,?,?,?)'
  ).run(id, name, industry || '', address || '', JSON.stringify(tags || []), req.user.id);
  res.status(201).json(mapCustomer(db.prepare('SELECT * FROM customers WHERE id = ?').get(id)));
});

router.put('/:id', (req, res) => {
  const customer = db.prepare('SELECT * FROM customers WHERE id = ?').get(req.params.id);
  if (!customer) return res.status(404).json({ error: '客户不存在', code: 404 });
  if (!assertOwner(req.user, customer.owner_id)) return res.status(403).json({ error: '无权限', code: 403 });
  const { name, industry, address, tags } = req.body || {};
  db.prepare(
    'UPDATE customers SET name = COALESCE(?, name), industry = COALESCE(?, industry), address = COALESCE(?, address), tags_json = COALESCE(?, tags_json) WHERE id = ?'
  ).run(name, industry, address, tags ? JSON.stringify(tags) : null, customer.id);
  res.json(mapCustomer(db.prepare('SELECT * FROM customers WHERE id = ?').get(customer.id)));
});

module.exports = router;
