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

    /// 降饱和后的角色色（Apple 风格，保持色相、降低饱和度 25-30%）
    var colorHex: String {
        switch self {
        case .judge:       return "#C0392B"
        case .prosecutor:  return "#2C6FAC"
        case .lawyer:      return "#3D7A4B"
        case .party:       return "#D4744A"
        case .police:      return "#5B5096"
        case .witness:     return "#2D7F75"
        case .clerk:       return "#6B5046"
        case .expert:      return "#A8456E"
        case .other:       return "#616161"
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

    var isActive: Bool {
        switch self {
        case .consulting, .retained, .filing, .inTrial, .enforcing, .appealed: return true
        case .mediated, .judged, .closed: return false
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

/// 提醒紧急级别
enum AlertLevel: String, Codable, CaseIterable, Identifiable {
    case reminder = "提醒"
    case critical = "紧急"

    var id: String { rawValue }
    var systemImage: String {
        switch self {
        case .reminder: return "bell.fill"
        case .critical: return "exclamationmark.shield.fill"
        }
    }
}

/// App 人格语调
enum AppTone: String, Codable, CaseIterable, Identifiable {
    case professional = "专业克制"
    case warm = "温暖人性"

    var id: String { rawValue }
    var systemImage: String {
        switch self {
        case .professional: return "text.alignleft"
        case .warm:          return "heart.text.square.fill"
        }
    }
}

/// 渐进式引导里程碑
enum OnboardingMilestone: String, Codable, CaseIterable {
    case firstLaunch = "首次启动"
    case firstCaseAdded = "添加第一个案件"
    case firstPersonAdded = "添加第一个联系人"
    case firstEventAdded = "添加第一个事件"
    case firstHearingAdded = "添加第一个开庭"
    case firstCaseClosed = "结案第一个案件"
    case firstConnectionExplored = "首次查看连接视图"

    var id: String { rawValue }
}

/// 时间线条目统一类型
enum TimelineEntryType {
    case caseEvent(CaseEventType)
    case note

    var systemImage: String {
        switch self {
        case .caseEvent(let t): return t.systemImage
        case .note: return "note.text"
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

/// 事件类型
enum EventType: String, Codable, CaseIterable, Identifiable {
    case meeting = "会议"
    case deadline = "截止日"
    case hearing = "开庭"
    case filing = "立案/递交"
    case research = "调研"
    case travel = "出差"
    case social = "社交"
    case other = "其他"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .meeting:   return "person.2.fill"
        case .deadline:  return "clock.badge.exclamationmark"
        case .hearing:   return "hammer.fill"
        case .filing:    return "doc.text.fill"
        case .research:  return "book.fill"
        case .travel:    return "airplane"
        case .social:    return "bubble.left.and.bubble.right.fill"
        case .other:     return "calendar"
        }
    }

    var colorHex: String {
        switch self {
        case .meeting:   return "#2C6FAC"
        case .deadline:  return "#C0392B"
        case .hearing:   return "#D4744A"
        case .filing:    return "#3D7A4B"
        case .research:  return "#5B5096"
        case .travel:    return "#2D7F75"
        case .social:    return "#A8456E"
        case .other:     return "#616161"
        }
    }
}

/// 事件状态
enum EventStatus: String, Codable, CaseIterable, Identifiable {
    case planned = "计划中"
    case confirmed = "已确认"
    case completed = "已完成"
    case cancelled = "已取消"

    var id: String { rawValue }

    var isActive: Bool {
        switch self {
        case .planned, .confirmed: return true
        case .completed, .cancelled: return false
        }
    }
}

/// 活跃度信号
enum ActivitySignal {
    case active(daysAgo: Int)
    case recent(months: Int)
    case inactive(months: Int)

    var label: String {
        switch self {
        case .active: return "活跃"
        case .recent(let m): return "\(m)月"
        case .inactive(let m): return "\(m)月+"
        }
    }

    var isActive: Bool {
        if case .active = self { return true }
        return false
    }
}

// MARK: - SwiftData 模型

@Model
final class Tag {
    var name: String
    var colorHex: String
    @Relationship(inverse: \Person.tags) var persons: [Person] = []

    init(name: String, colorHex: String = "#666666") {
        self.name = name
        self.colorHex = colorHex
    }
}

@Model
final class Person {
    var name: String
    var pinyin: String
    var pinyinInitials: String
    var _roleTypesJSON: String = "[]"
    var roleTypes: [PersonRoleType] {
        get { Self.decodeJSON(_roleTypesJSON) ?? [] }
        set { if let data = try? JSONEncoder().encode(newValue),
               let str = String(data: data, encoding: .utf8) { _roleTypesJSON = str } }
    }
    var org: String?
    var orgDepartment: String?
    var title: String?
    var phone: String?
    var phone2: String?
    var email: String?
    var wechat: String?
    var address: String?
    var notes: String?
    var importance: Int = 3
    @Attribute(.externalStorage) var avatarData: Data?
    var trustLevelRaw: Int = 0
    @Relationship(deleteRule: .nullify) var tags: [Tag] = []
    @Relationship(deleteRule: .cascade, inverse: \CasePerson.person) var casePersons: [CasePerson] = []
    @Relationship(deleteRule: .cascade, inverse: \EventPerson.person) var eventPersons: [EventPerson] = []
    var isArchived: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var uniqueKey: String { [name, org].compactMap { $0 }.joined(separator: "|") }

    init(name: String, roleTypes: [PersonRoleType] = [], org: String? = nil,
         orgDepartment: String? = nil, title: String? = nil, phone: String? = nil,
         email: String? = nil, wechat: String? = nil, notes: String? = nil, importance: Int = 3) {
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

    var casesByRole: [(PersonRoleType, [CasePerson])] {
        let grouped = Dictionary(grouping: casePersons) { $0.roleCategory }
        return PersonRoleType.allCases.compactMap { roleType in
            guard let items = grouped[roleType], !items.isEmpty else { return nil }
            return (roleType, items.sorted { $0.sortOrder < $1.sortOrder })
        }
    }

    var caseCount: Int { casePersons.count }
    var cases: [Case] { Array(Set(casePersons.compactMap { $0.case })) }
    var eventCount: Int { eventPersons.count }
    var events: [Event] { Array(Set(eventPersons.compactMap { $0.event })) }

    var lastActiveDate: Date? {
        var candidates: [Date] = []
        for cp in casePersons {
            if let c = cp.case {
                candidates.append(c.updatedAt)
                for ce in c.events where ce.date > c.createdAt { candidates.append(ce.date) }
            }
        }
        for ep in eventPersons {
            if let e = ep.event, let date = e.date { candidates.append(date) }
        }
        return candidates.max()
    }

    var activitySignal: ActivitySignal? {
        guard let lastDate = lastActiveDate else { return nil }
        let days = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
        if days <= 30 { return .active(daysAgo: days) }
        else {
            let months = Calendar.current.dateComponents([.month], from: lastDate, to: Date()).month ?? 1
            let m = max(months, 1)
            if days <= 180 { return .recent(months: m) }
            else { return .inactive(months: m) }
        }
    }

    func sharedCases(with other: Person) -> [Case] {
        let myCaseIDs = Set(casePersons.compactMap { $0.case?.persistentModelID })
        return other.cases.filter { myCaseIDs.contains($0.persistentModelID) }
    }

    func sharedEvents(with other: Person) -> [Event] {
        let myEventIDs = Set(eventPersons.compactMap { $0.event?.persistentModelID })
        return other.events.filter { myEventIDs.contains($0.persistentModelID) }
    }

    func earliestInteractionDate(with other: Person) -> Date? {
        let sharedCs = sharedCases(with: other)
        let sharedEs = sharedEvents(with: other)
        var dates: [Date] = sharedCs.map { $0.createdAt }
        dates += sharedEs.compactMap { $0.date }
        return dates.min()
    }

    func latestInteractionDate(with other: Person) -> Date? {
        let sharedCs = sharedCases(with: other)
        let sharedEs = sharedEvents(with: other)
        var dates: [Date] = sharedCs.map { $0.updatedAt }
        dates += sharedEs.compactMap { $0.date }
        return dates.max()
    }

    func interactionFrequency(with other: Person) -> Int {
        let sharedCs = sharedCases(with: other)
        let sharedEs = sharedEvents(with: other)
        let caseEventCount = sharedCs.reduce(0) { $0 + $1.events.count }
        return caseEventCount + sharedEs.count
    }

    func mutualConnectionIDs(with other: Person) -> Set<persistentidentifier> {
        let myConnectedIDs = Set(
            (casePersons.compactMap { $0.case?.allPersons }.flatMap { $0 }.map { $0.persistentModelID }) +
            (eventPersons.compactMap { $0.event?.participants }.flatMap { $0 }.map { $0.persistentModelID })
        )
        let otherConnectedIDs = Set(
            (other.casePersons.compactMap { $0.case?.allPersons }.flatMap { $0 }.map { $0.persistentModelID }) +
            (other.eventPersons.compactMap { $0.event?.participants }.flatMap { $0 }.map { $0.persistentModelID })
        )
        return myConnectedIDs.intersection(otherConnectedIDs)
            .subtracting([persistentModelID, other.persistentModelID])
    }

    static func decodeJSON<t: decodable="">(_ json: String) -> T? {
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}

@Model
final class Case {
    var name: String
    var caseNumber: String?
    var _caseTypeRaw: String = CaseType.civil.rawValue
    var caseType: CaseType {
        get { CaseType(rawValue: _caseTypeRaw) ?? .civil }
        set { _caseTypeRaw = newValue.rawValue }
    }
    var court: String?
    var _caseStatusRaw: String = CaseStatus.consulting.rawValue
    var caseStatus: CaseStatus {
        get { CaseStatus(rawValue: _caseStatusRaw) ?? .consulting }
        set { _caseStatusRaw = newValue.rawValue }
    }
    var filingDate: Date?
    var closingDate: Date?
    var subjectAmount: Double?
    var feeAmount: Double?
    var summary: String?
    var result: String?
    var notes: String?
    @Relationship(deleteRule: .cascade, inverse: \CasePerson.case) var casePersons: [CasePerson] = []
    @Relationship(deleteRule: .cascade, inverse: \CaseEvent.case) var events: [CaseEvent] = []
    @Relationship(deleteRule: .cascade, inverse: \CaseDocument.case) var documents: [CaseDocument] = []
    @Relationship(deleteRule: .cascade, inverse: \CaseNote.case) var caseNotes: [CaseNote] = []
    @Relationship(deleteRule: .cascade, inverse: \EventCase.case) var eventCases: [EventCase] = []
    var isArchived: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(name: String, caseType: CaseType = .civil, caseNumber: String? = nil, court: String? = nil,
         caseStatus: CaseStatus = .consulting, filingDate: Date? = nil, closingDate: Date? = nil,
         subjectAmount: Double? = nil, feeAmount: Double? = nil, summary: String? = nil, notes: String? = nil) {
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
    var personCount: Int { casePersons.count }
    var allPersons: [Person] { casePersons.compactMap { $0.person } }
    func persons(of roleType: PersonRoleType) -> [Person] {
        casePersons.filter { $0.roleCategory == roleType }.compactMap { $0.person }
    }
    var nextEvent: CaseEvent? {
        events.filter { !$0.isCompleted && $0.date > Date() }.min { $0.date < $1.date }
    }
}

@Model
final class CasePerson {
    var role: String
    var _roleCategoryRaw: String?
    var roleCategory: PersonRoleType? {
        get { guard let raw = _roleCategoryRaw else { return nil }; return PersonRoleType(rawValue: raw) }
        set { _roleCategoryRaw = newValue?.rawValue }
    }
    var note: String?
    var sortOrder: Int = 0
    var joinedAt: Date? = Date()
    var person: Person?
    var case: Case?

    init(person: Person? = nil, case: Case? = nil, role: String, roleCategory: PersonRoleType? = nil,
         note: String? = nil, sortOrder: Int = 0) {
        self.person = person; self.case = case; self.role = role
        self.roleCategory = roleCategory; self.note = note; self.sortOrder = sortOrder
    }
}

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
    var reminderOffset: TimeInterval?
    var isCompleted: Bool = false
    var completedAt: Date?
    var case: Case?

    init(title: String, eventType: CaseEventType = .other, date: Date, note: String? = nil,
         shouldRemind: Bool = false, case: Case? = nil) {
        self.title = title; self._eventTypeRaw = eventType.rawValue; self.date = date
        self.note = note; self.shouldRemind = shouldRemind; self.case = case
    }
}

@Model
final class CaseDocument {
    var title: String
    var _documentTypeRaw: String = DocumentType.other.rawValue
    var documentType: DocumentType {
        get { DocumentType(rawValue: _documentTypeRaw) ?? .other }
        set { _documentTypeRaw = newValue.rawValue }
    }
    var fileURL: URL?
    var fileSize: Int64?
    var addedAt: Date = Date()
    var note: String?
    var case: Case?

    init(title: String, documentType: DocumentType = .other, fileURL: URL? = nil, case: Case? = nil) {
        self.title = title; self._documentTypeRaw = documentType.rawValue
        self.fileURL = fileURL; self.case = case
    }
}

@Model
final class CaseNote {
    var title: String
    var content: String
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var timestamp: Date = Date()
    var isPinned: Bool = false
    @Relationship(inverse: \Case.caseNotes) var case: Case?

    init(title: String, content: String, timestamp: Date = Date(), case: Case? = nil, isPinned: Bool = false) {
        self.title = title; self.content = content; self.timestamp = timestamp
        self.case = case; self.isPinned = isPinned
    }
    var timelineEntryType: TimelineEntryType { .note }
}

@Model
final class Event {
    var title: String
    var _eventTypeRaw: String = EventType.other.rawValue
    var eventType: EventType {
        get { EventType(rawValue: _eventTypeRaw) ?? .other }
        set { _eventTypeRaw = newValue.rawValue }
    }
    var _statusRaw: String = EventStatus.planned.rawValue
    var status: EventStatus {
        get { EventStatus(rawValue: _statusRaw) ?? .planned }
        set { _statusRaw = newValue.rawValue }
    }
    var date: Date?
    var endDate: Date?
    var isAllDay: Bool = true
    var location: String?
    var summary: String?
    var notes: String?
    var shouldRemind: Bool = false
    var reminderOffset: TimeInterval?
    var _alertLevelRaw: String = AlertLevel.reminder.rawValue
    var alertLevel: AlertLevel {
        get { AlertLevel(rawValue: _alertLevelRaw) ?? .reminder }
        set { _alertLevelRaw = newValue.rawValue }
    }
    var systemCalendarEventIdentifier: String?
    @Relationship(deleteRule: .cascade, inverse: \EventPerson.event) var eventPersons: [EventPerson] = []
    @Relationship(deleteRule: .cascade, inverse: \EventCase.event) var eventCases: [EventCase] = []
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(title: String, eventType: EventType = .other, status: EventStatus = .planned,
         date: Date? = nil, endDate: Date? = nil, isAllDay: Bool = true, location: String? = nil,
         summary: String? = nil, notes: String? = nil, shouldRemind: Bool = false,
         systemCalendarEventIdentifier: String? = nil) {
        self.title = title; self._eventTypeRaw = eventType.rawValue
        self._statusRaw = status.rawValue; self.date = date; self.endDate = endDate
        self.isAllDay = isAllDay; self.location = location; self.summary = summary
        self.notes = notes; self.shouldRemind = shouldRemind
        self.systemCalendarEventIdentifier = systemCalendarEventIdentifier
    }

    var linkedCases: [Case] { eventCases.compactMap { $0.case } }
    var participants: [Person] { eventPersons.compactMap { $0.person } }
}

@Model
final class EventPerson {
    var role: String = "参与者"
    var person: Person?
    var event: Event?
    var sortOrder: Int = 0
    var note: String?

    init(person: Person? = nil, event: Event? = nil, role: String = "参与者") {
        self.person = person; self.event = event; self.role = role
    }
}

@Model
final class EventCase {
    var event: Event?
    var case: Case?
    var note: String?

    init(event: Event? = nil, case: Case? = nil, note: String? = nil) {
        self.event = event; self.case = case; self.note = note
    }
}

// MARK: - 拼音扩展

extension String {
    func toPinyin() -> String {
        let mutable = NSMutableString(string: self)
        CFStringTransform(mutable, nil, kCFStringTransformToLatin, false)
        CFStringTransform(mutable, nil, kCFStringTransformStripDiacritics, false)
        return (mutable as String).lowercased().replacingOccurrences(of: " ", with: "")
    }

    func toPinyinInitials() -> String {
        toPinyin().split(separator: " ").compactMap { $0.first }.map(String.init).joined().lowercased()
    }
}

// MARK: - 预设数据

enum PreviewData {
    static func makeSampleData(container: ModelContainer) {
        let context = container.mainContext
        let vipTag = Tag(name: "重要", colorHex: "#C0392B")
        let regularTag = Tag(name: "普通", colorHex: "#2C6FAC")
        let newTag = Tag(name: "新结识", colorHex: "#3D7A4B")
        context.insert(vipTag); context.insert(regularTag); context.insert(newTag)

        let judge = Person(name: "张建国", roleTypes: [.judge], org: "北京市朝阳区人民法院",
                           orgDepartment: "民二庭", title: "审判长", phone: "010-8888XXXX",
                           notes: "审理风格偏保守，重视证据链完整性", importance: 5)
        judge.tags = [vipTag]

        let prosecutor = Person(name: "李明", roleTypes: [.prosecutor],
                                org: "北京市朝阳区人民检察院", orgDepartment: "公诉部")
        prosecutor.tags = [regularTag]

        let client = Person(name: "王强", roleTypes: [.party], phone: "138XXXXYYYY",
                            notes: "XX公司法人代表", importance: 5)
        client.tags = [vipTag, newTag]

        let opposingLawyer = Person(name: "刘芳", roleTypes: [.lawyer], org: "君合律师事务所",
                                    phone: "139XXXXZZZZ", notes: "擅长合同法，庭审风格强势")
        opposingLawyer.tags = [regularTag]

        let police = Person(name: "陈刚", roleTypes: [.police], org: "朝阳分局经侦支队")
        let clerk = Person(name: "赵小燕", roleTypes: [.clerk], org: "北京市朝阳区人民法院",
                           orgDepartment: "民二庭")

        [judge, prosecutor, client, opposingLawyer, police, clerk].forEach { context.insert($0) }

        let case1 = Case(name: "XX公司股权转让纠纷案", caseType: .civil,
                         caseNumber: "(2026)京0105民初12345号", court: "北京市朝阳区人民法院",
                         caseStatus: .inTrial,
                         filingDate: Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 15)),
                         subjectAmount: 5_000_000, notes: "标的额较大，需要重点关注证据保全")
        let case2 = Case(name: "XX公司合同诈骗案", caseType: .criminal,
                         caseNumber: "(2025)京0105刑初6789号", court: "北京市朝阳区人民法院",
                         caseStatus: .judged,
                         filingDate: Calendar.current.date(from: DateComponents(year: 2025, month: 8, day: 1)),
                         closingDate: Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 20)),
                         result: "被告判三缓四，退赔全部款项", notes: "已结案，当事人满意")
        context.insert(case1); context.insert(case2)

        let cp1 = CasePerson(person: judge, case: case1, role: "审判长", roleCategory: .judge, sortOrder: 1)
        let cp2 = CasePerson(person: clerk, case: case1, role: "书记员", roleCategory: .clerk, sortOrder: 2)
        let cp3 = CasePerson(person: client, case: case1, role: "原告（我方当事人）", roleCategory: .party, sortOrder: 3)
        let cp4 = CasePerson(person: opposingLawyer, case: case1, role: "被告代理人", roleCategory: .lawyer, sortOrder: 4)
        let cp5 = CasePerson(person: judge, case: case2, role: "审判长", roleCategory: .judge, sortOrder: 1)
        let cp6 = CasePerson(person: prosecutor, case: case2, role: "公诉人", roleCategory: .prosecutor, sortOrder: 2)
        let cp7 = CasePerson(person: police, case: case2, role: "侦查人员", roleCategory: .police, sortOrder: 3)
        [cp1, cp2, cp3, cp4, cp5, cp6, cp7].forEach { context.insert($0) }

        let trialDate = Calendar.current.date(from: DateComponents(year: 2026, month: 7, day: 15, hour: 9, minute: 30))!
        let event1 = CaseEvent(title: "第四次开庭", eventType: .trial, date: trialDate, shouldRemind: true, case: case1)
        let deadlineDate = Calendar.current.date(from: DateComponents(year: 2026, month: 6, day: 30, hour: 17, minute: 0))!
        let event2 = CaseEvent(title: "补充证据截止日", eventType: .evidenceDeadline, date: deadlineDate, shouldRemind: true, case: case1)
        context.insert(event1); context.insert(event2)

        let meetingDate = Calendar.current.date(from: DateComponents(year: 2026, month: 6, day: 20, hour: 14, minute: 0))!
        let sampleEvent = Event(title: "团队周会", eventType: .meeting, status: .confirmed,
                                date: meetingDate, location: "会议室A", summary: "讨论本周案件进展及下周出庭安排")
        context.insert(sampleEvent)
        let ep1 = EventPerson(person: client, event: sampleEvent, role: "参会人")
        let ep2 = EventPerson(person: opposingLawyer, event: sampleEvent, role: "参会人")
        context.insert(ep1); context.insert(ep2)
        try? context.save()
    }
}

// MARK: - 查询服务

@MainActor
final class SearchService {
    private let modelContext: ModelContext
    init(modelContext: ModelContext) { self.modelContext = modelContext }

    func search(query: String) -> (persons: [Person], cases: [Case]) {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return ([], []) }
        let q = query.lowercased()
        let personDescriptor = FetchDescriptor<person>(
            predicate: #Predicate { person in
                person.name.localizedStandardContains(q) || person.pinyin.contains(q) ||
                person.pinyinInitials.contains(q) || (person.org?.localizedStandardContains(q) ?? false)
            },
            sortBy: [SortDescriptor(\.importance, order: .reverse), SortDescriptor(\.name)])
        let caseDescriptor = FetchDescriptor<case>(
            predicate: #Predicate { c in
                c.name.localizedStandardContains(q) || (c.caseNumber?.localizedStandardContains(q) ?? false) ||
                (c.court?.localizedStandardContains(q) ?? false)
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        do {
            let persons = try modelContext.fetch(personDescriptor)
            let cases = try modelContext.fetch(caseDescriptor)
            return (persons, cases)
        } catch { print("搜索失败: \(error)"); return ([], []) }
    }

    func searchPersons(query: String) -> [Person] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        let q = query.lowercased()
        let descriptor = FetchDescriptor<person>(
            predicate: #Predicate { person in
                person.name.localizedStandardContains(q) || person.pinyin.contains(q) ||
                person.pinyinInitials.contains(q)
            },
            sortBy: [SortDescriptor(\.name)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func casesForPerson(_ person: Person) -> [(PersonRoleType, [CasePerson])] { person.casesByRole }
    func personsForCase(_ case: Case) -> [(PersonRoleType, [(role: String, persons: [CasePerson])])] { `case`.personsByRole }

    func activeCases() -> [Case] {
        let descriptor = FetchDescriptor<case>(
            predicate: #Predicate { c in !c.isArchived },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func personsByRole(_ roleType: PersonRoleType) -> [Person] {
        let rawValue = roleType.rawValue
        let descriptor = FetchDescriptor<person>(
            predicate: #Predicate { person in person._roleTypesJSON.contains(rawValue) },
            sortBy: [SortDescriptor(\.name)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }
}

// MARK: - 邀请码模型

@Model
final class RedeemCode {
    var code: String
    var isUsed: Bool = false
    var usedAt: Date?
    var generatedAt: Date = Date()
    var note: String?
    var uniqueCode: String { code }

    init(code: String, note: String? = nil) { self.code = code; self.note = note }
}

// MARK: - SwiftData 容器配置

extension ModelContainer {
    static var appContainer: ModelContainer {
        do {
            let schema = Schema([
                Person.self, Case.self, CasePerson.self, CaseEvent.self, CaseDocument.self,
                Tag.self, Event.self, EventPerson.self, EventCase.self, RedeemCode.self
            ])
            let config = ModelConfiguration("IslandLink", cloudKitDatabase: .automatic)
            return try ModelContainer(for: schema, configurations: config)
        } catch { fatalError("无法创建 ModelContainer: \(error.localizedDescription)") }
    }

    static var localContainer: ModelContainer {
        do {
            let schema = Schema([
                Person.self, Case.self, CasePerson.self, CaseEvent.self, CaseDocument.self,
                Tag.self, Event.self, EventPerson.self, EventCase.self, RedeemCode.self
            ])
            let config = ModelConfiguration("IslandLink-local")
            return try ModelContainer(for: schema, configurations: config)
        } catch { fatalError("无法创建本地 ModelContainer: \(error.localizedDescription)") }
    }
}