import Foundation

// MARK: - App Tab

/// 应用导航 Tab（共享类型，供各 View 引用）
enum AppTab: String, CaseIterable {
    case search = "Search"
    case contacts = "Contacts"
    case cases = "Cases"
    case calendar = "Calendar"

    var systemImage: String {
        switch self {
        case .search:   "magnifyingglass"
        case .contacts: "person.3.fill"
        case .cases:    "doc.text.fill"
        case .calendar: "calendar"
        }
    }
}

// MARK: - 快捷键通知

extension Notification.Name {
    /// ⌘N 快捷键 → 当前活跃 Tab 新建项目
    static let newItemRequested = Notification.Name("CaseNetwork.newItemRequested")
    /// ⌘F 快捷键 → 聚焦搜索框
    static let focusSearchRequested = Notification.Name("CaseNetwork.focusSearchRequested")
}
