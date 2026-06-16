import Foundation
import SwiftData

// MARK: - 枚举定义

/// 人员角色大类（可多选：一个人可以同时是法官和前律师等）
enum PersonRoleType: String, Codable, CaseIterable, Identifiable {
    case judge = "法官"
    case prosecutor = "检察官"
    case lawyer = "律师"
    case party = "当事人"
    case police = "公安民警"
    case witness = "证人"
    case clerk = "书记员"
    case expert = "鉴定人"
    case other = "其他"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .judge:       return "hammer.fill"
        case .prosecutor:  return "building.columns.fill"
        case .lawyer:      return "briefcase.fill"
        case .party:       return "person.fill"
        case .police:      return "shield.fill"
        case .witness:     return "eye.fill"
        case .clerk:       return "doc.text.fill"
        case .expert:      return "flask.fill"
        case .other:       return "person.crop.circle"
        }
    }

    var colorHex: String {
        switch self {
        case .judge:       return "#D32F2F"  // 深红
        case .prosecutor:  return "#1976D2"  // 深蓝
        case .lawyer:      return "#388E3C"  // 深绿
        case .party:       return "#F57C00"  // 橙色
        case .police:      return "#512DA8"  // 紫色
        case .witness:     return "#00796B"  // 青色
        case .clerk:       return "#5D4037"  // 棕色
        case .expert:      return "#C2185B"  // 粉色
        case .other:       return "#616161"  // 灰色
        }
    }
}

/// 案件类型
enum CaseType: String, Codable, CaseIterable, Identifiable {
    case criminal = "刑事"
    case civil = "民事"
    case administrative = "行政"
    case arbitration = "仲裁"
    case nonLitigation = "非诉"

    var id: String { rawValue }
    var systemImage: String {
        switch self {
        case .criminal:       return "gavel.fill"
        case .civil:          return "doc.text.fill"
        case .administrative: return "building.2.fill"
        case .arbitration:    return "hand.raised.fill"
        case .nonLitigation:  return "checkmark.seal.fill"
        }
    }
}

/// 案件状态
enum CaseStatus: String, Codable, CaseIterable, Identifiable {
    case consulting = "洽谈中"
    case retained = "已委托"
    case filing = "立案中"
    case inTrial = "审理中"
    case mediated = "已调解"
    case judged = "已判决"
    case enforcing = "执行中"
    case closed = "已结案"
    case appealed = "已上诉"

    var id: String { rawValue }

    /// 是否属于"进行中"状态
    var isActive: Bool {
        switch self {
        case .consulting, .retained, .filing, .inTrial, .enforcing, .appealed:
            return true
        case .mediated, .judged, .closed:
            return false
        }
    }
}

/// 案件重要日期类型
enum CaseEventType: String, Codable, CaseIterable, Identifiable {
    case trial = "开庭"
    case evidenceDeadline = "举证期限"
    case mediation = "调解"
    case sentencing = "宣判"
    case clientMeeting = "会见当事人"
    case documentDue = "文书截止"
    case other = "其他"

    var id: String { rawValue }
    var systemImage: String {
        switch self {
        case .trial:            return "mic.fill"
        case .evidenceDeadline:  return "clock.badge.exclamationmark"
        case .mediation:         return "handshake"
        case .sentencing:        return "hammer.fill"
        case .clientMeeting:    return "person.2.fill"
        case .documentDue:      return "doc.badge.clock"
        case .other:            return "calendar"
        }
    }
}

/// 文书类型
enum DocumentType: String, Codable, CaseIterable, Identifiable {
    case complaint = "起诉状"
    case defense = "答辩状"
    case evidence = "证据材料"
    case judgment = "判决书"
    case ruling = "裁定书"
    case mediationAgreement = "调解书"
    case contract = "合同"
    case legalOpinion = "法律意见书"
    case correspondence = "往来函件"
    case other = "其他"

    var id: String { rawValue }
}


// MARK: - SwiftData 模型

/// 标签
@Model
final class Tag {
    var name: String
    var colorHex: String

    /// 反向关系：打此标签的人
    @Relationship(inverse: \Person.tags)
    var persons: [Person] = []

    init(name: String, colorHex: String = "#666666") {
        self.name = name
        self.colorHex = colorHex
    }
}

/// 人脉
@Model
final class Person {
    // 基本信息
    var name: String
    var pinyin: String          // 拼音全拼（用于搜索，如 "zhangsan"）
    var pinyinInitials: String  // 拼音首字母（如 "zs"）

