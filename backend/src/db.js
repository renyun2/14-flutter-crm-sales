const Database = require('better-sqlite3');
const fs = require('fs');
const path = require('path');

const dataDir = path.join(__dirname, '..', 'data');
if (!fs.existsSync(dataDir)) fs.mkdirSync(dataDir, { recursive: true });

const dbPath = process.env.CRM_DB_PATH || path.join(dataDir, 'crm.db');
const db = new Database(dbPath);
db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');

function initSchema() {
  db.exec(`
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      employee_no TEXT NOT NULL UNIQUE,
      name TEXT NOT NULL,
      password TEXT NOT NULL DEFAULT '123456',
      role TEXT NOT NULL CHECK(role IN ('sales','manager','admin')),
      manager_id TEXT REFERENCES users(id),
      team_id TEXT NOT NULL DEFAULT 'team-1',
      created_at TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS sessions (
      token TEXT PRIMARY KEY,
      user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      created_at TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS customers (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      industry TEXT DEFAULT '',
      address TEXT DEFAULT '',
      tags_json TEXT NOT NULL DEFAULT '[]',
      owner_id TEXT NOT NULL REFERENCES users(id),
      created_at TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS contacts (
      id TEXT PRIMARY KEY,
      customer_id TEXT NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
      name TEXT NOT NULL,
      phone TEXT DEFAULT '',
      email TEXT DEFAULT '',
      title TEXT DEFAULT '',
      is_primary INTEGER NOT NULL DEFAULT 0
    );

    CREATE TABLE IF NOT EXISTS leads (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      company TEXT NOT NULL,
      source TEXT NOT NULL DEFAULT '官网',
      status TEXT NOT NULL DEFAULT 'new',
      owner_id TEXT NOT NULL REFERENCES users(id),
      customer_id TEXT REFERENCES customers(id),
      last_follow_at TEXT,
      created_at TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS lead_follow_ups (
      id TEXT PRIMARY KEY,
      lead_id TEXT NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
      user_id TEXT NOT NULL REFERENCES users(id),
      content TEXT NOT NULL,
      created_at TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS opportunities (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      customer_id TEXT NOT NULL REFERENCES customers(id),
      owner_id TEXT NOT NULL REFERENCES users(id),
      stage TEXT NOT NULL DEFAULT 'initial',
      amount REAL NOT NULL DEFAULT 0,
      weighted_amount REAL NOT NULL DEFAULT 0,
      probability INTEGER NOT NULL DEFAULT 10,
      expected_close TEXT,
      created_at TEXT NOT NULL DEFAULT (datetime('now')),
      updated_at TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS visits (
      id TEXT PRIMARY KEY,
      customer_id TEXT NOT NULL REFERENCES customers(id),
      owner_id TEXT NOT NULL REFERENCES users(id),
      title TEXT NOT NULL,
      planned_at TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'planned',
      address TEXT DEFAULT '',
      check_in_at TEXT,
      summary TEXT DEFAULT '',
      photo_urls_json TEXT NOT NULL DEFAULT '[]',
      created_at TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS products (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      sku TEXT NOT NULL UNIQUE,
      unit_price REAL NOT NULL,
      unit TEXT NOT NULL DEFAULT '套',
      category TEXT DEFAULT ''
    );

    CREATE TABLE IF NOT EXISTS quotes (
      id TEXT PRIMARY KEY,
      opportunity_id TEXT NOT NULL REFERENCES opportunities(id),
      owner_id TEXT NOT NULL REFERENCES users(id),
      title TEXT NOT NULL,
      discount REAL NOT NULL DEFAULT 0,
      total REAL NOT NULL DEFAULT 0,
      status TEXT NOT NULL DEFAULT 'draft',
      created_at TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS quote_items (
      id TEXT PRIMARY KEY,
      quote_id TEXT NOT NULL REFERENCES quotes(id) ON DELETE CASCADE,
      product_id TEXT NOT NULL REFERENCES products(id),
      quantity INTEGER NOT NULL DEFAULT 1,
      unit_price REAL NOT NULL,
      discount REAL NOT NULL DEFAULT 0
    );

    CREATE TABLE IF NOT EXISTS contracts (
      id TEXT PRIMARY KEY,
      customer_id TEXT NOT NULL REFERENCES customers(id),
      opportunity_id TEXT REFERENCES opportunities(id),
      owner_id TEXT NOT NULL REFERENCES users(id),
      title TEXT NOT NULL,
      amount REAL NOT NULL,
      status TEXT NOT NULL DEFAULT 'draft',
      approval_status TEXT DEFAULT NULL,
      created_at TEXT NOT NULL DEFAULT (datetime('now')),
      effective_at TEXT
    );

    CREATE TABLE IF NOT EXISTS approvals (
      id TEXT PRIMARY KEY,
      contract_id TEXT NOT NULL REFERENCES contracts(id) ON DELETE CASCADE,
      requester_id TEXT NOT NULL REFERENCES users(id),
      approver_id TEXT REFERENCES users(id),
      status TEXT NOT NULL DEFAULT 'pending',
      comment TEXT DEFAULT '',
      created_at TEXT NOT NULL DEFAULT (datetime('now')),
      resolved_at TEXT
    );

    CREATE TABLE IF NOT EXISTS tasks (
      id TEXT PRIMARY KEY,
      owner_id TEXT NOT NULL REFERENCES users(id),
      title TEXT NOT NULL,
      related_type TEXT DEFAULT '',
      related_id TEXT DEFAULT '',
      due_at TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'pending',
      overdue INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS notifications (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      title TEXT NOT NULL,
      body TEXT NOT NULL,
      type TEXT NOT NULL DEFAULT 'system',
      read_flag INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL DEFAULT (datetime('now'))
    );
  `);
}

initSchema();

module.exports = db;
