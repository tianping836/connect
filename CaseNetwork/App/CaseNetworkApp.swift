import SwiftUI
import SwiftData

/// CaseNetwork App 入口
/// - iPhone (compact): TabView 底部导航
/// - iPad (regular): NavigationSplitView 三栏布局 + 键盘快捷键
@main
struct CaseNetworkApp: App {
    let container: ModelContainer
    @State private var activeTab: AppTab = .search

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
            AdaptiveContentView(activeTab: $activeTab)
        }
        .modelContainer(container)
        .commands {
            sidebarCommands
        }
    }

    // MARK: - 键盘快捷键 (iPad / Mac)

    @CommandsBuilder
    private var sidebarCommands: some Commands {
        CommandMenu("Navigate") {
            Button("Search") { activeTab = .search }
                .keyboardShortcut("1", modifiers: .command)
            Button("Contacts") { activeTab = .contacts }
                .keyboardShortcut("2", modifiers: .command)
            Button("Cases") { activeTab = .cases }
                .keyboardShortcut("3", modifiers: .command)
            Button("Calendar") { activeTab = .calendar }
                .keyboardShortcut("4", modifiers: .command)

            Divider()

            Button("New Item") {
                postNewItemCommand()
            }
            .keyboardShortcut("n", modifiers: .command)

            Button("Find") {
                NotificationCenter.default.post(name: .focusSearchRequested, object: nil)
            }
            .keyboardShortcut("f", modifiers: .command)
        }
    }

    private func postNewItemCommand() {
        NotificationCenter.default.post(name: .newItemRequested, object: activeTab)
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

// MARK: - 自适应布局

/// iPhone: TabView | iPad: NavigationSplitView
struct AdaptiveContentView: View {
    @Binding var activeTab: AppTab
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        if horizontalSizeClass == .regular {
            iPadLayout
        } else {
            iPhoneLayout
        }
    }

    // MARK: - iPhone: TabView

    private var iPhoneLayout: some View {
        TabView(selection: $activeTab) {
            GlobalSearchView()
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
                .tag(AppTab.search)

            ContactListView()
                .tabItem { Label("Contacts", systemImage: "person.3.fill") }
                .tag(AppTab.contacts)

            CaseListView()
                .tabItem { Label("Cases", systemImage: "doc.text.fill") }
                .tag(AppTab.cases)

            CalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }
                .tag(AppTab.calendar)
        }
        .tint(.blue)
    }

    // MARK: - iPad: NavigationSplitView

    private var iPadLayout: some View {
        NavigationSplitView {
            sidebar
        } content: {
            contentColumn
        } detail: {
            placeholderDetail
        }
        .navigationSplitViewStyle(.balanced)
    }

    // MARK: 侧栏

    private var sidebar: some View {
        List(selection: $activeTab) {
            Section("CaseNetwork") {
                Label("Search", systemImage: "magnifyingglass")
                    .tag(AppTab.search)
                Label("Contacts", systemImage: "person.3.fill")
                    .tag(AppTab.contacts)
                Label("Cases", systemImage: "doc.text.fill")
                    .tag(AppTab.cases)
                Label("Calendar", systemImage: "calendar")
                    .tag(AppTab.calendar)
            }
        }
        .navigationTitle("CaseNetwork")
        .listStyle(.sidebar)
    }

    // MARK: 内容栏——按选中的 Tab 切换

    @ViewBuilder
    private var contentColumn: some View {
        switch activeTab {
        case .search:
            GlobalSearchView()
        case .contacts:
            ContactListView()
        case .cases:
            CaseListView()
        case .calendar:
            CalendarView()
        }
    }

    // MARK: 详情栏占位（NavigationStack 处理 drill-down）

    private var placeholderDetail: some View {
        ContentUnavailableView(
            "Select an item",
            systemImage: "rectangle.lefthalf.inset.filled",
            description: Text("Choose a contact, case, or event from the list.")
        )
    }
}