    /// 角色类型（可多选），存为 JSON 字符串数组
    var _roleTypesJSON: String = "[]"
    var roleTypes: [PersonRoleType] {
        get { Self.decodeJSON(_roleTypesJSON) ?? [] }
        set { if let data = try? JSONEncoder().encode(newValue),
               let str = String(data: data, encoding: .utf8) { _roleTypesJSON = str } }
    }

    var org: String?             // 单位
    var orgDepartment: String?   // 部门/庭室（如 "民二庭"）
    var title: String?           // 职务/职称

    // 联系方式
    var phone: String?
    var phone2: String?
    var email: String?
    var wechat: String?
    var address: String?

    // 备注
    var notes: String?
    var importance: Int = 3      // 重要程度 1-5

    // 头像
    @Attribute(.externalStorage)
    var avatarData: Data?

    // 关联
    @Relationship(deleteRule: .nullify)
    var tags: [Tag] = []

    @Relationship(deleteRule: .cascade, inverse: \CasePerson.person)
    var casePersons: [CasePerson] = []

    // 元数据
    var isArchived: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    // MARK: 唯一约束
    // 用 name+org 的组合作为去重参考（律师可能需要"张法官（XX法院）"这种区分）
    var uniqueKey: String {
        [name, org].compactMap { $0 }.joined(separator: "|")
    }

    init(
        name: String,
        roleTypes: [PersonRoleType] = [],
        org: String? = nil,
        orgDepartment: String? = nil,
        title: String? = nil,
        phone: String? = nil,
        email: String? = nil,
        wechat: String? = nil,
        notes: String? = nil,
        importance: Int = 3
    ) {
        self.name = name
        self.pinyin = name.toPinyin()
        self.pinyinInitials = name.toPinyinInitials()
        self._roleTypesJSON = ""
        defer { self.roleTypes = roleTypes }
        self.org = org
        self.orgDepartment = orgDepartment
        self.title = title
        self.phone = phone
        self.email = email
        self.wechat = wechat
        self.notes = notes
        self.importance = importance
    }

    // MARK: - 查询辅助

    /// 该人在各个角色大类下的案件关联（用于分组展示）
    var casesByRole: [(PersonRoleType, [CasePerson])] {
        let grouped = Dictionary(grouping: casePersons) { $0.roleCategory }
        return PersonRoleType.allCases.compactMap { roleType in
            guard let items = grouped[roleType], !items.isEmpty else { return nil }
            return (roleType, items.sorted { $0.sortOrder < $1.sortOrder })
        }
    }

    /// 参与的案件总数
    var caseCount: Int { casePersons.count }

    /// 参与的案件（去重）
    var cases: [Case] {
        Array(Set(casePersons.compactMap { $0.case }))
    }

    // MARK: - JSON 编解码工具

    static func decodeJSON<T: Decodable>(_ json: String) -> T? {
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}

/// 案件
@Model
final class Case {
    // 基本信息
    var name: String
    var caseNumber: String?       // 如 "(2026)京0105民初12345号"

    var _caseTypeRaw: String = CaseType.civil.rawValue
    var caseType: CaseType {
        get { CaseType(rawValue: _caseTypeRaw) ?? .civil }
        set { _caseTypeRaw = newValue.rawValue }
    }

    var court: String?            // 管辖法院/仲裁机构

    var _caseStatusRaw: String = CaseStatus.consulting.rawValue
    var caseStatus: CaseStatus {
        get { CaseStatus(rawValue: _caseStatusRaw) ?? .consulting }
        set { _caseStatusRaw = newValue.rawValue }
    }

    // 日期
    var filingDate: Date?         // 立案日期
    var closingDate: Date?        // 结案日期

    // 金额
    var subjectAmount: Double?    // 标的额
    var feeAmount: Double?        // 律师费

    // 内容
    var summary: String?          // 案件摘要
    var result: String?           // 判决结果
    var notes: String?            // 私有备注

    // 关联
    @Relationship(deleteRule: .cascade, inverse: \CasePerson.case)
    var casePersons: [CasePerson] = []

    @Relationship(deleteRule: .cascade, inverse: \CaseEvent.case)
    var events: [CaseEvent] = []

    @Relationship(deleteRule: .cascade, inverse: \CaseDocument.case)
    var documents: [CaseDocument] = []

