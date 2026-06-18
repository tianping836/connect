import Foundation
import SwiftData

// MARK: - 枚举定义

enum ContactRole: String, Codable, CaseIterable, Identifiable {
    case judge = "法官", prosecutor = "检察官", prosecutorAssistant = "检察官助理"
    case judgeAssistant = "法官助理", clerk = "书记员", juror = "人民陪审员"
    case lawyer = "律师", party = "当事人", police = "公安民警"
    case witness = "证人", appraiser = "鉴定人"
    case inspectionUnit = "检查股", caseReviewUnit = "案审股", other = "其他"
    var id: String { rawValue }
    var colorHex: String {
        switch self {
        case .judge: "#D32F2F"; case .prosecutor: "#1976D2"; case .prosecutorAssistant: "#64B5F6"
        case .judgeAssistant: "#EF9A9A"; case .clerk: "#5D4037"; case .juror: "#7B1FA2"
        case .lawyer: "#388E3C"; case .party: "#F57C00"; case .police: "#512DA8"
        case .witness: "#00796B"; case .appraiser: "#C2185B"
        case .inspectionUnit: "#455A64"; case .caseReviewUnit: "#455A64"; case .other: "#616161"
        }
    }
}

enum OrganizationType: String, Codable, CaseIterable, Identifiable {
    case court = "法院", procuratorate = "检察院", publicSecurity = "公安局"
    case taxBureau = "稽查局", judicialBureau = "司法局", lawFirm = "律所", other = "其他"
    var id: String { rawValue }
}

enum OrgRole: String, Codable, CaseIterable, Identifiable {
    case judge = "法官", judgeAssistant = "法官助理", clerk = "书记员"
    case juror = "人民陪审员", prosecutor = "检察官", prosecutorAssistant = "检察官助理"
    case inspectionUnit = "检查股", caseReviewUnit = "案审股", lawyer = "律师", other = "其他"
    var id: String { rawValue }
}

enum CaseType: String, Codable, CaseIterable, Identifiable {
    case criminal = "刑事", civil = "民事", administrative = "行政"
    case arbitration = "仲裁", nonLitigation = "非诉"
    var id: String { rawValue }
}

enum CaseStage: String, Codable, CaseIterable, Identifiable {
    case consulting = "洽谈中", retained = "已委托", filing = "立案中"
    case inTrial = "审理中", mediated = "已调解", judged = "已判决"
    case enforcing = "执行中", closed = "已结案", appealed = "已上诉"
    var id: String { rawValue }
    var isActive: Bool {
        switch self {
        case .consulting, .retained, .filing, .inTrial, .enforcing, .appealed: true
        case .mediated, .judged, .closed: false
        }
    }
    var pipelineOrder: Int {
        switch self {
        case .consulting: 0; case .retained: 1; case .filing: 2; case .inTrial: 3
        case .mediated: 4; case .judged: 5; case .appealed: 6; case .enforcing: 7; case .closed: 8
        }
    }
}

enum ParticipantRole: String, Codable, CaseIterable, Identifiable {
    case client = "委托人", opposingParty = "对手方", presidingJudge = "承办法官"
    case courtClerk = "书记员", prosecutorInCharge = "承办检察官"
    case opposingCounsel = "对方律师", coCounsel = "协办律师"
    case witness = "证人", appraiser = "鉴定人", other = "其他"
    var id: String { rawValue }
    var category: ParticipantCategory {
        switch self {
        case .client, .opposingParty, .witness: .partyRelated
        default: .officialRelated
        }
    }
}

enum ParticipantCategory: String, Codable {
    case partyRelated = "当事人相关", officialRelated = "经办人员"
}

enum InteractionType: String, Codable, CaseIterable, Identifiable {
    case giftGiven = "送礼", giftReceived = "收礼", favorGiven = "帮忙"
    case favorReceived = "被帮", visit = "拜访", phoneCall = "电话"
    case wechat = "微信", meeting = "面谈", meal = "饭局", other = "其他"
    var id: String { rawValue }
}

enum KeyEventType: String, Codable, CaseIterable, Identifiable {
    case filing = "立案", courtHearing = "开庭", evidenceDeadline = "举证期限"
    case mediation = "调解", sentencing = "宣判", appeal = "上诉", closing = "结案"
    case clientMeeting = "会见当事人", evidenceSubmission = "提交证据"
    case ruling = "裁定", other = "其他"
    var id: String { rawValue }
}

enum RelationshipStage: String, Codable, CaseIterable, Identifiable {
    case newAcquaintance = "新识", familiar = "熟悉", trusted = "信任", canRefer = "可引荐"
    var id: String { rawValue }
}

// MARK: - 联系人

@Model
final class Contact {
    @Attribute(.unique) var id: UUID
    var name: String
    @Attribute(.externalStorage) var avatar: Data?
    var phone: String?
    var wechat: String?
    var email: String?

    var roleTagsJSON: String
    @Transient var roleTags: [ContactRole] {
        get { JSONArrayTransformer.decodeContactRoles(roleTagsJSON) }
        set { roleTagsJSON = JSONArrayTransformer.encodeContactRoles(newValue) }
    }

