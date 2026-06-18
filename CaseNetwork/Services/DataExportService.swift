import Foundation
import SwiftData
import UniformTypeIdentifiers

// MARK: - 导出数据容器

/// CaseNetwork 全量数据导出结构（Codable，跨版本兼容）
struct CaseNetworkExport: Codable {
    let version: String
    let exportDate: Date
    let contacts: [ContactExportDTO]
    let interactions: [InteractionExportDTO]
    let organizations: [OrganizationExportDTO]
    let caseRecords: [CaseRecordExportDTO]
    let caseParticipants: [CaseParticipantExportDTO]
    let keyEvents: [KeyEventExportDTO]
}

// MARK: - 导出 DTO（扁平化，无关联，纯数据）

struct ContactExportDTO: Codable {
    let id: UUID
    let name: String
    let phone: String?
    let wechat: String?
    let email: String?
    let roleTags: [String]
    let organizationName: String?
    let rolesInOrg: [String]
    let referrerName: String?
    let importance: Int
    let relationshipStage: String
    let skillTags: [String]
    let preferences: String?
    let birthday: String?  // ISO 8601
    let notes: String?
    let contactReminderDays: Int?
    let lastContactDate: String?
    let nextContactDate: String?
    let hasUpdate: Bool
    let isArchived: Bool
    let createdAt: String
    let updatedAt: String
}

struct InteractionExportDTO: Codable {
    let id: UUID
    let contactName: String?
    let type: String
    let date: String
    let detail: String
    let amount: Double?
    let nextFollowUpDate: String?
    let createdAt: String
}

struct OrganizationExportDTO: Codable {
    let id: UUID
    let name: String
    let type: String
    let address: String?
    let notes: String?
    let contactNames: [String]
    let createdAt: String
    let updatedAt: String
}

struct CaseRecordExportDTO: Codable {
    let id: UUID
    let caseName: String
    let caseType: String
    let courtCaseNumber: String?
    let internalCaseNumber: String?
    let claimAmount: Double?
    let claimSummary: String?
    let caseResult: String?
    let caseStage: String
    let filingDate: String?
    let closingDate: String?
    let acceptedOrgName: String?
    let responsibleLawyerName: String?
    let participantSummaries: [String]
    let keyEventSummaries: [String]
    let documentPaths: [String]
    let notes: String?
    let createdAt: String
    let updatedAt: String
}

struct CaseParticipantExportDTO: Codable {
    let id: UUID
    let caseName: String?
    let contactName: String?
    let role: String
    let roleDetail: String?
    let notes: String?
    let createdAt: String
}

struct KeyEventExportDTO: Codable {
    let id: UUID
    let caseName: String?
    let eventType: String
    let date: String
    let title: String
    let detail: String?
    let reminderEnabled: Bool
    let reminderDays: [Int]
    let createdAt: String
}

// MARK: - 数据导出服务

/// 处理 JSON 全量导出、CSV 按表导出、JSON 导入、数据清除
@MainActor
final class DataExportService {

    static let shared = DataExportService()
    private init() {}

    // MARK: - JSON 全量导出

    /// 导出全部数据为 JSON，写入临时目录并返回文件 URL
    func exportAllJSON(modelContext: ModelContext) throws -> URL {
        let export = try buildExportData(context: modelContext)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(export)

        let url = tempFileURL(prefix: "CaseNetwork_export_", ext: "json")
        try data.write(to: url)
        return url
    }

    // MARK: - CSV 按表导出

    /// 导出联系人 CSV
    func exportContactsCSV(modelContext: ModelContext) throws -> URL {
        let contacts = try fetchAll(of: Contact.self, context: modelContext)
        let headers = ["姓名", "手机", "微信", "邮箱", "角色标签", "机构",
                       "关系阶段", "重要度(1-5)", "技能标签", "最近联系", "下次联系", "备注"]
        let rows = contacts.map { c in
            [c.name, c.phone ?? "", c.wechat ?? "", c.email ?? "",
             c.roleTags.map(\.rawValue).joined(separator: ";"),
             c.organization?.name ?? "",
             c.relationshipStage.rawValue,
             String(c.importance),
             c.skillTags.joined(separator: ";"),
             dateString(c.lastContactDate),
             dateString(c.nextContactDate),
             c.notes ?? ""]
        }
        return try writeCSV(headers: headers, rows: rows, prefix: "CaseNetwork_contacts_")
    }

