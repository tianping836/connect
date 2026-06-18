import SwiftUI
import SwiftData

/// CaseNetwork App 入口
/// - iPhone (compact): TabView 底部导航
/// - iPad (regular): NavigationSplitView 三栏布局 + 键盘快捷键
/// - macOS: 菜单栏 + 窗口管理 + 右键菜单
/// - Phase 6: 应用锁 + CloudKit 同步 + 数据导出
@main
struct CaseNetworkApp: App {
    let container: ModelContainer
    @State private var activeTab: AppTab = .search
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("has_seen_onboarding") private var hasSeenOnboarding = false

    init() {
        container = ModelContainer.appContainer
        // 若非首次启动且跳过引导 → 补建预览数据
        let launchedBefore = UserDefaults.standard.bool(forKey: "has_launched_before")
        if launchedBefore && !hasSeenOnboarding {
            // 之前启动过但没看过引导 = 升级用户，跳过引导
            hasSeenOnboarding = true
        }
        if launchedBefore {
            // 已启动过 → 正常
        } else {
            // 真正的首次启动 → 标记，引导页接管数据初始化
            UserDefaults.standard.set(true, forKey: "has_launched_before")
        }
        // 请求通知权限
        Task { @MainActor in
            let granted = await NotificationService.shared.requestAuthorization()
            print("[CaseNetwork] Notification authorization: \(granted ? "granted" : "denied")")
        }
        // 启动 CloudKit 同步观察
        CloudSyncObserver.shared.startIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            AdaptiveContentView(activeTab: $activeTab)
            #if os(macOS)
                .frame(minWidth: 800, minHeight: 500)
            #endif
                // 应用锁遮罩
                .overlay {
                    if BiometricAuthService.shared.isAppLocked {
                        AppLockView()
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: BiometricAuthService.shared.isAppLocked)
                // 首次引导
                .sheet(isPresented: Binding(
                    get: { !hasSeenOnboarding },
                    set: { if !$0 { hasSeenOnboarding = true } }
                )) {
                    OnboardingView()
                        .onDisappear {
                            hasSeenOnboarding = true
                            // 引导结束后，如果数据库为空，建预览数据
                            ensurePreviewData()
                        }
                        #if os(macOS)
                        .frame(width: 520, height: 620)
                        #endif
                }
        }
        #if os(macOS)
        .defaultSize(width: 1100, height: 700)
        #endif
        .modelContainer(container)
        #if os(macOS)
        .commands {
            sidebarCommands
        }
        #endif
        // Phase 6: 场景阶段 → 自动加锁
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background || newPhase == .inactive {
                BiometricAuthService.shared.lock()
            }
        }
    }

    // MARK: - 菜单栏 (macOS)

    #if os(macOS)
    @CommandsBuilder
    private var sidebarCommands: some Commands {
        // File 菜单
        CommandGroup(after: .newItem) {
            Menu("New") {
                Button("New Contact") {
                    NotificationCenter.default.post(name: .newItemRequested, object: AppTab.contacts)
                }
                .keyboardShortcut("n", modifiers: .command)

                Button("New Case") {
                    NotificationCenter.default.post(name: .newItemRequested, object: AppTab.cases)
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])

                Button("New Event") {
                    NotificationCenter.default.post(name: .newItemRequested, object: AppTab.calendar)
                }
                .keyboardShortcut("n", modifiers: [.command, .option])
            }
        }

        // View 菜单
        CommandMenu("Navigate") {
            Button("Search") { activeTab = .search }
                .keyboardShortcut("1", modifiers: .command)
            Button("Contacts") { activeTab = .contacts }
                .keyboardShortcut("2", modifiers: .command)
            Button("Cases") { activeTab = .cases }
                .keyboardShortcut("3", modifiers: .command)
            Button("Calendar") { activeTab = .calendar }
                .keyboardShortcut("4", modifiers: .command)
            Button("Settings") { activeTab = .settings }
                .keyboardShortcut("5", modifiers: .command)

            Divider()

            Button("Find…") {
                activeTab = .search
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    NotificationCenter.default.post(name: .focusSearchRequested, object: nil)
                }
            }
            .keyboardShortcut("f", modifiers: .command)
        }

        // Window 菜单
        CommandGroup(replacing: .windowSize) {
            Button("Default Size") {
                NSApplication.shared.keyWindow?.setContentSize(NSSize(width: 1100, height: 700))
            }
            .keyboardShortcut("0", modifiers: [.command])

            Divider()
        }
    }
    #endif

    /// 如果数据库为空，填充预览数据（引导结束后调用）
    private func ensurePreviewData() {
        let ctx = container.mainContext
        do {
            let contactCount = try ctx.fetchCount(FetchDescriptor<Contact>())
            if contactCount == 0 {
                PreviewData.create(modelContext: ctx)
            }
        } catch {
            PreviewData.create(modelContext: ctx)
        }
    }
}

// MARK: - 自适应布局

/// iPhone: TabView | iPad: NavigationSplitView | Mac: NavigationSplitView
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

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(AppTab.settings)
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
            Section {
                Label("Settings", systemImage: "gearshape")
                    .tag(AppTab.settings)
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
        case .settings:
            SettingsView()
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
