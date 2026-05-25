# CRM 销售助手 App

面向 B 端销售人员的移动 CRM：线索跟进、商机 Pipeline、客户 360、合同审批、拜访签到（Mock 定位）、业绩看板、任务待办。

## 技术栈

| 层 | 技术 |
|---|---|
| 前端 | Flutter 3.22+、Riverpod、go_router、dio、fl_chart、table_calendar、hive |
| 后端 Mock | Express + better-sqlite3，端口 **3002** |

## 测试账号

| 工号 | 密码 | 角色 | 说明 |
|------|------|------|------|
| S001 | 123456 | sales | 销售，仅看自己的数据 |
| S002 | 123456 | sales | 销售 |
| M001 | 123456 | manager | 经理，可看团队数据 + 审批 |
| A001 | 123456 | admin | 管理员，全量数据 |

## 快速开始

### 1. 启动 Mock 后端

```bash
cd backend
npm install
npm run dev
```

服务地址：`http://localhost:3002`

### 2. Web 调试 Flutter

```bash
cd mobile
flutter pub get
flutter run -d chrome --dart-define=API_BASE=http://localhost:3002
```

## 路由图

```
/                     启动页
/login                登录
/dashboard            工作台（Tab）
/customers            客户列表（Tab）
/opportunities        商机 Kanban（Tab）
/profile              个人中心（Tab）
/leads                线索列表
/lead/create          新建线索
/lead/:id             线索详情
/opportunity/:id      商机详情
/customer/create      新建客户
/customer/:id         客户 360
/customer/:id/contacts 联系人
/visits               拜访计划
/visit/create         新建拜访
/visit/:id            拜访详情（签到 Mock + Hive 草稿）
/quotes               报价列表
/quote/:id            报价编辑
/contracts            合同列表
/contract/:id         合同详情
/approvals            审批中心（经理）
/tasks                任务中心
/reports              业绩报表
/products             产品价目
/notifications        消息
```

## 业务规则（Mock）

- 商机阶段：初步接触 → 需求确认 → 方案报价 → 谈判 → 赢单/输单；销售不可回退阶段，经理可回退
- 线索 7 天未跟进标记逾期
- 合同金额 > 10 万需经理审批
- 数据权限：销售只看自己的；经理看团队

## 测试

```bash
# 后端 API 测试
cd backend && npm test

# Flutter 单元测试
cd mobile && flutter test
```

Seed 数据：≥55 线索、≥35 商机、≥22 客户。

## Web 兼容说明

- 不使用 geolocator / contacts_service 等原生插件
- 拜访签到：手动选择客户地址 + 点击签到
- 外呼：Mock 拨号对话框
