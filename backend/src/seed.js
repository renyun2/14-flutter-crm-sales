const { v4: uuid } = require('uuid');
const db = require('./db');
const { weightedAmount } = require('./utils/stages');

const SOURCES = ['官网', '展会', '转介绍', '电话营销', '合作伙伴'];
const LEAD_STATUSES = ['new', 'contacted', 'qualified', 'converted', 'lost'];
const STAGES = ['initial', 'qualification', 'proposal', 'negotiation', 'won', 'lost'];
const INDUSTRIES = ['制造', '金融', '零售', '医疗', '教育', '互联网'];

function daysAgo(n) {
  const d = new Date();
  d.setDate(d.getDate() - n);
  return d.toISOString();
}

function daysFromNow(n) {
  const d = new Date();
  d.setDate(d.getDate() + n);
  return d.toISOString();
}

function seed() {
  const count = db.prepare('SELECT COUNT(*) AS c FROM users').get().c;
  if (count > 0) return;

  const adminId = uuid();
  const managerId = uuid();
  const salesIds = [uuid(), uuid(), uuid(), uuid()];

  const insertUser = db.prepare(
    'INSERT INTO users (id, employee_no, name, password, role, manager_id, team_id) VALUES (?,?,?,?,?,?,?)'
  );
  insertUser.run(adminId, 'A001', '系统管理员', '123456', 'admin', null, 'team-1');
  insertUser.run(managerId, 'M001', '张经理', '123456', 'manager', null, 'team-1');
  salesIds.forEach((id, i) => {
    insertUser.run(id, `S00${i + 1}`, `销售${i + 1}`, '123456', 'sales', managerId, 'team-1');
  });

  const customerIds = [];
  const insertCustomer = db.prepare(
    'INSERT INTO customers (id, name, industry, address, tags_json, owner_id, created_at) VALUES (?,?,?,?,?,?,?)'
  );
  for (let i = 1; i <= 22; i += 1) {
    const id = uuid();
    customerIds.push(id);
    const owner = salesIds[i % salesIds.length];
    insertCustomer.run(
      id,
      `客户公司${i}`,
      INDUSTRIES[i % INDUSTRIES.length],
      `上海市浦东新区世纪大道${100 + i}号`,
      JSON.stringify(i % 3 === 0 ? ['重点客户'] : i % 2 === 0 ? ['VIP'] : []),
      owner,
      daysAgo(i * 2)
    );
  }

  const insertContact = db.prepare(
    'INSERT INTO contacts (id, customer_id, name, phone, email, title, is_primary) VALUES (?,?,?,?,?,?,?)'
  );
  customerIds.forEach((cid, i) => {
    insertContact.run(uuid(), cid, `联系人${i + 1}`, `1380000${String(i).padStart(4, '0')}`, `c${i}@example.com`, '采购经理', 1);
  });

  const insertLead = db.prepare(
    'INSERT INTO leads (id, title, company, source, status, owner_id, last_follow_at, created_at) VALUES (?,?,?,?,?,?,?,?)'
  );
  const leadIds = [];
  for (let i = 1; i <= 55; i += 1) {
    const id = uuid();
    leadIds.push(id);
    const owner = salesIds[i % salesIds.length];
    const followDays = i % 8 === 0 ? null : i % 10 === 0 ? daysAgo(10) : daysAgo(i % 5);
    insertLead.run(
      id,
      `线索-${i}`,
      `潜客企业${i}`,
      SOURCES[i % SOURCES.length],
      LEAD_STATUSES[i % LEAD_STATUSES.length],
      owner,
      followDays,
      daysAgo(i)
    );
  }

  const insertFollow = db.prepare(
    'INSERT INTO lead_follow_ups (id, lead_id, user_id, content, created_at) VALUES (?,?,?,?,?)'
  );
  leadIds.slice(0, 30).forEach((lid, i) => {
    insertFollow.run(uuid(), lid, salesIds[i % salesIds.length], `跟进记录：已电话沟通 @销售${(i % 4) + 1}`, daysAgo(i % 3));
  });

  const insertOpp = db.prepare(
    'INSERT INTO opportunities (id, title, customer_id, owner_id, stage, amount, weighted_amount, probability, expected_close, created_at, updated_at) VALUES (?,?,?,?,?,?,?,?,?,?,?)'
  );
  const oppIds = [];
  for (let i = 1; i <= 35; i += 1) {
    const id = uuid();
    oppIds.push(id);
    const stage = STAGES[i % STAGES.length];
    const amount = 50000 + (i * 8000);
    const owner = salesIds[i % salesIds.length];
    insertOpp.run(
      id,
      `商机-${i}`,
      customerIds[i % customerIds.length],
      owner,
      stage,
      amount,
      weightedAmount(amount, stage),
      [10, 25, 50, 75, 100, 0][i % 6],
      daysFromNow(30 + i),
      daysAgo(i),
      daysAgo(i % 3)
    );
  }

  const insertProduct = db.prepare(
    'INSERT INTO products (id, name, sku, unit_price, unit, category) VALUES (?,?,?,?,?,?)'
  );
  const productIds = [];
  for (let i = 1; i <= 12; i += 1) {
    const id = uuid();
    productIds.push(id);
    insertProduct.run(id, `产品${i}`, `SKU-${1000 + i}`, 1000 * i, '套', i % 2 === 0 ? '软件' : '服务');
  }

  const insertQuote = db.prepare(
    'INSERT INTO quotes (id, opportunity_id, owner_id, title, discount, total, status, created_at) VALUES (?,?,?,?,?,?,?,?)'
  );
  const quoteIds = [];
  oppIds.slice(0, 10).forEach((oid, i) => {
    const id = uuid();
    quoteIds.push(id);
    insertQuote.run(id, oid, salesIds[i % salesIds.length], `报价单-${i + 1}`, 0.05, 80000 + i * 5000, 'draft', daysAgo(i));
  });

  const insertQuoteItem = db.prepare(
    'INSERT INTO quote_items (id, quote_id, product_id, quantity, unit_price, discount) VALUES (?,?,?,?,?,?)'
  );
  quoteIds.forEach((qid, i) => {
    insertQuoteItem.run(uuid(), qid, productIds[i % productIds.length], 2, 1000 * (i + 1), 0);
  });

  const insertVisit = db.prepare(
    'INSERT INTO visits (id, customer_id, owner_id, title, planned_at, status, address, created_at) VALUES (?,?,?,?,?,?,?,?)'
  );
  for (let i = 1; i <= 15; i += 1) {
    insertVisit.run(
      uuid(),
      customerIds[i % customerIds.length],
      salesIds[i % salesIds.length],
      `拜访计划-${i}`,
      daysFromNow(i - 5),
      i % 4 === 0 ? 'completed' : i % 5 === 0 ? 'cancelled' : 'planned',
      `上海市浦东新区世纪大道${100 + i}号`,
      daysAgo(i)
    );
  }

  const insertContract = db.prepare(
    'INSERT INTO contracts (id, customer_id, opportunity_id, owner_id, title, amount, status, approval_status, created_at) VALUES (?,?,?,?,?,?,?,?,?)'
  );
  const contractIds = [];
  for (let i = 1; i <= 8; i += 1) {
    const id = uuid();
    contractIds.push(id);
    const amount = i <= 3 ? 150000 : 50000;
    const status = i <= 3 ? 'pending_approval' : 'draft';
    insertContract.run(
      id,
      customerIds[i % customerIds.length],
      oppIds[i % oppIds.length],
      salesIds[i % salesIds.length],
      `合同-${i}`,
      amount,
      status,
      i <= 3 ? 'pending' : null,
      daysAgo(i)
    );
  }

  const insertApproval = db.prepare(
    'INSERT INTO approvals (id, contract_id, requester_id, status, created_at) VALUES (?,?,?,?,?)'
  );
  contractIds.slice(0, 3).forEach((cid, i) => {
    insertApproval.run(uuid(), cid, salesIds[i % salesIds.length], 'pending', daysAgo(i));
  });

  const insertTask = db.prepare(
    'INSERT INTO tasks (id, owner_id, title, related_type, related_id, due_at, status, overdue, created_at) VALUES (?,?,?,?,?,?,?,?,?)'
  );
  for (let i = 1; i <= 12; i += 1) {
    const overdue = i % 4 === 0 ? 1 : 0;
    insertTask.run(
      uuid(),
      salesIds[i % salesIds.length],
      `待办任务-${i}`,
      'lead',
      leadIds[i % leadIds.length],
      daysFromNow(i - 6),
      overdue ? 'pending' : i % 3 === 0 ? 'done' : 'pending',
      overdue,
      daysAgo(i)
    );
  }

  const insertNotif = db.prepare(
    'INSERT INTO notifications (id, user_id, title, body, type, read_flag, created_at) VALUES (?,?,?,?,?,?,?)'
  );
  [managerId, ...salesIds].forEach((uid, i) => {
    insertNotif.run(uuid(), uid, '审批提醒', '有新的合同待审批', 'approval', 0, daysAgo(i));
    insertNotif.run(uuid(), uid, '任务提醒', '您有逾期任务待处理', 'task', i % 2, daysAgo(i + 1));
  });

  console.log('CRM seed completed');
}

module.exports = { seed };

if (require.main === module) seed();