    /// 导出案件 CSV
    func exportCasesCSV(modelContext: ModelContext) throws -> URL {
        let cases = try fetchAll(of: CaseRecord.self, context: modelContext)
        let headers = ["案件名称", "案件类型", "案号(法院)", "案号(委托)", "案件阶段",
                       "标的额", "立案时间", "结案时间", "受理机构", "负责律师", "备注"]
        let rows = cases.map { c in
            [c.caseName, c.caseType.rawValue, c.courtCaseNumber ?? "", c.internalCaseNumber ?? "",
             c.caseStage.rawValue,
             c.claimAmount.map { String($0) } ?? "",
             dateString(c.filingDate), dateString(c.closingDate),
             c.acceptedOrganization?.name ?? "",
             c.responsibleLawyer?.name ?? "",
             c.notes ?? ""]
        }
        return try writeCSV(headers: headers, rows: rows, prefix: "CaseNetwork_cases_")
    }

    /// 导出机构 CSV
    func exportOrganizationsCSV(modelContext: ModelContext) throws -> URL {
        let orgs = try fetchAll(of: Organization.self, context: modelContext)
        let headers = ["名称", "类型", "地址", "关联联系人数", "关联案件数", "备注"]
        let rows = orgs.map { o in
            [o.name, o.type.rawValue, o.address ?? "",
             String(o.contacts?.count ?? 0),
             String(o.acceptedCases?.count ?? 0),
             o.notes ?? ""]
        }
        return try writeCSV(headers: headers, rows: rows, prefix: "CaseNetwork_organizations_")
    }

    /// 导出大事记 CSV
    func exportEventsCSV(modelContext: ModelContext) throws -> URL {
        let events = try fetchAll(of: KeyEvent.self, context: modelContext)
        let headers = ["事件类型", "标题", "日期", "关联案件", "提醒", "提醒天数", "详情"]
        let rows = events.map { e in
            [e.eventType.rawValue, e.title, dateString(e.date),
             e.caseRecord?.caseName ?? "",
             e.reminderEnabled ? "是" : "否",
             e.reminderDays.map(String.init).joined(separator: ";"),
             e.detail ?? ""]
        }
        return try writeCSV(headers: headers, rows: rows, prefix: "CaseNetwork_events_")
    }

    // MARK: - JSON 导入

