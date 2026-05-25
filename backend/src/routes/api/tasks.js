const express = require('express');
const { v4: uuid } = require('uuid');
const db = require('../../db');
const { authRequired } = require('../../middleware/auth');
const { ownerFilter, assertOwner } = require('../../utils/permissions');

const router = express.Router();
router.use(authRequired);

router.get('/', (req, res) => {
  const { clause, params } = ownerFilter(req.user);
  const rows = db.prepare(`SELECT * FROM tasks WHERE ${clause} ORDER BY due_at ASC`).all(...params);
  const now = Date.now();
  const items = rows.map((t) => {
    const overdue = t.status !== 'done' && new Date(t.due_at).getTime() < now;
    return { ...t, overdue: overdue ? 1 : 0 };
  });
  res.json({ items });
});

router.patch('/:id', (req, res) => {
  const task = db.prepare('SELECT * FROM tasks WHERE id = ?').get(req.params.id);
  if (!task) return res.status(404).json({ error: '任务不存在', code: 404 });
  if (!assertOwner(req.user, task.owner_id)) return res.status(403).json({ error: '无权限', code: 403 });
  const { status } = req.body || {};
  db.prepare('UPDATE tasks SET status = COALESCE(?, status), overdue = 0 WHERE id = ?').run(status, task.id);
  res.json(db.prepare('SELECT * FROM tasks WHERE id = ?').get(task.id));
});

router.post('/', (req, res) => {
  const { title, dueAt, relatedType, relatedId } = req.body || {};
  if (!title || !dueAt) return res.status(400).json({ error: '标题和截止时间必填', code: 400 });
  const id = uuid();
  db.prepare(
    'INSERT INTO tasks (id, owner_id, title, related_type, related_id, due_at) VALUES (?,?,?,?,?,?)'
  ).run(id, req.user.id, title, relatedType || '', relatedId || '', dueAt);
  res.status(201).json(db.prepare('SELECT * FROM tasks WHERE id = ?').get(id));
});

module.exports = router;
