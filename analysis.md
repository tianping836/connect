# 案件人脉管理 App — 完整分析

> 写于 2026-06-15 | 军哥的 iOS/macOS 个人开发项目

---

## 一、竞品与市场

### 1.1 WOLB（直接竞品）

- 官网：https://www.w-o-l-b.com/downloadApp/
- 开发方：北京畅效科技
- 当前版本：V1.8.5
- 定位：人脉管理 + 事件日历提醒
- 核心功能：人脉管理（标签/群组/模板）、事件模块（参与人关联/纪要/待办）、日历视图、互动追溯
- 加密：用户个人密钥端到端加密、离线可用、多端同步
- 不足：**关联是单向的**（人→事件），不支持你需要的多对多交叉查询（从法官反查所有案件、从案件看全部参与人的角色分布）

### 1.2 其他相关产品

| 产品 | 优势 | 劣势 |
|------|------|------|
| **飞书多维表格** | 关联列、双向引用、多视图 | 不是专为律师设计，太重，数据在云端 |
| **Notion** | 灵活数据库、Relation 属性 | 同上，且国内访问不稳定 |
| **Airtable** | 关联记录、多视图 | 英文、贵、云端 |
| **Day One / 格志** | 日记/事件记录 | 无关联系统 |
| **OmniFocus / Things** | 任务管理 | 无人物关联 |
| **LexisNexis / 威科先行** | 法律专业数据库 | 不管理人脉 |

### 1.3 市场空白

**没有人做"律师个人案件-人脉交叉管理"这个细分**。大厂做通用工具（飞书/Notion），小厂做泛人脉（WOLB），专业法律工具做案例库不做个人管理。你的机会就在这个交叉点。

---

## 二、需求定义

### 2.1 核心用例（User Stories）

#### 人脉管理
- 添加/编辑/删除/搜索联系人
- 每个人有：姓名、角色类型（可多选：法官/检察官/律师/当事人/公安民警/证人/其他）、单位/机构、联系方式（电话/微信/邮箱）、标签、备注
- 按角色类型、标签、单位筛选
- 点击某人 → 看到 ta 参与的所有案件（按角色分组）

#### 案件管理
- 创建/编辑/删除/搜索案件
- 每个案件有：案件名称、案号、案件类型（刑事/民事/行政/仲裁/非诉）、管辖法院/机构、立案日期、当前状态、案件摘要、判决/结果、备注
- 从人脉中**选择/搜索添加**参与人，并指定在该案中的角色
- 点击某案 → 看到全部参与人（按角色分组：法官、检察官、对方律师、当事人…）

#### 交叉查询
- **从人查案**：打开"张法官" → 看到审理过的 15 个案件，按时间/类型排列
- **从案查人**：打开"XX合同纠纷案" → 看到法官、书记员、对方律师、当事人，每个人可点击跳转
- **全局搜索**：输入关键字 → 同时搜人+搜案，结果分两类展示
- **智能补全**：在案件中添加参与人时，输入前两个字 → 下拉匹配已有联系人

#### 日历与提醒
- 案件关联日期（开庭日期、举证期限、判决日期等）
- 日历视图（日/周/月）
- 到期提醒推送

#### 数据安全
- 本地优先存储，所有数据在设备上
- 可选 iCloud 同步（端到端加密）
- 应用锁（Face ID / Touch ID）
- 不经过第三方服务器

### 2.2 不做的事（V1 排除）

- 团队协作/多人共享（先做个人版）
- 法律文书 OCR/AI 分析（V2 考虑）
- Android / Web 端（先 Apple 全平台）
- 对接法院公开数据
- 计费/订阅系统（先自己用）

---

## 三、数据模型设计

### 3.1 核心实体

```
Person（人） 1 ←→ N CasePerson N ←→ 1 Case（案件）
```

加上辅助实体：