    var organization: Organization?

    var rolesInOrgJSON: String
    @Transient var rolesInOrg: [OrgRole] {
        get { JSONArrayTransformer.decodeOrgRoles(rolesInOrgJSON) }
        set { rolesInOrgJSON = JSONArrayTransformer.encodeOrgRoles(newValue) }
    }

    var referrer: Contact?
    @Relationship(inverse: \Contact.referrer)
    var referrals: [Contact]?

    var importance: Int
    var relationshipStageRaw: String
    @Transient var relationshipStage: RelationshipStage {
        get { RelationshipStage(rawValue: relationshipStageRaw) ?? .newAcquaintance }
        set { relationshipStageRaw = newValue.rawValue }
    }

    var skillTagsJSON: String
    @Transient var skillTags: [String] {
        get { JSONArrayTransformer.decodeStringArray(skillTagsJSON) }
        set { skillTagsJSON = JSONArrayTransformer.encodeStringArray(newValue) }
    }

    var preferences: String?
    var birthday: Date?
    var notes: String?
    var contactReminderDays: Int?
    var lastContactDate: Date?
    var nextContactDate: Date?
    @Relationship(deleteRule: .cascade) var interactions: [Interaction]?
    var hasUpdate: Bool
    var isArchived: Bool
    var createdAt: Date
    var updatedAt: Date

    @Relationship(inverse: \CaseParticipant.contact)
    var caseParticipations: [CaseParticipant]?

    init(id: UUID = UUID(), name: String, avatar: Data? = nil, phone: String? = nil,
         wechat: String? = nil, email: String? = nil, roleTags: [ContactRole] = [],
         organization: Organization? = nil, rolesInOrg: [OrgRole] = [],
         referrer: Contact? = nil, importance: Int = 3,
         relationshipStage: RelationshipStage = .newAcquaintance, skillTags: [String] = [],
         preferences: String? = nil, birthday: Date? = nil, notes: String? = nil,
         contactReminderDays: Int? = nil, lastContactDate: Date? = nil,
         nextContactDate: Date? = nil, interactions: [Interaction]? = nil,
         hasUpdate: Bool = false, isArchived: Bool = false,
         createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id; self.name = name; self.avatar = avatar
        self.phone = phone; self.wechat = wechat; self.email = email
        self.roleTagsJSON = JSONArrayTransformer.encodeContactRoles(roleTags)
        self.organization = organization
        self.rolesInOrgJSON = JSONArrayTransformer.encodeOrgRoles(rolesInOrg)
        self.referrer = referrer; self.importance = importance
        self.relationshipStageRaw = relationshipStage.rawValue
        self.skillTagsJSON = JSONArrayTransformer.encodeStringArray(skillTags)
        self.preferences = preferences; self.birthday = birthday; self.notes = notes
        self.contactReminderDays = contactReminderDays
        self.lastContactDate = lastContactDate; self.nextContactDate = nextContactDate
        self.interactions = interactions; self.hasUpdate = hasUpdate
        self.isArchived = isArchived; self.createdAt = createdAt; self.updatedAt = updatedAt
    }
}

// MARK: - 互动记录

@Model
final class Interaction {
    @Attribute(.unique) var id: UUID
    var contact: Contact?
    var typeRaw: String
    @Transient var type: InteractionType {
        get { InteractionType(rawValue: typeRaw) ?? .other }
        set { typeRaw = newValue.rawValue }
    }
    var date: Date
    var detail: String
    var amount: Double?
    var nextFollowUpDate: Date?
    var createdAt: Date

    init(id: UUID = UUID(), contact: Contact? = nil, type: InteractionType = .other,
         date: Date = Date(), detail: String = "", amount: Double? = nil,
         nextFollowUpDate: Date? = nil, createdAt: Date = Date()) {
        self.id = id; self.contact = contact; self.typeRaw = type.rawValue
        self.date = date; self.detail = detail; self.amount = amount
        self.nextFollowUpDate = nextFollowUpDate; self.createdAt = createdAt
    }
}

// MARK: - 机构

@Model
final class Organization {
    @Attribute(.unique) var id: UUID
    var name: String
    var typeRaw: String
    @Transient var type: OrganizationType {
        get { OrganizationType(rawValue: typeRaw) ?? .other }
        set { typeRaw = newValue.rawValue }
    }
    var address: String?
    var notes: String?

    @Relationship(deleteRule: .nullify, inverse: \Contact.organization)
    var contacts: [Contact]?

    @Relationship(inverse: \CaseRecord.acceptedOrganization)
    var acceptedCases: [CaseRecord]?

    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), name: String, type: OrganizationType = .other,
         address: String? = nil, notes: String? = nil, contacts: [Contact]? = nil,
         acceptedCases: [CaseRecord]? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id; self.name = name; self.typeRaw = type.rawValue
        self.address = address; self.notes = notes; self.contacts = contacts
        self.acceptedCases = acceptedCases; self.createdAt = createdAt; self.updatedAt = updatedAt
    }
}

