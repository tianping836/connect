import Contacts
import SwiftUI
import SwiftData

/// 系统通讯录导入管理器
/// 支持：全量导入 / 逐条选择导入 / 匹配去重
@MainActor
final class ContactsImportManager: ObservableObject {
    static let shared = ContactsImportManager()

    private let store = CNContactStore()

    @Published var isAuthorized: Bool = false
    @Published var allContacts: [CNContact] = []

    private let keysToFetch: [CNKeyDescriptor] = [
        CNContactGivenNameKey as CNKeyDescriptor,
        CNContactFamilyNameKey as CNKeyDescriptor,
        CNContactPhoneNumbersKey as CNKeyDescriptor,
        CNContactEmailAddressesKey as CNKeyDescriptor,
        CNContactOrganizationNameKey as CNKeyDescriptor,
        CNContactJobTitleKey as CNKeyDescriptor,
        CNContactNoteKey as CNKeyDescriptor,
        CNContactImageDataKey as CNKeyDescriptor,
        CNContactThumbnailImageDataKey as CNKeyDescriptor
    ]

    // MARK: - 权限

    func requestAccess() async -> Bool {
        do {
            let granted = try await store.requestAccess(for: .contacts)
            isAuthorized = granted
            return granted
        } catch {
            print("[ContactsImport] 通讯录权限请求失败: \(error)")
            return false
        }
    }

    // MARK: - 读取全部联系人

    func fetchAllContacts() -> [CNContact] {
        guard isAuthorized else { return [] }

        let request = CNContactFetchRequest(keysToFetch: keysToFetch)
        var contacts: [CNContact] = []

        do {
            try store.enumerateContacts(with: request) { contact, _ in
                contacts.append(contact)
            }
        } catch {
            print("[ContactsImport] 读取通讯录失败: \(error)")
        }

        allContacts = contacts
        return contacts
    }

    // MARK: - 数据提取

    func fullName(for contact: CNContact) -> String {
        "\(contact.familyName)\(contact.givenName)"
    }

    func primaryPhone(for contact: CNContact) -> String? {
        contact.phoneNumbers.first?.value.stringValue
    }

    func primaryEmail(for contact: CNContact) -> String? {
        contact.emailAddresses.first?.value as String?
    }

    func organization(for contact: CNContact) -> String? {
        contact.organizationName.isEmpty ? nil : contact.organizationName
    }

    func jobTitle(for contact: CNContact) -> String? {
        contact.jobTitle.isEmpty ? nil : contact.jobTitle
    }

    // MARK: - 导入到 SwiftData

    func importContact(_ contact: CNContact, into modelContext: ModelContext) -> Person {
        let person = Person(
            name: fullName(for: contact),
            roleTypes: [.other],
            org: organization(for: contact),
            title: jobTitle(for: contact),
            phone: primaryPhone(for: contact),
            notes: contact.note.isEmpty ? nil : contact.note
        )

        if contact.phoneNumbers.count > 1 {
            person.phone = contact.phoneNumbers.first?.value.stringValue
            person.phone2 = contact.phoneNumbers.dropFirst().first?.value.stringValue
        }

        person.email = primaryEmail(for: contact)

        modelContext.insert(person)
        return person
    }

    // MARK: - 去重匹配

    func findExistingPerson(for contact: CNContact, in persons: [Person]) -> Person? {
        let name = fullName(for: contact)
        let phone = primaryPhone(for: contact)

        return persons.first { existing in
            if let phone = phone, existing.phone == phone {
                return true
            }
            if existing.name == name,
               let org = existing.org,
               org == contact.organizationName {
                return true
            }
            return false
        }
    }

    // MARK: - 导入状态

    enum ImportStatus {
        case new
        case alreadyImported
    }

    struct ImportEntry: Identifiable {
        let id: String
        let contact: CNContact
        let name: String
        let phone: String?
        let org: String?
        let status: ImportStatus
        var isSelected: Bool = false
    }
}