    /// 从 JSON 文件导入数据
    /// - Returns: 导入的记录总数
    func importFromJSON(_ url: URL, modelContext: ModelContext) throws -> Int {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let export = try decoder.decode(CaseNetworkExport.self, from: data)

        var importedCount = 0
        let isoFormatter = ISO8601DateFormatter()

        // 机构（无依赖，先导入）
        var orgMap: [UUID: Organization] = [:]
        for dto in export.organizations {
            let org = Organization(
                id: dto.id,
                name: dto.name,
                type: OrganizationType(rawValue: dto.type) ?? .other,
                address: dto.address,
                notes: dto.notes,
                createdAt: isoFormatter.date(from: dto.createdAt) ?? Date(),
                updatedAt: isoFormatter.date(from: dto.updatedAt) ?? Date()
            )
            modelContext.insert(org)
            orgMap[dto.id] = org
            importedCount += 1
        }

        // 联系人（先不带 referrer 关联）
        var contactMap: [UUID: Contact] = [:]

        for dto in export.contacts {
            let contact = Contact(
                id: dto.id,
                name: dto.name,
                phone: dto.phone,
                wechat: dto.wechat,
                email: dto.email,
                roleTags: dto.roleTags.compactMap { ContactRole(rawValue: $0) },
                organization: dto.organizationName.flatMap { _ in nil }, // 后续按名匹配
                rolesInOrg: dto.rolesInOrg.compactMap { OrgRole(rawValue: $0) },
                importance: dto.importance,
                relationshipStage: RelationshipStage(rawValue: dto.relationshipStage) ?? .newAcquaintance,
                skillTags: dto.skillTags,
                preferences: dto.preferences,
                notes: dto.notes,
                contactReminderDays: dto.contactReminderDays,
                lastContactDate: isoFormatter.date(from: dto.lastContactDate ?? ""),
                nextContactDate: isoFormatter.date(from: dto.nextContactDate ?? ""),
                hasUpdate: dto.hasUpdate,
                isArchived: dto.isArchived,
                createdAt: isoFormatter.date(from: dto.createdAt) ?? Date(),
                updatedAt: isoFormatter.date(from: dto.updatedAt) ?? Date()
            )
            modelContext.insert(contact)
            contactMap[dto.id] = contact
            importedCount += 1
        }

        // 机构↔联系人 按名称关联
        for dto in export.contacts {
            guard let contact = contactMap[dto.id],
                  let orgName = dto.organizationName else { continue }
            // 找同名机构
            if let org = orgMap.values.first(where: { $0.name == orgName }) {
                contact.organization = org
            }
        }

        // 介绍人自关联（按名字）
        for dto in export.contacts {
            guard let contact = contactMap[dto.id],
                  let refName = dto.referrerName else { continue }
            if let referrer = contactMap.values.first(where: { $0.name == refName }) {
                contact.referrer = referrer
            }
        }

        // 案件
        var caseMap: [UUID: CaseRecord] = [:]
        for dto in export.caseRecords {
            let caseRecord = CaseRecord(
                id: dto.id,
                caseName: dto.caseName,
                caseType: CaseType(rawValue: dto.caseType) ?? .civil,
                courtCaseNumber: dto.courtCaseNumber,
                internalCaseNumber: dto.internalCaseNumber,
                claimAmount: dto.claimAmount,
                claimSummary: dto.claimSummary,
                caseResult: dto.caseResult,
                caseStage: CaseStage(rawValue: dto.caseStage) ?? .consulting,
                filingDate: isoFormatter.date(from: dto.filingDate ?? ""),
                closingDate: isoFormatter.date(from: dto.closingDate ?? ""),
                documentPaths: dto.documentPaths,
                notes: dto.notes,
                createdAt: isoFormatter.date(from: dto.createdAt) ?? Date(),
                updatedAt: isoFormatter.date(from: dto.updatedAt) ?? Date()
            )

            // 关联机构
            if let orgName = dto.acceptedOrgName,
               let org = orgMap.values.first(where: { $0.name == orgName }) {
                caseRecord.acceptedOrganization = org
            }
            // 关联负责律师
            if let lawyerName = dto.responsibleLawyerName,
               let lawyer = contactMap.values.first(where: { $0.name == lawyerName }) {
                caseRecord.responsibleLawyer = lawyer
            }

            modelContext.insert(caseRecord)
            caseMap[dto.id] = caseRecord
            importedCount += 1
        }

        // 案件参与人
        for dto in export.caseParticipants {
            let participant = CaseParticipant(
                id: dto.id,
                role: ParticipantRole(rawValue: dto.role) ?? .other,
                roleDetail: dto.roleDetail,
                notes: dto.notes,
                createdAt: isoFormatter.date(from: dto.createdAt) ?? Date()
            )
            // 关联案件和联系人
            if let caseName = dto.caseName,
               let caseRec = caseMap.values.first(where: { $0.caseName == caseName }) {
                participant.caseRecord = caseRec
            }
            if let contactName = dto.contactName,
               let contact = contactMap.values.first(where: { $0.name == contactName }) {
                participant.contact = contact
            }

            modelContext.insert(participant)
            importedCount += 1
        }

        // 大事记
        for dto in export.keyEvents {
            let event = KeyEvent(
                id: dto.id,
                eventType: KeyEventType(rawValue: dto.eventType) ?? .other,
                date: isoFormatter.date(from: dto.date) ?? Date(),
                title: dto.title,
                detail: dto.detail,
                reminderEnabled: dto.reminderEnabled,
                reminderDays: dto.reminderDays,
                createdAt: isoFormatter.date(from: dto.createdAt) ?? Date()
            )
            if let caseName = dto.caseName,
               let caseRec = caseMap.values.first(where: { $0.caseName == caseName }) {
                event.caseRecord = caseRec
            }
            modelContext.insert(event)
            importedCount += 1
        }

        try modelContext.save()
        return importedCount
    }