    // 元数据
    var isArchived: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(
        name: String,
        caseType: CaseType = .civil,
        caseNumber: String? = nil,
        court: String? = nil,
        caseStatus: CaseStatus = .consulting,
        filingDate: Date? = nil,
        closingDate: Date? = nil,
        subjectAmount: Double? = nil,
        feeAmount: Double? = nil,
        summary: String? = nil,
        notes: String? = nil
    ) {
        self.name = name
        self.caseNumber = caseNumber
        self._caseTypeRaw = caseType.rawValue
        self.court = court
        self._caseStatusRaw = caseStatus.rawValue
        self.filingDate = filingDate
        self.closingDate = closingDate
        self.subjectAmount = subjectAmount
        self.feeAmount = feeAmount
        self.summary = summary
        self.notes = notes
    }

    // MARK: - 查询辅助

    /// 案件参与人按角色大类和具体角色分组
    /// 返回结构：[(角色大类, [(具体角色, [CasePerson])])]
    var personsByRole: [(PersonRoleType, [(role: String, persons: [CasePerson])])] {
        let grouped = Dictionary(grouping: casePersons) { $0.roleCategory }
        return PersonRoleType.allCases.compactMap { roleType in
            guard let items = grouped[roleType], !items.isEmpty else { return nil }
            let bySpecificRole = Dictionary(grouping: items) { $0.role }
                .sorted { $0.key < $1.key }
                .map { (role: $0.key, persons: $0.value.sorted { $0.sortOrder < $1.sortOrder }) }
            return (roleType, bySpecificRole)
        }
    }

    /// 参与人总数
    var personCount: Int { casePersons.count }

    /// 所有参与人
    var allPersons: [Person] {
        casePersons.compactMap { $0.person }
    }

    /// 按角色大类获取参与人
    func persons(of roleType: PersonRoleType) -> [Person] {
        casePersons.filter { $0.roleCategory == roleType }.compactMap { $0.person }
    }

    /// 最近的重要日期
    var nextEvent: CaseEvent? {
        events
            .filter { !$0.isCompleted && $0.date > Date() }
            .min { $0.date < $1.date }
    }
}

/// 案件-人关联（枢纽表，实现多对多）
@Model
final class CasePerson {
    var role: String              // 在本案中的具体角色（如"审判长""原告代理人"）

    var _roleCategoryRaw: String?
    var roleCategory: PersonRoleType? {
        get {
            guard let raw = _roleCategoryRaw else { return nil }
            return PersonRoleType(rawValue: raw)
        }
        set { _roleCategoryRaw = newValue?.rawValue }
    }

    var note: String?             // 备注（如"中途更换"）
    var sortOrder: Int = 0
    var joinedAt: Date? = Date()

    // 关系（删除 CasePerson 不影响 Person 和 Case）
    var person: Person?
    var case: Case?

    init(person: Person? = nil, case: Case? = nil, role: String, roleCategory: PersonRoleType? = nil, note: String? = nil, sortOrder: Int = 0) {
        self.person = person
        self.case = case
        self.role = role
        self.roleCategory = roleCategory
        self.note = note
        self.sortOrder = sortOrder
    }
}

/// 案件重要日期
@Model
final class CaseEvent {
    var title: String
    var _eventTypeRaw: String = CaseEventType.other.rawValue
    var eventType: CaseEventType {
        get { CaseEventType(rawValue: _eventTypeRaw) ?? .other }
        set { _eventTypeRaw = newValue.rawValue }
    }
    var date: Date
    var isAllDay: Bool = true
    var note: String?
    var shouldRemind: Bool = false
    var reminderOffset: TimeInterval?  // 提前秒数（如 86400 = 提前一天）
    var isCompleted: Bool = false
    var completedAt: Date?

    var case: Case?

    init(title: String, eventType: CaseEventType = .other, date: Date, note: String? = nil, shouldRemind: Bool = false, case: Case? = nil) {
        self.title = title
        self._eventTypeRaw = eventType.rawValue
        self.date = date
        self.note = note
        self.shouldRemind = shouldRemind
        self.case = case
    }
}

/// 案件文书（可选模块）
@Model
final class CaseDocument {
    var title: String
    var _documentTypeRaw: String = DocumentType.other.rawValue
    var documentType: DocumentType {
        get { DocumentType(rawValue: _documentTypeRaw) ?? .other }
        set { _documentTypeRaw = newValue.rawValue }
    }
    var fileURL: URL?             // 本地文件路径
    var fileSize: Int64?
    var addedAt: Date = Date()
    var note: String?

    var case: Case?