```
Person ──< CasePerson >── Case
         ├── role: String        ("主审法官" / "代理人" / "当事人" / "公诉人"...)
         ├── note: String?
         └── sortOrder: Int

Person ──< PersonTag (多对多标签)

Case ──< CaseEvent (案件重要日期)
      ├── date: Date
      ├── type: 开庭/举证期限/宣判/调解/...
      └── note: String?

Case ──< CaseDocument (案件文书，可选)
      ├── title: String
      ├── fileURL: URL
      └── type: 起诉状/判决书/证据/...
```

### 3.2 各实体字段详设

**Person**
```
id: UUID
name: String                    // 姓名
pinyin: String?                 // 拼音（搜索排序用）
roleTypes: [PersonRoleType]     // 角色标签，可多选
  - 法官 judge
  - 检察官 prosecutor
  - 律师 lawyer
  - 当事人 party
  - 公安民警 police
  - 证人 witness
  - 书记员 clerk
  - 其他 other
org: String?                    // 单位/机构
orgDepartment: String?          // 部门/庭室
phone: String?
email: String?
wechat: String?
address: String?
tags: [Tag]                     // 自定义标签
avatar: Data?                   // 头像
notes: String?                  // 备注
importance: Int                 // 重要程度 1-5
createdAt: Date
updatedAt: Date
isArchived: Bool
```

**Case**
```
id: UUID
name: String                    // 案件名称
caseNumber: String?             // 案号 (如 (2026)京0105民初12345号)
caseType: CaseType              
  - 刑事 criminal
  - 民事 civil
  - 行政 administrative
  - 仲裁 arbitration
  - 非诉 nonLitigation
court: String?                  // 管辖法院/机构
caseStatus: CaseStatus
  - 洽谈中 consulting
  - 已委托 retained
  - 立案中 filing
  - 审理中 inTrial
  - 已调解 mediated
  - 已判决 judged
  - 执行中 enforcing
  - 已结案 closed
  - 已上诉 appealed
filingDate: Date?               // 立案日期
closingDate: Date?              // 结案日期
summary: String?                // 案件摘要
result: String?                 // 判决/结果
feeAmount: Decimal?             // 律师费
notes: String?                  // 备注
isArchived: Bool
createdAt: Date
updatedAt: Date
```

**CasePerson（关联枢纽）**
```
id: UUID
person: Person                  // → 关联的人
case: Case                      // → 关联的案件
role: String                    // 在本案中的具体角色
                                // 如"审判长""原告代理人""被告人""证人"
roleCategory: PersonRoleType?   // 角色大类（方便分组）
note: String?                   // 备注（如"更换过代理人"）
sortOrder: Int                  // 排序
joinedAt: Date?                 // 加入案件日期
```

**CaseEvent（重要日期）**
```
id: UUID
case: Case
title: String
eventType: CaseEventType
  - 开庭 trial
  - 举证期限 evidenceDeadline
  - 调解 mediation
  - 宣判 sentencing
  - 会见 clientMeeting
  - 其他 other
date: Date
isAllDay: Bool
note: String?
reminder: Bool                  // 是否提醒
reminderOffset: TimeInterval?   // 提前多久提醒
isCompleted: Bool
```

**Tag**
```
id: UUID
name: String
color: String                   // 标签颜色 hex
```

### 3.3 关键查询

```
// 查一个人的所有案件（按角色大类分组）
Person.casePersons → CasePerson[] → 按 roleCategory 分组 → 
  { judge: [CasePerson], prosecutor: [CasePerson], ... }

// 查一个案件的所有参与人（按角色分组）
Case.casePersons → CasePerson[] → 按 roleCategory 分组 →
  { judge: [Person], party: [Person], lawyer: [Person], ... }

// 全局搜索
搜索 "张三" → 
  - Person.name CONTAINS "张三"
  - Case.name CONTAINS "张三" 
  - (未来) Case.notes CONTAINS "张三"
```

---

## 四、UI 设计（页面清单）

### 4.1 主结构：Tab Bar（iOS）/ Sidebar（iPad & Mac）

```
📋 案件    👥 人脉    📅 日历    ⚙️ 设置
```

### 4.2 各页面详情

