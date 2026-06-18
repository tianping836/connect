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

                ContentUnavailableView(
                    "Calendar",
                    systemImage: "calendar",
                    description: Text("Coming in Phase 3")
                )
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