    init(title: String, documentType: DocumentType = .other, fileURL: URL? = nil, case: Case? = nil) {
        self.title = title
        self._documentTypeRaw = documentType.rawValue
        self.fileURL = fileURL
        self.case = case
    }
}


// MARK: - 拼音扩展（中文搜索支持）

import SwiftUI  // 仅用于平台判断，实际拼音转换需要 Foundation 或第三方库

extension String {
    /// 转拼音全拼（需要 CFStringTransform 或引入拼音库）
    /// 这里给出 CFStringTransform 方案
    func toPinyin() -> String {
        let mutable = NSMutableString(string: self)
        CFStringTransform(mutable, nil, kCFStringTransformToLatin, false)
        CFStringTransform(mutable, nil, kCFStringTransformStripDiacritics, false)
        return (mutable as String)
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
    }

    /// 取拼音首字母
    func toPinyinInitials() -> String {
        toPinyin()
            .split(separator: " ")
            .compactMap { $0.first }
            .map(String.init)
            .joined()
            .lowercased()
    }
}


// MARK: - 预设数据（用于开发和预览）

enum PreviewData {
    static func makeSampleData(container: ModelContainer) {
        let context = container.mainContext

        // 创建标签
        let vipTag = Tag(name: "重要", colorHex: "#D32F2F")
        let regularTag = Tag(name: "普通", colorHex: "#1976D2")
        let newTag = Tag(name: "新结识", colorHex: "#388E3C")

        context.insert(vipTag)
        context.insert(regularTag)
        context.insert(newTag)

        // 创建人脉
        let judge = Person(
            name: "张建国",
            roleTypes: [.judge],
            org: "北京市朝阳区人民法院",
            orgDepartment: "民二庭",
            title: "审判长",
            phone: "010-8888XXXX",
            notes: "审理风格偏保守，重视证据链完整性",
            importance: 5
        )
        judge.tags = [vipTag]

        let prosecutor = Person(
            name: "李明",
            roleTypes: [.prosecutor],
            org: "北京市朝阳区人民检察院",
            orgDepartment: "公诉部"
        )
        prosecutor.tags = [regularTag]

        let client = Person(
            name: "王强",
            roleTypes: [.party],
            phone: "138XXXXYYYY",
            notes: "XX公司法人代表",
            importance: 5
        )
        client.tags = [vipTag, newTag]

        let opposingLawyer = Person(
            name: "刘芳",
            roleTypes: [.lawyer],
            org: "君合律师事务所",
            phone: "139XXXXZZZZ",
            notes: "擅长合同法，庭审风格强势"
        )
        opposingLawyer.tags = [regularTag]

        let police = Person(
            name: "陈刚",
            roleTypes: [.police],
            org: "朝阳分局经侦支队"
        )

        let clerk = Person(
            name: "赵小燕",
            roleTypes: [.clerk],
            org: "北京市朝阳区人民法院",
            orgDepartment: "民二庭"
        )

        [judge, prosecutor, client, opposingLawyer, police, clerk].forEach {
            context.insert($0)
        }

        // 创建案件
        let case1 = Case(
            name: "XX公司股权转让纠纷案",
            caseType: .civil,
            caseNumber: "(2026)京0105民初12345号",
            court: "北京市朝阳区人民法院",
            caseStatus: .inTrial,
            filingDate: Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 15)),
            subjectAmount: 5_000_000,
            notes: "标的额较大，需要重点关注证据保全"
        )

        let case2 = Case(
            name: "XX公司合同诈骗案",
            caseType: .criminal,
            caseNumber: "(2025)京0105刑初6789号",
            court: "北京市朝阳区人民法院",
            caseStatus: .judged,
            filingDate: Calendar.current.date(from: DateComponents(year: 2025, month: 8, day: 1)),
            closingDate: Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 20)),
            result: "被告判三缓四，退赔全部款项",
            notes: "已结案，当事人满意"
        )

        context.insert(case1)
        context.insert(case2)

        // 创建关联
        let cp1 = CasePerson(person: judge, case: case1, role: "审判长", roleCategory: .judge, sortOrder: 1)
        let cp2 = CasePerson(person: clerk, case: case1, role: "书记员", roleCategory: .clerk, sortOrder: 2)
        let cp3 = CasePerson(person: client, case: case1, role: "原告（我方当事人）", roleCategory: .party, sortOrder: 3)
        let cp4 = CasePerson(person: opposingLawyer, case: case1, role: "被告代理人", roleCategory: .lawyer, sortOrder: 4)

        let cp5 = CasePerson(person: judge, case: case2, role: "审判长", roleCategory: .judge, sortOrder: 1)
        let cp6 = CasePerson(person: prosecutor, case: case2, role: "公诉人", roleCategory: .prosecutor, sortOrder: 2)
        let cp7 = CasePerson(person: police, case: case2, role: "侦查人员", roleCategory: .police, sortOrder: 3)

        [cp1, cp2, cp3, cp4, cp5, cp6, cp7].forEach { context.insert($0) }

        // 创建重要日期
        let trialDate = Calendar.current.date(from: DateComponents(year: 2026, month: 7, day: 15, hour: 9, minute: 30))!
        let event1 = CaseEvent(title: "第四次开庭", eventType: .trial, date: trialDate, shouldRemind: true, case: case1)

        let deadlineDate = Calendar.current.date(from: DateComponents(year: 2026, month: 6, day: 30, hour: 17, minute: 0))!
        let event2 = CaseEvent(title: "补充证据截止日", eventType: .evidenceDeadline, date: deadlineDate, shouldRemind: true, case: case1)

        context.insert(event1)
        context.insert(event2)

        try? context.save()
    }
}