#### TAB 1：案件列表
- 列表视图，按状态分段（进行中/已结案）
- 每行显示：案件名、案号、参与人数、最近日期、状态标签
- 支持搜索、筛选（类型/状态/法院/日期范围）
- 右上角 + 按钮新建案件
- 点击 → 案件详情页

#### 案件详情页
- 基本信息区（可编辑）
- **参与人列表**：按角色大类分组显示（效果最接近飞书关联列）
  - 显示：人名、角色、单位
  - 点击人名 → 跳转该人详情页
  - 右上角"添加参与人"按钮 → 搜索补全弹窗
  - 已添加的参与人，其名字是**可点击链接**
- **重要日期时间线**
- **附件/文书**区域（可选）
- **笔记/备忘**区域

#### 添加参与人弹窗（核心交互）
- 搜索框（输入即搜索已有联系人）
- 搜索结果下拉（实时过滤）
- 点击结果 → 选择角色 → 确认添加
- 如果搜不到 → "新建联系人"快捷入口

#### TAB 2：人脉列表
- 列表/网格切换
- 按角色类型、标签筛选
- 搜索（支持拼音首字母）
- 每行：头像、姓名、角色标签、关联案件数
- 点击 → 人脉详情页

#### 人脉详情页
- 基本信息区
- **关联案件列表**（核心）：按角色分组，显示案件名+案号+在本案角色
  - 每个案件可点击跳转
  - 显示案件状态标签
- 按时间/类型排序
- 联系记录/备注

#### TAB 3：日历
- 月视图为主，周视图为辅
- 显示案件重要日期（开庭等）
- 点击日期 → 当天事件列表
- 日期用不同颜色区分事件类型

#### TAB 4：设置
- iCloud 同步开关
- 数据导出/导入
- 外观（深色/浅色/跟随系统）
- 应用锁（Face ID）
- 关于

### 4.3 需要特别打磨的交互

| 交互 | 说明 |
|------|------|
| **关联选择器** | 在案件中添加参与人时的搜索+选择弹窗，这是使用频率最高的交互 |
| **交叉跳转** | 案件→人、人→案件的导航要流畅，有返回路径，不迷路 |
| **角色分组** | 人和案件的详情页都要按角色分组展示关联，这是"飞书关联列"体验的关键 |
| **全局搜索** | 一个搜索框同时搜人+搜案件，结果分两类，高亮匹配文字 |
| **拼音搜索** | 中文输入支持拼音首字母（如"ZS"匹配"张三"） |

---

## 五、技术架构

### 5.1 整体架构

```
┌─────────────────────────────────────────┐
│               SwiftUI Views              │
│  CaseListView / PersonListView / ...    │
├─────────────────────────────────────────┤
│           ViewModel / @Observable        │
│  CaseStore / PersonStore / SearchStore  │
├─────────────────────────────────────────┤
│              SwiftData                   │
│  @Model Person / Case / CasePerson / ...│
├─────────────────────────────────────────┤
│    CloudKit / CoreData (SwiftData 自动)   │
│        本地 SQLite + iCloud 同步          │
└─────────────────────────────────────────┘
```

### 5.2 技术选型理由

| 选项 | 选型 | 理由 |
|------|------|------|
| UI 框架 | SwiftUI | Apple 全平台原生，一套代码 iOS/iPadOS/macOS |
| 数据层 | SwiftData | iOS 17+ 原生 ORM，自动 CloudKit 同步，无需后端 |
| 云同步 | CloudKit | Apple 免费额度（个人开发者足够），端到端加密，零运维 |
| 最低系统 | iOS 17 / macOS 14 | SwiftData 的硬性要求，覆盖主流活跃设备 |
| 搜索 | Swift Predicate + 自建拼音索引 | SwiftData 原生查询 + 内存拼音首字母索引加速 |
| 加密 | iOS Data Protection + 可选应用层 AES | 双重保障律师数据安全 |
| 推送 | UserNotifications + 本地通知 | 无需服务器，开庭提醒全部本地触发 |

### 5.3 不需要的东西（降低复杂度）