    // MARK: - 数据清除

    /// 清除所有数据（按依赖顺序删除，避免外键冲突）
    /// - Returns: 删除的记录总数
    func clearAllData(modelContext: ModelContext) throws -> Int {
        var deleted = 0

        // 1. 互动记录（依赖 Contact）
        let interactions = try fetchAll(of: Interaction.self, context: modelContext)
        interactions.forEach { modelContext.delete($0) }
        deleted += interactions.count

        // 2. 案件参与人（依赖 Contact + CaseRecord）
        let participants = try fetchAll(of: CaseParticipant.self, context: modelContext)
        participants.forEach { modelContext.delete($0) }
        deleted += participants.count

        // 3. 大事记（依赖 CaseRecord）
        let events = try fetchAll(of: KeyEvent.self, context: modelContext)
        events.forEach { modelContext.delete($0) }
        deleted += events.count

        // 4. 案件
        let cases = try fetchAll(of: CaseRecord.self, context: modelContext)
        cases.forEach { modelContext.delete($0) }
        deleted += cases.count

        // 5. 联系人（清空 referrer + org 关联后删除）
        let contacts = try fetchAll(of: Contact.self, context: modelContext)
        contacts.forEach { $0.referrer = nil; $0.organization = nil }
        contacts.forEach { modelContext.delete($0) }
        deleted += contacts.count

        // 6. 机构
        let orgs = try fetchAll(of: Organization.self, context: modelContext)
        orgs.forEach { modelContext.delete($0) }
        deleted += orgs.count

        try modelContext.save()
        return deleted
    }

    /// 计算各表记录数（用于清除前预览）
    func recordCounts(modelContext: ModelContext) throws -> [(String, Int)] {
        [
            ("联系人", try fetchCount(of: Contact.self, context: modelContext)),
            ("互动记录", try fetchCount(of: Interaction.self, context: modelContext)),
            ("机构", try fetchCount(of: Organization.self, context: modelContext)),
            ("案件", try fetchCount(of: CaseRecord.self, context: modelContext)),
            ("案件参与人", try fetchCount(of: CaseParticipant.self, context: modelContext)),
            ("大事记", try fetchCount(of: KeyEvent.self, context: modelContext)),
        ]
    }

    // MARK: - 内部工具

    private func buildExportData(context: ModelContext) throws -> CaseNetworkExport {
        let contacts = try fetchAll(of: Contact.self, context: context)
        let interactions = try fetchAll(of: Interaction.self, context: context)
        let orgs = try fetchAll(of: Organization.self, context: context)
        let cases = try fetchAll(of: CaseRecord.self, context: context)
        let participants = try fetchAll(of: CaseParticipant.self, context: context)
        let events = try fetchAll(of: KeyEvent.self, context: context)

        return CaseNetworkExport(
            version: "1.0",
            exportDate: Date(),
            contacts: contacts.map(contactDTO),
            interactions: interactions.map(interactionDTO),
            organizations: orgs.map(orgDTO),
            caseRecords: cases.map(caseDTO),
            caseParticipants: participants.map(participantDTO),
            keyEvents: events.map(eventDTO)
        )
    }

    // MARK: DTO 映射

    private func contactDTO(_ c: Contact) -> ContactExportDTO {
        ContactExportDTO(
            id: c.id, name: c.name, phone: c.phone, wechat: c.wechat, email: c.email,
            roleTags: c.roleTags.map(\.rawValue),
            organizationName: c.organization?.name,
            rolesInOrg: c.rolesInOrg.map(\.rawValue),
            referrerName: c.referrer?.name,
            importance: c.importance,
            relationshipStage: c.relationshipStage.rawValue,
            skillTags: c.skillTags,
            preferences: c.preferences,
            birthday: c.birthday.map(isoString),
            notes: c.notes,
            contactReminderDays: c.contactReminderDays,
            lastContactDate: c.lastContactDate.map(isoString),
            nextContactDate: c.nextContactDate.map(isoString),
            hasUpdate: c.hasUpdate, isArchived: c.isArchived,
            createdAt: isoString(c.createdAt),
            updatedAt: isoString(c.updatedAt)
        )
    }

