# 项目 14：CRM 销售助手 App（Flutter）

> 本文件仅描述需求，不包含任何实现代码。UI 使用 Material 基础组件，不做美化。

## 一、项目简介
面向 B 端销售人员的移动 CRM：线索跟进、商机 pipeline、客户 360、合同审批、拜访签到（Mock 定位）、业绩看板、任务待办。Flutter Web 调试，Express Mock 后端模拟复杂销售流程与权限。

## 二、技术栈

### 前端
- Flutter 3.22+ / Dart 3
- 状态：Riverpod
- 路由：go_router
- 网络：dio
- 图表：fl_chart（漏斗图、折线图、饼图）
- 日历：table_calendar（拜访计划）
- 本地：shared_preferences

### 后端 Mock
- Express + better-sqlite3
- JWT 角色：销售(sales) / 经理(manager) / 管理员(admin)
- 端口 `3002`

### Web 兼容约束
- **禁止**：geolocator、background_fetch、contacts_service、call_log
- **替代**：拜访「签到」= 点击按钮 + 选手动选客户地址；外呼 = Mock 拨号对话框

## 三、后端 Mock API 设计

| 模块 | 路径 | 说明 |
|------|------|------|
| 认证 | `/api/auth/*` | 登录、角色 |
| 线索 | `/api/leads` | CRUD、分配、转化商机 |
| 商机 | `/api/opportunities` | 阶段流转、金额加权 |
| 客户 | `/api/customers` | 360 视图、联系人、标签 |
| 联系人 | `/api/contacts` | 隶属客户 |
| 拜访 | `/api/visits` | 计划/完成/取消，签到 Mock |
| 合同 | `/api/contracts` | 草稿→审批→生效 |
| 审批 | `/api/approvals` | 经理审批队列 |
| 任务 | `/api/tasks` | 待办、逾期标记 |
| 产品 | `/api/products` | 价目表 |
| 报价 | `/api/quotes` | 关联商机、PDF 占位 |
| 报表 | `/api/reports/*` | 业绩、漏斗、排行 |
| 通知 | `/api/notifications` | 审批/任务提醒 |
| 团队 | `/api/team` | 经理看下属数据 |

**业务规则**
- 商机阶段：初步接触→需求确认→方案报价→谈判→赢单/输单（不可逆回退需经理权限）
- 线索 7 天未跟进自动标记「逾期」
- 合同金额 > 10 万需经理审批
- 数据权限：销售只看自己的；经理看团队

## 四、页面清单（≥22 页）

| 序号 | 页面 | 路由 | 说明 |
|------|------|------|------|
| 1 | 启动 | `/` | |
| 2 | 登录 | `/login` | 工号+密码 |
| 3 | 工作台 | `/dashboard` | 今日待办、业绩摘要、快捷入口 |
| 4 | 线索列表 | `/leads` | 筛选：状态/来源/逾期 |
| 5 | 线索详情 | `/lead/:id` | 跟进记录时间轴 |
| 6 | 新建线索 | `/lead/create` | |
| 7 | 商机看板 | `/opportunities` | Kanban 按阶段分列 |
| 8 | 商机详情 | `/opportunity/:id` | 阶段推进、关联报价 |
| 9 | 客户列表 | `/customers` | 搜索、标签筛选 |
| 10 | 客户 360 | `/customer/:id` | 商机/合同/拜访聚合 |
| 11 | 新建客户 | `/customer/create` | |
| 12 | 联系人 | `/customer/:id/contacts` | |
| 13 | 拜访计划 | `/visits` | 日历+列表双视图 |
| 14 | 拜访详情 | `/visit/:id` | 签到、纪要、照片 URL |
| 15 | 新建拜访 | `/visit/create` | |
| 16 | 报价列表 | `/quotes` | |
| 17 | 报价编辑 | `/quote/:id` | 行项目、折扣校验 |
| 18 | 合同列表 | `/contracts` | |
| 19 | 合同详情 | `/contract/:id` | 审批流展示 |
| 20 | 审批中心 | `/approvals` | 经理专属 |
| 21 | 任务中心 | `/tasks` | |
| 22 | 业绩报表 | `/reports` | 漏斗+趋势+排行 |
| 23 | 产品价目 | `/products` | |
| 24 | 消息 | `/notifications` | |
| 25 | 个人中心 | `/profile` | 设置、退出 |

**底部导航**：工作台 | 客户 | 商机 | 我的

## 五、核心功能需求
1. 商机 Kanban：Web 端拖拽改阶段（Draggable + DragTarget 或按钮推进）
2. 客户 360：Tab 聚合线索/商机/合同/拜访
3. 跟进记录：富文本简版（TextField + @提及 Mock）
4. 报表：本月/本季切换，fl_chart 渲染
5. 离线草稿：拜访纪要未提交时 hive 暂存（Web 可用）

## 六、编译与调试
```bash
cd backend && npm run dev          # :3002
cd mobile && flutter run -d chrome --dart-define=API_BASE=http://localhost:3002
```

## 七、交付物
- 完整前后端工程
- seed：≥50 线索、≥30 商机、≥20 客户、阶段分布合理
- API 测试：商机流转、审批、权限隔离
- README：角色账号表、路由图

## 八、本次任务
**只列出需求和架构规划，不要写代码。**
请输出：
1. 模块划分（lead/opportunity/customer/visit/contract/report）
2. 角色权限矩阵与路由 guard
3. 商机 Kanban 状态同步方案
4. SQLite ER 图（≥12 表）
5. 报表聚合 SQL 思路
6. Web 端 Kanban 拖拽实现要点