- ❌ 不需要后端服务器（纯本地 + CloudKit）
- ❌ 不需要数据库服务器
- ❌ 不需要用户注册/登录系统
- ❌ 不需要支付系统（V1）
- ❌ 不需要 WebRTC / 音视频
- ❌ 不需要第三方 AI API（V1）

---

## 六、开发路线图

### Phase 0：原型验证（1-2 周，现在就可以开始）
- [ ] 用 Notion/飞书多维表格搭建数据原型，录入 10+ 案件+30+ 人
- [ ] 验证数据模型是否顺手，字段是否够用
- [ ] 体验关联列交互，确认这就是你想要的
- [ ] 调整字段和模型

### Phase 1：核心 MVP（6-8 周）
- [ ] Xcode 项目初始化（iOS target）
- [ ] SwiftData 数据模型实现
- [ ] 人脉 CRUD 完整功能
- [ ] 案件 CRUD 完整功能
- [ ] 人→案件、案件→人 关联的创建和展示
- [ ] 添加参与人时的搜索补全弹窗
- [ ] 全局搜索
- [ ] 基础列表 UI（非最终设计，能跑就行）

### Phase 2：交互打磨（3-4 周）
- [ ] 角色分组展示（案件详情页参与人按角色分组）
- [ ] 交叉跳转流畅性（不丢导航上下文）
- [ ] 拼音搜索
- [ ] UI 美化（图标、间距、动效）
- [ ] 深色模式

### Phase 3：日历与提醒（2-3 周）
- [ ] 日历视图（月/周）
- [ ] 开庭/举证等日期的创建和展示
- [ ] 本地推送通知
- [ ] 日期和案件的双向关联

### Phase 4：iPad 适配（2-3 周）
- [ ] NavigationSplitView（双栏/三栏布局）
- [ ] 横屏优化
- [ ] 键盘快捷键

### Phase 5：macOS 适配（2-3 周）
- [ ] macOS target
- [ ] 菜单栏
- [ ] 窗口尺寸适配
- [ ] 拖放支持

### Phase 6：同步与安全（2-3 周）
- [ ] CloudKit 同步配置
- [ ] 多设备同步测试
- [ ] 应用锁（Face ID / Touch ID）
- [ ] 数据导出/导入（JSON/CSV）

### Phase 7：上架准备（1-2 周）
- [ ] App Store 截图和描述
- [ ] 隐私政策
- [ ] TestFlight 内测
- [ ] 提交审核

**总周期：如果全职投入，MVP 2-3 月可出，全功能版 5-7 月。**

---

## 七、Swift 代码原型

见同目录 `DataModel.swift`——完整的 SwiftData 数据模型 + 基础 ViewModel。

---

## 八、成本估算

### 个人开发

| 项目 | 金额 |
|------|------|
| Apple Developer Program | ¥688/年（$99） |
| Mac 开发机 | 已有 |
| 测试设备 | 已有 iPhone/iPad |
| 设计资源 | ¥0-3000（SF Symbols 免费 + 可能的图标/插画素材） |
| 服务器 | ¥0（纯本地 + CloudKit 免费额度） |
| **合计** | **¥688-3688/年** |

CloudKit 免费额度（个人开发者）：
- 数据库存储：1 GB → 文字数据完全够用
- 文件存储：100 GB → 文书 PDF 足够
- 数据传输：2 GB/天 → 个人使用绰绰有余

### 外包开发

| 范围 | 市场报价 | 风险 |
|------|---------|------|
| MVP（仅 iOS） | ¥30,000-80,000 | 沟通成本高，后期改需求贵 |
| 全平台完整版 | ¥100,000-300,000 | 质量参差，维护依赖开发者 |
| 设计外包（UI/UX） | ¥5,000-20,000 | 相对可控 |

**强烈建议自己做**。你是律师，业务逻辑在你脑子里，任何外包都无法替代你对需求的理解。技术门槛在这个项目里不高——SwiftUI + SwiftData 的设计目标就是让个人开发者能快速做出原生应用。