    private func interactionDTO(_ i: Interaction) -> InteractionExportDTO {
        InteractionExportDTO(
            id: i.id, contactName: i.contact?.name, type: i.type.rawValue,
            date: isoString(i.date), detail: i.detail, amount: i.amount,
            nextFollowUpDate: i.nextFollowUpDate.map(isoString),
            createdAt: isoString(i.createdAt)
        )
    }

    private func orgDTO(_ o: Organization) -> OrganizationExportDTO {
        OrganizationExportDTO(
            id: o.id, name: o.name, type: o.type.rawValue,
            address: o.address, notes: o.notes,
            contactNames: o.contacts?.map(\.name) ?? [],
            createdAt: isoString(o.createdAt), updatedAt: isoString(o.updatedAt)
        )
    }

    private func caseDTO(_ c: CaseRecord) -> CaseRecordExportDTO {
        CaseRecordExportDTO(
            id: c.id, caseName: c.caseName, caseType: c.caseType.rawValue,
            courtCaseNumber: c.courtCaseNumber, internalCaseNumber: c.internalCaseNumber,
            claimAmount: c.claimAmount, claimSummary: c.claimSummary, caseResult: c.caseResult,
            caseStage: c.caseStage.rawValue,
            filingDate: c.filingDate.map(isoString),
            closingDate: c.closingDate.map(isoString),
            acceptedOrgName: c.acceptedOrganization?.name,
            responsibleLawyerName: c.responsibleLawyer?.name,
            participantSummaries: c.participants?.map { "\($0.contact?.name ?? "?")(\($0.role.rawValue))" } ?? [],
            keyEventSummaries: c.keyEvents?.map { "\($0.eventType.rawValue): \($0.title)" } ?? [],
            documentPaths: c.documentPaths,
            notes: c.notes,
            createdAt: isoString(c.createdAt), updatedAt: isoString(c.updatedAt)
        )
    }

    private func participantDTO(_ p: CaseParticipant) -> CaseParticipantExportDTO {
        CaseParticipantExportDTO(
            id: p.id, caseName: p.caseRecord?.caseName, contactName: p.contact?.name,
            role: p.role.rawValue, roleDetail: p.roleDetail, notes: p.notes,
            createdAt: isoString(p.createdAt)
        )
    }

    private func eventDTO(_ e: KeyEvent) -> KeyEventExportDTO {
        KeyEventExportDTO(
            id: e.id, caseName: e.caseRecord?.caseName, eventType: e.eventType.rawValue,
            date: isoString(e.date), title: e.title, detail: e.detail,
            reminderEnabled: e.reminderEnabled, reminderDays: e.reminderDays,
            createdAt: isoString(e.createdAt)
        )
    }

    // MARK: 通用查询

    private func fetchAll<T: PersistentModel>(of type: T.Type, context: ModelContext) throws -> [T] {
        let descriptor = FetchDescriptor<T>()
        return try context.fetch(descriptor)
    }

    private func fetchCount<T: PersistentModel>(of type: T.Type, context: ModelContext) throws -> Int {
        let descriptor = FetchDescriptor<T>()
        return try context.fetchCount(descriptor)
    }

    // MARK: 文件工具

    private func tempFileURL(prefix: String, ext: String) -> URL {
        let dir = FileManager.default.temporaryDirectory
        let ts = Int(Date().timeIntervalSince1970)
        return dir.appendingPathComponent("\(prefix)\(ts).\(ext)")
    }

    private func writeCSV(headers: [String], rows: [[String]], prefix: String) throws -> URL {
        var csv = headers.map(escapeCSV).joined(separator: ",") + "\n"
        for row in rows {
            csv += row.map(escapeCSV).joined(separator: ",") + "\n"
        }
        let url = tempFileURL(prefix: prefix, ext: "csv")
        // 加 BOM 让 Excel 正确识别 UTF-8 中文
        var data = Data([0xEF, 0xBB, 0xBF])
        data.append(Data(csv.utf8))
        try data.write(to: url)
        return url
    }

