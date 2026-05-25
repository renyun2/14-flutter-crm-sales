const express = require('express');
const db = require('../../db');
const { authRequired } = require('../../middleware/auth');

const router = express.Router();
router.use(authRequired);

router.get('/', (_req, res) => {
  const items = db.prepare('SELECT * FROM products ORDER BY name ASC').all();
  res.json({ items });
});

module.exports = router;