---

## 九、商业化考量（未来）

如果 V1 用得好，可以考虑商业化方向：

### 目标用户
- 律师（诉讼律师尤其契合）
- 法务（企业法务管理外部律师/案件）
- 检察官/法官（管理经手案件，但量小）
- 其他需要人-事件交叉管理的职业（猎头、销售、记者...）

### 可能的商业模式

| 模式 | 说明 |
|------|------|
| 免费 + 内购 | 基础功能免费，高级功能（无限案件/云端同步/团队共享）付费 |
| 订阅制 | ¥8-30/月，适合律师付费意愿和能力 |
| 买断制 | ¥68-198 一次性，Apple 全平台通用购买 |
| 团队版 | 律所团队协作版，按人头收费 |

### 竞争壁垒
1. **数据网络效应**：案件和人脉越录越多，迁移成本越高
2. **律师垂直领域深度**：案号格式、法院层级、诉讼流程的状态机，通用工具做不了
3. **数据安全合规**：律师保密义务 → 本地优先存储是刚需，云端产品天然有顾虑

---

## 十、风险与缓解

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|---------|
| 开发周期超出预期 | 高 | 中 | 严格控制 MVP 范围，砍功能而非延时间 |
| SwiftData API 变动 | 低 | 中 | Apple 已稳定，WWDC 后关注 beta |
| iCloud 同步不稳定 | 中 | 高 | 做好冲突处理，提供手动同步+导出 |
| 与其他工作冲突 | 高 | 中 | 设定固定开发时间（每天晚上 2 小时？周末？） |
| 做出来没人用 | 低 | 低 | 你自己就是第一个用户，解决自己的问题 |
| App Store 审核被拒 | 低 | 中 | 隐私政策、数据加密声明准备好 |

---

## 十一、参考资源

### Apple 官方文档 & 教程
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [CloudKit + SwiftData](https://developer.apple.com/documentation/swiftdata/maintaining-a-local-persistent-data-store)
- [SF Symbols](https://developer.apple.com/sf-symbols/) — 免费图标库
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines)

### 开源参考项目
- 搜索 GitHub：`swiftdata crm`、`swiftui contacts app`、`ios lawyer case management`
- [Notes app clone](https://github.com/topics/swiftdata) — 学 SwiftData 基础
- [Reminders clone](https://github.com/topics/swiftui-list) — 学列表交互

### 设计参考
- 飞书多维表格的"关联列"交互（你的核心设计参考）
- Apple 通讯录 App（人脉管理的最简参考）
- Apple 日历 App（日历视图参考）
- Things 3（iOS 精品 To-Do 的交互典范）
- [Mobbin](https://mobbin.com) — 真实 App 截屏库

### 律师行业参考
- 案号格式规范：[《关于人民法院案件案号的若干规定》](https://www.court.gov.cn/)
- 法院层级体系：最高法 → 高院 → 中院 → 基层法院
- 诉讼流程阶段：立案 → 审理 → 判决 → 执行

---

## 十二、立即可以做的 5 件事

1. **打开飞书或 Notion，手动录入 10 个真实案件 + 涉及的 30-50 个人**，用关联列功能模拟交叉查询，感受数据模型是否顺手。这是最便宜的验证方式，花 2-3 小时。
2. **下载 WOLB 用一周**，把真实数据录进去，感受哪里不够用。你在用的过程中会发现更多"这里应该更好"的点。
3. **在 App Store 搜 "legal case management"、"CRM"、"contact manager"**，下载排名前 5 的体验，截图记录好的交互。
4. **打开 Xcode，File → New → Project → iOS App → 勾选 SwiftData**，起个名字跑起来。
5. **决定一个核心原则**：这个 App 的"灵魂特征"是什么？我建议——**"让每一个关联都可见"**。在任何一个页面，都能看到当前实体（人或案件）的所有关联，并且可以一键跳转。

---

*这份文档是一个活的文件。开始开发后，把实际遇到的坑、调整的方案、新的想法都补充进来。*
