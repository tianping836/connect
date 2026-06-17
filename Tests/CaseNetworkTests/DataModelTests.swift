import Foundation
import Testing
import SwiftData
@testable import CaseNetwork

@MainActor
struct DataModelTests {

    // MARK: - 联系人与机构

    @Test func testCreateContactAndOrganization() throws {
        let container = try ModelContainer(
            for: Contact.self, Organization.self, Interaction.self,
            CaseRecord.self, CaseParticipant.self, KeyEvent.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let court = Organization(name: "朝阳法院", type: .court, address: "朝阳公园南路甲2号")
        context.insert(court)

        let judge = Contact(
            name: "王朝阳",
            phone: "13801001234",
            roleTags: [.judge],
            organization: court,
            rolesInOrg: [.judge],
            importance: 5,
            relationshipStage: .trusted
        )
        context.insert(judge)
        try context.save()

        #expect(judge.organization?.name == "朝阳法院")
        #expect(court.contacts?.contains(judge) == true)
        #expect(judge.roleTags.contains(.judge))
        #expect(judge.importance == 5)
    }

    // MARK: - 介绍人链（自关联）

    @Test func testReferralChain() throws {
        let container = try ModelContainer(
            for: Contact.self, Organization.self, Interaction.self,
            CaseRecord.self, CaseParticipant.self, KeyEvent.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let referrer = Contact(name: "方文博", roleTags: [.lawyer], importance: 5, relationshipStage: .trusted)
        context.insert(referrer)

        let referred = Contact(
            name: "杨志伟",
            roleTags: [.party],
            referrer: referrer,
            relationshipStage: .familiar
        )
        context.insert(referred)

        let secondDegree = Contact(
            name: "秦志明",
            roleTags: [.party],
            referrer: referred,
            relationshipStage: .newAcquaintance
        )
        context.insert(secondDegree)
        try context.save()

        #expect(referred.referrer?.name == "方文博")
        #expect(secondDegree.referrer?.name == "杨志伟")
    }

    // MARK: - 案件 + 参与人（多对多）

    @Test func testCaseWithParticipants() throws {
        let container = try ModelContainer(
            for: Contact.self, Organization.self, Interaction.self,
            CaseRecord.self, CaseParticipant.self, KeyEvent.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let court = Organization(name: "朝阳法院", type: .court)
        context.insert(court)

        let client = Contact(name: "杨志伟", roleTags: [.party])
        let judge = Contact(name: "王朝阳", roleTags: [.judge], organization: court)
        let clerk = Contact(name: "陈小芳", roleTags: [.clerk], organization: court)
        [client, judge, clerk].forEach { context.insert($0) }

        let p1 = CaseParticipant(contact: client, role: .client)
        let p2 = CaseParticipant(contact: judge, role: .presidingJudge, roleDetail: "审判长")
        let p3 = CaseParticipant(contact: clerk, role: .courtClerk)

        let caseRecord = CaseRecord(
            caseName: "建设工程施工合同纠纷",
            caseType: .civil,
            courtCaseNumber: "(2025)京0105民初15678号",
            caseStage: .inTrial,
            acceptedOrganization: court,
            participants: [p1, p2, p3]
        )
        context.insert(caseRecord)

        let e1 = KeyEvent(eventType: .filing, date: date(2025, 3, 15), title: "立案")
        let e2 = KeyEvent(eventType: .courtHearing, date: date(2025, 7, 15), title: "开庭", reminderDays: [7, 3, 1])
        caseRecord.keyEvents = [e1, e2]

        try context.save()

        #expect(caseRecord.participants?.count == 3)
        #expect(caseRecord.keyEvents?.count == 2)
        #expect(caseRecord.acceptedOrganization?.name == "朝阳法院")

        // 区分当事人 vs 经办人员
        let partyParticipants = caseRecord.participants?.filter { $0.role.category == .partyRelated }
        let officialParticipants = caseRecord.participants?.filter { $0.role.category == .officialRelated }
        #expect(partyParticipants?.count == 1)   // 委托人
        #expect(officialParticipants?.count == 2) // 法官 + 书记员

        // 级联提醒
        #expect(e2.reminderDays == [7, 3, 1])
    }

    // MARK: - 案件 ↔ 机构双向

    @Test func testCaseOrganizationBidirectional() throws {
        let container = try ModelContainer(
            for: Contact.self, Organization.self, Interaction.self,
            CaseRecord.self, CaseParticipant.self, KeyEvent.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let court = Organization(name: "海淀法院", type: .court)
        context.insert(court)

        let case1 = CaseRecord(caseName: "案A", caseType: .civil, acceptedOrganization: court)
        let case2 = CaseRecord(caseName: "案B", caseType: .civil, acceptedOrganization: court)
        [case1, case2].forEach { context.insert($0) }

        try context.save()

        #expect(court.acceptedCases?.count == 2)
        #expect(case1.acceptedOrganization?.name == "海淀法院")
    }

    // MARK: - 互动记录

    @Test func testInteractionTracking() throws {
        let container = try ModelContainer(
            for: Contact.self, Organization.self, Interaction.self,
            CaseRecord.self, CaseParticipant.self, KeyEvent.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let contact = Contact(name: "陈国栋", roleTags: [.party])
        context.insert(contact)

        let i1 = Interaction(contact: contact, type: .meal, detail: "铁观音会所午餐", amount: 680)
        let i2 = Interaction(contact: contact, type: .giftReceived, detail: "春节送礼", amount: 3200)
        [i1, i2].forEach { context.insert($0) }

        try context.save()

        #expect(contact.interactions?.count == 2)
    }

    // MARK: - PreviewData

    @Test func testPreviewDataCreation() throws {
        let container = try ModelContainer(
            for: Contact.self, Organization.self, Interaction.self,
            CaseRecord.self, CaseParticipant.self, KeyEvent.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        PreviewData.create(modelContext: context)

        let contactCount = try context.fetchCount(FetchDescriptor<Contact>())
        let orgCount = try context.fetchCount(FetchDescriptor<Organization>())
        let caseCount = try context.fetchCount(FetchDescriptor<CaseRecord>())

        #expect(contactCount > 0)
        #expect(orgCount > 0)
        #expect(caseCount > 0)
    }

    // MARK: - 搜索场景验证

    /// 验证核心场景：搜人名 → 找到关联案件
    @Test func testSearchPersonFindsCases() throws {
        let container = try ModelContainer(
            for: Contact.self, Organization.self, Interaction.self,
            CaseRecord.self, CaseParticipant.self, KeyEvent.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let person = Contact(name: "王朝阳", roleTags: [.judge])
        context.insert(person)

        let case1 = CaseRecord(caseName: "合同纠纷案", caseType: .civil)
        let p1 = CaseParticipant(caseRecord: case1, contact: person, role: .presidingJudge)
        case1.participants = [p1]
        context.insert(case1)

        let case2 = CaseRecord(caseName: "侵权纠纷案", caseType: .civil)
        let p2 = CaseParticipant(caseRecord: case2, contact: person, role: .presidingJudge)
        case2.participants = [p2]
        context.insert(case2)

        try context.save()

        // 通过 CaseParticipant 查询此人关联的案件
        let participations = person.caseParticipations ?? []
        #expect(participations.count == 2)
        let caseNames = participations.compactMap { $0.caseRecord?.caseName }
        #expect(caseNames.contains("合同纠纷案"))
        #expect(caseNames.contains("侵权纠纷案"))
    }

    /// 验证核心场景：搜案件 → 找到全部参与人 + 大事记
    @Test func testSearchCaseFindsAllParticipants() throws {
        let container = try ModelContainer(
            for: Contact.self, Organization.self, Interaction.self,
            CaseRecord.self, CaseParticipant.self, KeyEvent.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let client = Contact(name: "杨志伟", roleTags: [.party])
        let judge = Contact(name: "王朝阳", roleTags: [.judge])
        let opponent = Contact(name: "潘晓明", roleTags: [.party])
        [client, judge, opponent].forEach { context.insert($0) }

        let caseRecord = CaseRecord(
            caseName: "建设工程施工合同纠纷",
            caseType: .civil,
            caseStage: .inTrial,
            participants: [
                CaseParticipant(contact: client, role: .client),
                CaseParticipant(contact: judge, role: .presidingJudge),
                CaseParticipant(contact: opponent, role: .opposingParty),
            ],
            keyEvents: [
                KeyEvent(eventType: .filing, date: date(2025, 3, 15), title: "立案"),
                KeyEvent(eventType: .courtHearing, date: date(2025, 7, 15), title: "开庭"),
            ]
        )
        context.insert(caseRecord)
        try context.save()

        // 所有参与人
        #expect(caseRecord.participants?.count == 3)
        // 大事记
        #expect(caseRecord.keyEvents?.count == 2)
        // 大事记按时间排序
        let sortedEvents = caseRecord.keyEvents?.sorted(by: { $0.date < $1.date })
        #expect(sortedEvents?.first?.title == "立案")
    }

    // MARK: - Helper

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day))!
    }
}
