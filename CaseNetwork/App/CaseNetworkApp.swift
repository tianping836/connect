import SwiftUI
import SwiftData

/// CaseNetwork App 入口
@main
struct CaseNetworkApp: App {
    let container: ModelContainer

    init() {
        container = ModelContainer.appContainer
        // 如果是首次启动，注入预设数据
        if isFirstLaunch() {
            PreviewData.create(modelContext: container.mainContext)
        }
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                ContactListView()
                    .tabItem {
                        Label("Contacts", systemImage: "person.3.fill")
                    }

                Text("Case list - coming soon")
                    .tabItem {
                        Label("Cases", systemImage: "doc.text.fill")
                    }

                Text("Calendar - coming soon")
                    .tabItem {
                        Label("Calendar", systemImage: "calendar")
                    }

                Text("Settings - coming soon")
                    .tabItem {
                        Label("Settings", systemImage: "gearshape")
                    }
            }
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