    private func escapeCSV(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"\(field.replacingOccurrences(of: "\"", with: "\"\"") )\""
        }
        return field
    }

    private func isoString(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

    private func dateString(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    // MARK: - CSV 案件导入

    /// 从 CSV 文件导入案件（支持 Excel/Numbers 导出的 CSV）
    ///
    /// 期望列（自动检测表头，大小写不敏感）：
    /// "案件名称"、"案件类型"、"案号"、"案件阶段"、"标的额"、"立案时间"、"受理机构"、"备注"
    ///
    /// - Returns: 导入的案件数量
    func importCasesFromCSV(_ url: URL, modelContext: ModelContext) throws -> Int {
        let content = try String(contentsOf: url, encoding: .utf8)
        let lines = parseCSVLines(content)
        guard lines.count >= 2 else { throw ImportError.emptyFile }

        // 解析表头，建立列索引映射
        let header = lines[0].map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
        var colMap: [String: Int] = [:]
        for (i, h) in header.enumerated() {
            colMap[h] = i
        }

        // 日期解析器
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let altDateFormatter = DateFormatter()
        altDateFormatter.dateFormat = "yyyy/M/d"

        func parseDate(_ s: String) -> Date? {
            dateFormatter.date(from: s) ?? altDateFormatter.date(from: s)
        }

        var imported = 0

        // 跳过表头，逐行导入
        for line in lines.dropFirst() {
            guard line.count >= 1, !line.allSatisfy({ $0.isEmpty }) else { continue }

            let caseName = col(at: colMap["案件名称"] ?? colMap["case name"] ?? colMap["name"], in: line)

            guard let name = caseName, !name.isEmpty else { continue }

            // 去重：同名案件跳过
            let allCases = (try? modelContext.fetch(FetchDescriptor<CaseRecord>())) ?? []
            if allCases.contains(where: { $0.caseName == name }) {
                continue
            }

            let caseTypeStr = col(at: colMap["案件类型"] ?? colMap["case type"] ?? colMap["type"], in: line)
            let type = CaseType.allCases.first { $0.rawValue == caseTypeStr } ?? .civil

            let caseNumber = col(at: colMap["案号"] ?? colMap["case number"] ?? colMap["no"], in: line)

            let stageStr = col(at: colMap["案件阶段"] ?? colMap["stage"] ?? colMap["status"], in: line)
            let stage = CaseStage.allCases.first { $0.rawValue == stageStr } ?? .consulting

            let amountStr = col(at: colMap["标的额"] ?? colMap["amount"] ?? colMap["claim amount"], in: line)
            let amount = amountStr.flatMap { Double($0.replacingOccurrences(of: ",", with: "").replacingOccurrences(of: "¥", with: "")) }

            let filingDateStr = col(at: colMap["立案时间"] ?? colMap["filing date"] ?? colMap["date"], in: line)
            let filingDate = filingDateStr.flatMap(parseDate)

            let orgName = col(at: colMap["受理机构"] ?? colMap["organization"] ?? colMap["court"], in: line)

            let notes = col(at: colMap["备注"] ?? colMap["notes"] ?? colMap["description"], in: line)

            let caseRecord = CaseRecord(
                caseName: name,
                caseType: type,
                courtCaseNumber: caseNumber,
                claimAmount: amount,
                caseStage: stage,
                filingDate: filingDate,
                notes: notes
            )

            // 查找或创建机构
            if let orgName = orgName, !orgName.isEmpty {
                let allOrgs = (try? modelContext.fetch(FetchDescriptor<Organization>())) ?? []
                if let existingOrg = allOrgs.first(where: { $0.name == orgName }) {
                    caseRecord.acceptedOrganization = existingOrg
                } else {
                    let org = Organization(name: orgName, type: .other)
                    modelContext.insert(org)
                    caseRecord.acceptedOrganization = org
                }
            }

            modelContext.insert(caseRecord)
            imported += 1
        }

        if imported > 0 { try modelContext.save() }
        return imported
    }

    /// 解析 CSV 行（处理引号内的逗号）
    private func parseCSVLines(_ content: String) -> [[String]] {
        var result: [[String]] = []
        for rawLine in content.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty else { continue }

            var fields: [String] = []
            var current = ""
            var inQuotes = false

            for char in line {
                switch char {
                case "\"":
                    inQuotes.toggle()
                case "," where !inQuotes:
                    fields.append(current)
                    current = ""
                default:
                    current.append(char)
                }
            }
            fields.append(current)
            result.append(fields)
        }
        return result
    }

    private func col(at index: Int?, in line: [String]) -> String? {
        guard let i = index, i < line.count else { return nil }
        let val = line[i].trimmingCharacters(in: .whitespaces)
        return val.isEmpty ? nil : val
    }

    // MARK: - CSV 人脉导入

    /// 从 CSV 文件导入人脉（支持 Numbers/Excel 导出的 CSV）
    ///
    /// 期望列（自动检测表头）：姓名、电话、微信、邮箱、角色、机构、关系阶段、备注
    func importContactsFromCSV(_ url: URL, modelContext: ModelContext) throws -> Int {
        let content = try String(contentsOf: url, encoding: .utf8)
        let lines = parseCSVLines(content)
        guard lines.count >= 2 else { throw ImportError.emptyFile }

        let header = lines[0].map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
        var colMap: [String: Int] = [:]
        for (i, h) in header.enumerated() { colMap[h] = i }

        func colVal(_ keys: String..., in line: [String]) -> String? {
            for k in keys {
                if let idx = colMap[k], idx < line.count {
                    let v = line[idx].trimmingCharacters(in: .whitespaces)
                    if !v.isEmpty { return v }
                }
            }
            return nil
        }

        let allOrgs = (try? modelContext.fetch(FetchDescriptor<Organization>())) ?? []
        let allExisting = (try? modelContext.fetch(FetchDescriptor<Contact>())) ?? []

        var imported = 0
        for line in lines.dropFirst() {
            guard line.count >= 1, !line.allSatisfy({ $0.isEmpty }) else { continue }

            let name = colVal("姓名", "name", "名字", in: line)
            guard let name = name else { continue }

            // 去重
            let phone = colVal("电话", "手机", "phone", "tel", in: line)
            if allExisting.contains(where: { $0.name == name && $0.phone == phone }) { continue }

            let wechat = colVal("微信", "wechat", in: line)
            let email = colVal("邮箱", "email", "邮件", in: line)
            let roleStr = colVal("角色", "role", "标签", in: line)
            let roleTags: [ContactRole] = roleStr?.components(separatedBy: CharacterSet(charactersIn: ";,，；"))
                .compactMap { seg in
                    let t = seg.trimmingCharacters(in: .whitespaces)
                    for role in ContactRole.allCases { if role.rawValue == t { return role } }
                    return nil
                } ?? []

            let orgName = colVal("机构", "单位", "organization", "company", "org", in: line)
            let org: Organization? = orgName.flatMap { name in
                if let existing = allOrgs.first(where: { $0.name == name }) { return existing }
                let newOrg = Organization(name: name)
                modelContext.insert(newOrg)
                return newOrg
            }

            let stageStr = colVal("关系阶段", "阶段", "stage", "关系", in: line)
            let stage = RelationshipStage.allCases.first(where: { $0.rawValue == stageStr }) ?? .newAcquaintance

            let notes = colVal("备注", "notes", "note", "说明", in: line)

            let contact = Contact(
                name: name,
                phone: phone, wechat: wechat, email: email,
                roleTags: roleTags,
                organization: org,
                relationshipStage: stage,
                notes: notes
            )
            modelContext.insert(contact)
            imported += 1
        }

        if imported > 0 { try modelContext.save() }
        return imported
    }

    enum ImportError: Error, LocalizedError {
        case emptyFile

        var errorDescription: String? {
            switch self {
            case .emptyFile: return "CSV 文件为空或格式不正确"
            }
        }
    }
}
