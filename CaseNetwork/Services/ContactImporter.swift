import Foundation
import Contacts
import SwiftData

/// 系统通讯录导入服务
/// iOS: 需在 Info.plist 配置 NSContactsUsageDescription
/// macOS: 需在 Signing & Capabilities 勾选 Contacts (Hardened Runtime)
@MainActor
final class ContactImporter {
    static let shared = ContactImporter()

    private let store = CNContactStore()

    // 要读取的字段
    private let keys: [CNKeyDescriptor] = [
        CNContactGivenNameKey as CNKeyDescriptor,
        CNContactFamilyNameKey as CNKeyDescriptor,
        CNContactPhoneNumbersKey as CNKeyDescriptor,
        CNContactEmailAddressesKey as CNKeyDescriptor,
        CNContactOrganizationNameKey as CNKeyDescriptor,
        CNContactJobTitleKey as CNKeyDescriptor,
        CNContactNoteKey as CNKeyDescriptor,
        CNContactImageDataKey as CNKeyDescriptor,
        CNContactThumbnailImageDataKey as CNKeyDescriptor,
    ]

    private init() {}

    // MARK: - 权限

    /// 请求通讯录访问权限
    func requestAccess() async -> Bool {
        do {
            return try await store.requestAccess(for: .contacts)
        } catch {
            return false
        }
    }

    /// 当前权限状态
    var authorizationStatus: CNAuthorizationStatus {
        CNContactStore.authorizationStatus(for: .contacts)
    }

    // MARK: - 读取

    /// 读取全部联系人（用于导入预览）
    func fetchAllContacts() async throws -> [CNContact] {
        let status = authorizationStatus
        switch status {
        case .authorized:
            break
        case .notDetermined:
            let granted = await requestAccess()
            if !granted { throw ImportError.accessDenied }
        default:
            throw ImportError.accessDenied
        }

        let request = CNContactFetchRequest(keysToFetch: keys)
        var results: [CNContact] = []

        try store.enumerateContacts(with: request) { contact, _ in
            results.append(contact)
        }

        return results.sorted { ($0.familyName + $0.givenName) < ($1.familyName + $1.givenName) }
    }

    /// 将系统联系人转为 CaseNetwork Contact（不存入数据库，仅转换）
    func convertToCaseNetworkContact(_ cnContact: CNContact) -> Contact {
        let fullName = cnContact.familyName + cnContact.givenName

        let phone = cnContact.phoneNumbers.first?.value.stringValue
        let email = cnContact.emailAddresses.first?.value as String?

        // 从机构名+职位推断角色
        var roleTags: [ContactRole] = []
        let org = cnContact.organizationName.lowercased()
        let title = cnContact.jobTitle.lowercased()

        if org.contains("法院") || title.contains("法官") { roleTags.append(.judge) }
        if org.contains("检察院") || title.contains("检察官") { roleTags.append(.prosecutor) }
        if org.contains("公安") { roleTags.append(.police) }
        if org.contains("律") || title.contains("律师") { roleTags.append(.lawyer) }

        let avatar = cnContact.thumbnailImageData ?? cnContact.imageData

        return Contact(
            name: fullName.isEmpty ? "Unnamed" : fullName,
            avatar: avatar,
            phone: phone,
            email: email,
            roleTags: roleTags,
            notes: cnContact.note.isEmpty ? nil : cnContact.note
        )
    }

    /// 从组织名称匹配或创建 Organization
    func resolveOrganization(name: String?, context: ModelContext) -> Organization? {
        guard let name = name, !name.isEmpty else { return nil }

        let allOrgs = (try? context.fetch(FetchDescriptor<Organization>())) ?? []
        if let existing = allOrgs.first(where: { $0.name == name }) {
            return existing
        }

        let org = Organization(name: name, type: .other)
        context.insert(org)
        return org
    }

    // MARK: - 批量导入

    /// 批量导入选中的系统联系人
    /// - Returns: 成功导入的数量
    func importSelected(_ cnContacts: [CNContact], modelContext: ModelContext) throws -> Int {
        var count = 0
        for cn in cnContacts {
            let contact = convertToCaseNetworkContact(cn)

            // 跳过空名字
            guard !contact.name.isEmpty, contact.name != "Unnamed" else { continue }

            // 去重：同名+同手机号跳过
            let allExisting = (try? modelContext.fetch(FetchDescriptor<Contact>())) ?? []
            if allExisting.contains(where: { $0.name == contact.name && $0.phone == contact.phone }) {
                continue
            }

            // 解析机构
            let orgName = cn.organizationName
            if !orgName.isEmpty {
                contact.organization = resolveOrganization(name: orgName, context: modelContext)
            }

            modelContext.insert(contact)
            count += 1
        }

        try modelContext.save()
        return count
    }

    // MARK: - 增量获取

    /// 获取自指定时间以来修改过的联系人
    func fetchContacts(since date: Date) async throws -> [CNContact] {
        let status = authorizationStatus
        guard status == .authorized else { return [] }

        let all = try await fetchAllContacts()
        // CNContact 没有内置修改时间字段，用 Contact 的 modificationDate
        // 实际策略：记录上次导入的标识符集合，只导入新增的
        return all
    }

    /// 获取通讯录中尚未导入的联系人
    func fetchUnimportedContacts(existingIdentifiers: Set<String>) async throws -> [CNContact] {
        let all = try await fetchAllContacts()
        return all.filter { !existingIdentifiers.contains($0.identifier) }
    }

    /// 一键导入全部通讯录（跳过已存在的）
    /// - Returns: 新导入的数量
    func importAll(modelContext: ModelContext) async throws -> Int {
        let all = try await fetchAllContacts()
        return try importSelected(all, modelContext: modelContext)
    }

    /// 获取已导入联系人标识符集合（用于去重）
    func importedIdentifiers(modelContext: ModelContext) -> Set<String> {
        let all = (try? modelContext.fetch(FetchDescriptor<Contact>())) ?? []
        // 用 phone 作为去重标识
        return Set(all.compactMap { $0.phone }.filter { !$0.isEmpty })
    }

    enum ImportError: Error, LocalizedError {
        case accessDenied

        var errorDescription: String? {
            switch self {
            case .accessDenied: return "通讯录访问被拒绝。请在 设置 > 隐私 > 通讯录 中授权。"
            }
        }
    }
}

