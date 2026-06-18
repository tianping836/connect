import SwiftUI
import SwiftData

/// CaseNetwork App 入口
@main
struct CaseNetworkApp: App {
    let container: ModelContainer
    @State private var activeTab: Tab = .search

    enum Tab: String, CaseIterable {
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

    init() {
        container = ModelContainer.appContainer
        if isFirstLaunch() {
            PreviewData.create(modelContext: container.mainContext)
        }
        // 请求通知权限（首次启动时系统弹窗，之后静默返回当前状态）
        Task { @MainActor in
            let granted = await NotificationService.shared.requestAuthorization()
            print("[CaseNetwork] Notification authorization: \(granted ? "granted" : "denied")")
        }
    }

    var body: some Scene {
        WindowGroup {
            TabView(selection: $activeTab) {
                GlobalSearchView()
                    .tabItem { Label("Search", systemImage: "magnifyingglass") }
                    .tag(Tab.search)

                ContactListView()
                    .tabItem { Label("Contacts", systemImage: "person.3.fill") }
                    .tag(Tab.contacts)

                CaseListView()
                    .tabItem { Label("Cases", systemImage: "doc.text.fill") }
                    .tag(Tab.cases)

                CalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }
                .tag(Tab.calendar)
            }
            .tint(.blue)
        }
        .modelContainer(container)
    }

    private func isFirstLaunch() -> Bool {
        let key = "has_launched_before"
        let launched = UserDefaults.standard.bool(forKey: key)
        if !launched {
            UserDefaults.standard.set(true, forKey: key)
        }
        return !launched
    }
}
