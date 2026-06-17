import Foundation
import SwiftData
import SwiftUI
import Combine

/// 联系人列表的数据逻辑：搜索 + 筛选 + 排序
@MainActor
@Observable
final class ContactListViewModel {

    // MARK: - 查询状态

    var searchText = ""
    var selectedRoleFilter: ContactRole? = nil
    var sortOrder: SortOrder = .byName
    var showArchived = false

    // MARK: - 搜索结果（派生）

    /// 联系人总数
    var totalCount: Int { filteredContacts.count }

    /// 按关系阶段分组的联系人
    var contactsByStage: [(RelationshipStage, [Contact])] {
        let grouped = Dictionary(grouping: filteredContacts) { $0.relationshipStage }
        return RelationshipStage.allCases.compactMap { stage in
            guard let contacts = grouped[stage], !contacts.isEmpty else { return nil }
            return (stage, contacts.sorted(by: sortPredicate))
        }
    }

    /// 按角色分组的联系人
    var contactsByRole: [(ContactRole, [Contact])] {
        let all = filteredContacts.flatMap { contact in
            contact.roleTags.map { ($0, contact) }
        }
        let grouped = Dictionary(grouping: all) { $0.0 }.mapValues { $0.map(\.1) }
        return ContactRole.allCases.compactMap { role in
            guard let contacts = grouped[role], !contacts.isEmpty else { return nil }
            return (role, contacts.sorted(by: sortPredicate))
        }
    }

    /// 高优先级联系人（importance >= 4）
    var importantContacts: [Contact] {
        filteredContacts
            .filter { $0.importance >= 4 }
            .sorted(by: sortPredicate)
    }

    // MARK: - 筛选

    /// 是否激活筛选
    var isFiltering: Bool {
        !searchText.isEmpty || selectedRoleFilter != nil
    }

    // MARK: - Private

    private var allContacts: [Contact] = []

    private var filteredContacts: [Contact] {
        var result = allContacts

        // 归档过滤
        if !showArchived {
            result = result.filter { !$0.isArchived }
        }

        // 文本搜索
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { contact in
                contact.name.lowercased().contains(query)
                || (contact.phone ?? "").contains(query)
                || (contact.organization?.name ?? "").lowercased().contains(query)
                || contact.skillTags.contains(where: { $0.lowercased().contains(query) })
            }
        }

        // 角色筛选
        if let role = selectedRoleFilter {
            result = result.filter { $0.roleTags.contains(role) }
        }

        return result
    }

    // MARK: - 排序

    enum SortOrder: String, CaseIterable, Identifiable {
        case byName = "按姓名"
        case byImportance = "按重要度"
        case byRecent = "按最近联系"

        var id: String { rawValue }
    }

    private var sortPredicate: (Contact, Contact) -> Bool {
        switch sortOrder {
        case .byName:
            return { ($0.name.localizedCompare($1.name)) == .orderedAscending }
        case .byImportance:
            return { $0.importance > $1.importance }
        case .byRecent:
            return { ($0.lastContactDate ?? .distantPast) > ($1.lastContactDate ?? .distantPast) }
        }
    }

    // MARK: - 数据加载

    func loadContacts(_ contacts: [Contact]) {
        allContacts = contacts
    }
}
