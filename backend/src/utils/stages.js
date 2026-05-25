const STAGES = ['initial', 'qualification', 'proposal', 'negotiation', 'won', 'lost'];

const STAGE_LABELS = {
  initial: '初步接触',
  qualification: '需求确认',
  proposal: '方案报价',
  negotiation: '谈判',
  won: '赢单',
  lost: '输单',
};

const STAGE_WEIGHTS = {
  initial: 0.1,
  qualification: 0.25,
  proposal: 0.5,
  negotiation: 0.75,
  won: 1,
  lost: 0,
};

function stageIndex(stage) {
  return STAGES.indexOf(stage);
}

function canMoveStage(from, to, role) {
  if (!STAGES.includes(from) || !STAGES.includes(to)) return false;
  if (from === to) return true;
  const fromIdx = stageIndex(from);
  const toIdx = stageIndex(to);
  if (toIdx < fromIdx) return role === 'manager' || role === 'admin';
  return true;
}

function weightedAmount(amount, stage) {
  return Math.round(amount * (STAGE_WEIGHTS[stage] ?? 0) * 100) / 100;
}

module.exports = { STAGES, STAGE_LABELS, STAGE_WEIGHTS, canMoveStage, weightedAmount };
