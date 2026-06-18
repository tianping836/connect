import Foundation

// MARK: - App Tab

/// 应用导航 Tab（共享类型，供各 View 引用）
enum AppTab: String, CaseIterable {
    case search = "搜索"
    case contacts = "人脉"
    case cases = "案件"
    case calendar = "日历"
    case settings = "设置"

    var systemImage: String {
        switch self {
        case .search:    "magnifyingglass"
        case .contacts:  "person.3.fill"
        case .cases:     "doc.text.fill"
        case .calendar:  "calendar"
        case .settings:  "gearshape"
        }
    }

    var displayName: String {
        switch self {
        case .search:    "搜索"
        case .contacts:  "人脉"
        case .cases:     "案件"
        case .calendar:  "日历"
        case .settings:  "设置"
        }
    }
}

// MARK: - 快捷键通知

extension Notification.Name {
    /// ⌘N 快捷键 → 当前活跃 Tab 新建项目
    static let newItemRequested = Notification.Name("CaseNetwork.newItemRequested")
    /// ⌘F 快捷键 → 聚焦搜索框
    static let focusSearchRequested = Notification.Name("CaseNetwork.focusSearchRequested")
    /// 右键菜单 → 编辑联系人
    static let editContactRequested = Notification.Name("CaseNetwork.editContactRequested")
    /// 右键菜单 → 添加联系人到案件
    static let addContactToCaseRequested = Notification.Name("CaseNetwork.addContactToCaseRequested")
    /// 右键菜单 → 编辑案件
    static let editCaseRequested = Notification.Name("CaseNetwork.editCaseRequested")
    /// 右键菜单 → 编辑大事记
    static let editKeyEventRequested = Notification.Name("CaseNetwork.editKeyEventRequested")
}
