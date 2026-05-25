const express = require('express');
const { v4: uuid } = require('uuid');
const db = require('../../db');
const { authRequired } = require('../../middleware/auth');
const { ownerFilter, assertOwner } = require('../../utils/permissions');

const router = express.Router();
router.use(authRequired);

function mapQuote(row) {
  const items = db
    .prepare('SELECT qi.*, p.name AS product_name FROM quote_items qi JOIN products p ON p.id = qi.product_id WHERE quote_id = ?')
    .all(row.id);
  return { ...row, items, pdfUrl: `/api/quotes/${row.id}/pdf` };
}

function calcTotal(items, discount) {
  const sub = items.reduce((s, i) => s + i.quantity * i.unit_price * (1 - (i.discount || 0)), 0);
  return Math.round(sub * (1 - (discount || 0)) * 100) / 100;
}

router.get('/', (req, res) => {
  const { clause, params } = ownerFilter(req.user);
  const rows = db.prepare(`SELECT * FROM quotes WHERE ${clause} ORDER BY created_at DESC`).all(...params).map(mapQuote);
  res.json({ items: rows });
});

router.get('/:id', (req, res) => {
  const quote = db.prepare('SELECT * FROM quotes WHERE id = ?').get(req.params.id);
  if (!quote) return res.status(404).json({ error: '报价不存在', code: 404 });
  if (!assertOwner(req.user, quote.owner_id)) return res.status(403).json({ error: '无权限', code: 403 });
  res.json(mapQuote(quote));
});

router.post('/', (req, res) => {
  const { opportunityId, title, items, discount } = req.body || {};
  if (!opportunityId || !title) return res.status(400).json({ error: '商机和标题必填', code: 400 });
  const id = uuid();
  const disc = Number(discount) || 0;
  if (disc < 0 || disc > 0.3) return res.status(400).json({ error: '折扣需在 0-30% 之间', code: 400 });
  const lineItems = (items || []).map((i) => ({
    quantity: i.quantity || 1,
    unit_price: i.unitPrice || i.unit_price || 0,
    discount: i.discount || 0,
    product_id: i.productId || i.product_id,
  }));
  const total = calcTotal(lineItems, disc);
  db.prepare(
    'INSERT INTO quotes (id, opportunity_id, owner_id, title, discount, total) VALUES (?,?,?,?,?,?)'
  ).run(id, opportunityId, req.user.id, title, disc, total);
  const insertItem = db.prepare(
    'INSERT INTO quote_items (id, quote_id, product_id, quantity, unit_price, discount) VALUES (?,?,?,?,?,?)'
  );
  lineItems.forEach((i) => {
    insertItem.run(uuid(), id, i.product_id, i.quantity, i.unit_price, i.discount);
  });
  res.status(201).json(mapQuote(db.prepare('SELECT * FROM quotes WHERE id = ?').get(id)));
});

router.put('/:id', (req, res) => {
  const quote = db.prepare('SELECT * FROM quotes WHERE id = ?').get(req.params.id);
  if (!quote) return res.status(404).json({ error: '报价不存在', code: 404 });
  if (!assertOwner(req.user, quote.owner_id)) return res.status(403).json({ error: '无权限', code: 403 });
  const { title, items, discount } = req.body || {};
  const disc = discount != null ? Number(discount) : quote.discount;
  if (disc < 0 || disc > 0.3) return res.status(400).json({ error: '折扣需在 0-30% 之间', code: 400 });
  if (items) {
    db.prepare('DELETE FROM quote_items WHERE quote_id = ?').run(quote.id);
    const insertItem = db.prepare(
      'INSERT INTO quote_items (id, quote_id, product_id, quantity, unit_price, discount) VALUES (?,?,?,?,?,?)'
    );
    const lineItems = items.map((i) => ({
      quantity: i.quantity || 1,
      unit_price: i.unitPrice || i.unit_price || 0,
      discount: i.discount || 0,
      product_id: i.productId || i.product_id,
    }));
    lineItems.forEach((i) => {
      insertItem.run(uuid(), quote.id, i.product_id, i.quantity, i.unit_price, i.discount);
    });
    const total = calcTotal(lineItems, disc);
    db.prepare('UPDATE quotes SET title = COALESCE(?, title), discount = ?, total = ? WHERE id = ?').run(
      title,
      disc,
      total,
      quote.id
    );
  } else {
    db.prepare('UPDATE quotes SET title = COALESCE(?, title), discount = ? WHERE id = ?').run(title, disc, quote.id);
  }
  res.json(mapQuote(db.prepare('SELECT * FROM quotes WHERE id = ?').get(quote.id)));
});

router.get('/:id/pdf', (req, res) => {
  const quote = db.prepare('SELECT * FROM quotes WHERE id = ?').get(req.params.id);
  if (!quote) return res.status(404).json({ error: '报价不存在', code: 404 });
  res.json({ placeholder: true, message: 'PDF 生成功能占位', quoteId: quote.id });
});

module.exports = router;
