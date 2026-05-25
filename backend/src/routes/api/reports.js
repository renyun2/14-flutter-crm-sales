const express = require('express');
const db = require('../../db');
const { authRequired } = require('../../middleware/auth');
const { getTeamUserIds } = require('../../utils/permissions');
const { STAGES, STAGE_LABELS } = require('../../utils/stages');

const router = express.Router();
router.use(authRequired);

router.get('/summary', (req, res) => {
  const ids = getTeamUserIds(req.user);
  const placeholders = ids.map(() => '?').join(',');
  const period = req.query.period === 'quarter' ? 'quarter' : 'month';

  const opps = db
    .prepare(`SELECT stage, amount, weighted_amount FROM opportunities WHERE owner_id IN (${placeholders})`)
    .all(...ids);

  const funnel = STAGES.filter((s) => s !== 'lost').map((s) => ({
    stage: s,
    label: STAGE_LABELS[s],
    count: opps.filter((o) => o.stage === s).length,
    amount: opps.filter((o) => o.stage === s).reduce((sum, o) => sum + o.amount, 0),
  }));

  const wonAmount = opps.filter((o) => o.stage === 'won').reduce((s, o) => s + o.amount, 0);
  const pipeline = opps.reduce((s, o) => s + o.weighted_amount, 0);

  const trend = [];
  for (let i = 5; i >= 0; i -= 1) {
    trend.push({
      label: period === 'quarter' ? `Q${6 - i}` : `${6 - i}月`,
      amount: Math.round(wonAmount * (0.6 + i * 0.08)),
      pipeline: Math.round(pipeline * (0.5 + i * 0.1)),
    });
  }

  const ranking = db
    .prepare(
      `SELECT u.id, u.name, u.employee_no,
              COALESCE(SUM(CASE WHEN o.stage = 'won' THEN o.amount ELSE 0 END), 0) AS won_amount,
              COUNT(o.id) AS opp_count
       FROM users u
       LEFT JOIN opportunities o ON o.owner_id = u.id
       WHERE u.id IN (${placeholders}) AND u.role = 'sales'
       GROUP BY u.id
       ORDER BY won_amount DESC`
    )
    .all(...ids);

  res.json({
    period,
    kpis: { wonAmount, pipeline, oppCount: opps.length, winRate: opps.length ? opps.filter((o) => o.stage === 'won').length / opps.length : 0 },
    funnel,
    trend,
    ranking,
  });
});

module.exports = router;