// MARK: - 查询服务示例

/// 全局搜索服务
@MainActor
final class SearchService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// 全局搜索：同时搜人和案件
    func search(query: String) -> (persons: [Person], cases: [Case]) {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return ([], []) }
        let q = query.lowercased()

        // 搜人：名字 / 拼音 / 拼音首字母 / 单位
        let personDescriptor = FetchDescriptor<Person>(
            predicate: #Predicate { person in
                person.name.localizedStandardContains(q) ||
                person.pinyin.contains(q) ||
                person.pinyinInitials.contains(q) ||
                (person.org?.localizedStandardContains(q) ?? false)
            },
            sortBy: [SortDescriptor(\.importance, order: .reverse), SortDescriptor(\.name)]
        )

        // 搜案件：名称 / 案号 / 法院
        let caseDescriptor = FetchDescriptor<Case>(
            predicate: #Predicate { c in
                c.name.localizedStandardContains(q) ||
                (c.caseNumber?.localizedStandardContains(q) ?? false) ||
                (c.court?.localizedStandardContains(q) ?? false)
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )

        do {
            let persons = try modelContext.fetch(personDescriptor)
            let cases = try modelContext.fetch(caseDescriptor)
            return (persons, cases)
        } catch {
            print("搜索失败: \(error)")
            return ([], [])
        }
    }

    /// 搜索联系人（用于案件添加参与人时的补全）
    func searchPersons(query: String) -> [Person] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        let q = query.lowercased()

        let descriptor = FetchDescriptor<Person>(
            predicate: #Predicate { person in
                person.name.localizedStandardContains(q) ||
                person.pinyin.contains(q) ||
                person.pinyinInitials.contains(q)
            },
            sortBy: [SortDescriptor(\.name)]
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// 获取某人的所有案件（按角色类型分组）
    func casesForPerson(_ person: Person) -> [(PersonRoleType, [CasePerson])] {
        person.casesByRole
    }

    /// 获取某案的所有参与人（按角色大类分组）
    func personsForCase(_ case: Case) -> [(PersonRoleType, [(role: String, persons: [CasePerson])])] {
        `case`.personsByRole
    }

    /// 活跃案件列表
    func activeCases() -> [Case] {
        let descriptor = FetchDescriptor<Case>(
            predicate: #Predicate { c in
                !c.isArchived
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// 按角色类型筛选人脉
    func personsByRole(_ roleType: PersonRoleType) -> [Person] {
        let rawValue = roleType.rawValue
        let descriptor = FetchDescriptor<Person>(
            predicate: #Predicate { person in
                person._roleTypesJSON.contains(rawValue)
            },
            sortBy: [SortDescriptor(\.name)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
}


// MARK: - SwiftData 容器配置

extension ModelContainer {
    /// 创建应用使用的 ModelContainer
    static var appContainer: ModelContainer {
        do {
            let schema = Schema([Person.self, Case.self, CasePerson.self, CaseEvent.self, CaseDocument.self, Tag.self])
            let config = ModelConfiguration(
                "CaseNetwork",
                cloudKitDatabase: .automatic  // 自动启用 CloudKit
            )
            let container = try ModelContainer(for: schema, configurations: config)

            // 首次启动时插入示例数据（调试用）
            // PreviewData.makeSampleData(container: container)

            return container
        } catch {
            fatalError("无法创建 ModelContainer: \(error.localizedDescription)")
        }
    }

    /// 仅本地存储（调试/不使用 iCloud 时）
    static var localContainer: ModelContainer {
        do {
            let schema = Schema([Person.self, Case.self, CasePerson.self, CaseEvent.self, CaseDocument.self, Tag.self])
            let config = ModelConfiguration("CaseNetwork-local")
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("无法创建本地 ModelContainer: \(error.localizedDescription)")
        }
    }
}