// MARK: - 案件

@Model
final class CaseRecord {
    @Attribute(.unique) var id: UUID
    var caseName: String
    var caseTypeRaw: String
    @Transient var caseType: CaseType {
        get { CaseType(rawValue: caseTypeRaw) ?? .civil }
        set { caseTypeRaw = newValue.rawValue }
    }
    var courtCaseNumber: String?
    var internalCaseNumber: String?
    var claimAmount: Double?
    var claimSummary: String?
    var caseResult: String?
    var caseStageRaw: String
    @Transient var caseStage: CaseStage {
        get { CaseStage(rawValue: caseStageRaw) ?? .consulting }
        set { caseStageRaw = newValue.rawValue }
    }
    var filingDate: Date?
    var closingDate: Date?

    // inverse declared on Organization.acceptedCases
    var acceptedOrganization: Organization?

    var responsibleLawyer: Contact?

    @Relationship(deleteRule: .cascade, inverse: \CaseParticipant.caseRecord)
    var participants: [CaseParticipant]?

    @Relationship(deleteRule: .cascade, inverse: \KeyEvent.caseRecord)
    var keyEvents: [KeyEvent]?

    var documentPathsJSON: String
    @Transient var documentPaths: [String] {
        get { JSONArrayTransformer.decodeStringArray(documentPathsJSON) }
        set { documentPathsJSON = JSONArrayTransformer.encodeStringArray(newValue) }
    }

    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), caseName: String, caseType: CaseType = .civil,
         courtCaseNumber: String? = nil, internalCaseNumber: String? = nil,
         claimAmount: Double? = nil, claimSummary: String? = nil,
         caseResult: String? = nil, caseStage: CaseStage = .consulting,
         filingDate: Date? = nil, closingDate: Date? = nil,
         acceptedOrganization: Organization? = nil, responsibleLawyer: Contact? = nil,
         participants: [CaseParticipant]? = nil, keyEvents: [KeyEvent]? = nil,
         documentPaths: [String] = [],
         notes: String? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id; self.caseName = caseName; self.caseTypeRaw = caseType.rawValue
        self.courtCaseNumber = courtCaseNumber; self.internalCaseNumber = internalCaseNumber
        self.claimAmount = claimAmount; self.claimSummary = claimSummary
        self.caseResult = caseResult; self.caseStageRaw = caseStage.rawValue
        self.filingDate = filingDate; self.closingDate = closingDate
        self.acceptedOrganization = acceptedOrganization
        self.responsibleLawyer = responsibleLawyer
        self.participants = participants; self.keyEvents = keyEvents
        self.documentPathsJSON = JSONArrayTransformer.encodeStringArray(documentPaths)
        self.notes = notes; self.createdAt = createdAt; self.updatedAt = updatedAt
    }
}

// MARK: - 案件参与人（中间表）

@Model
final class CaseParticipant {
    @Attribute(.unique) var id: UUID
    var caseRecord: CaseRecord?
    var contact: Contact?
    var roleRaw: String
    @Transient var role: ParticipantRole {
        get { ParticipantRole(rawValue: roleRaw) ?? .other }
        set { roleRaw = newValue.rawValue }
    }
    var roleDetail: String?
    var notes: String?
    var createdAt: Date

    init(id: UUID = UUID(), caseRecord: CaseRecord? = nil, contact: Contact? = nil,
         role: ParticipantRole = .other, roleDetail: String? = nil, notes: String? = nil,
         createdAt: Date = Date()) {
        self.id = id; self.caseRecord = caseRecord; self.contact = contact
        self.roleRaw = role.rawValue; self.roleDetail = roleDetail; self.notes = notes
        self.createdAt = createdAt
    }
}

// MARK: - 大事记

@Model
final class KeyEvent {
    @Attribute(.unique) var id: UUID
    var caseRecord: CaseRecord?
    var eventTypeRaw: String
    @Transient var eventType: KeyEventType {
        get { KeyEventType(rawValue: eventTypeRaw) ?? .other }
        set { eventTypeRaw = newValue.rawValue }
    }
    var date: Date
    var title: String
    var detail: String?
    var reminderEnabled: Bool
    var reminderDaysJSON: String
    @Transient var reminderDays: [Int] {
        get { JSONArrayTransformer.decodeIntArray(reminderDaysJSON) }
        set { reminderDaysJSON = JSONArrayTransformer.encodeIntArray(newValue) }
    }
    var createdAt: Date

    init(id: UUID = UUID(), caseRecord: CaseRecord? = nil, eventType: KeyEventType = .other,
         date: Date = Date(), title: String = "", detail: String? = nil,
         reminderEnabled: Bool = true, reminderDays: [Int] = [7, 3, 1],
         createdAt: Date = Date()) {
        self.id = id; self.caseRecord = caseRecord; self.eventTypeRaw = eventType.rawValue
        self.date = date; self.title = title; self.detail = detail
        self.reminderEnabled = reminderEnabled
        self.reminderDaysJSON = JSONArrayTransformer.encodeIntArray(reminderDays)
        self.createdAt = createdAt
    }
}
