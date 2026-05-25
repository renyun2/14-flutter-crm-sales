const db = require('../db');

function getTeamUserIds(user) {
  if (user.role === 'admin') {
    return db.prepare('SELECT id FROM users').all().map((r) => r.id);
  }
  if (user.role === 'manager') {
    return db
      .prepare('SELECT id FROM users WHERE manager_id = ? OR id = ?')
      .all(user.id, user.id)
      .map((r) => r.id);
  }
  return [user.id];
}

function ownerFilter(user, column = 'owner_id') {
  const ids = getTeamUserIds(user);
  return { clause: `${column} IN (${ids.map(() => '?').join(',')})`, params: ids };
}

function assertOwner(user, ownerId) {
  const ids = getTeamUserIds(user);
  return ids.includes(ownerId);
}

module.exports = { getTeamUserIds, ownerFilter, assertOwner };
