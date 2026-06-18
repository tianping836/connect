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
        // Phase 6: 场景阶段 → 自动加锁
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background || newPhase == .inactive {
                BiometricAuthService.shared.lock()
            }
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
                .tabItem { Label("搜索", systemImage: "magnifyingglass") }
                .tag(AppTab.search)

            ContactListView()
                .tabItem { Label("人脉", systemImage: "person.3.fill") }
                .tag(AppTab.contacts)

            CaseListView()
                .tabItem { Label("案件", systemImage: "doc.text.fill") }
                .tag(AppTab.cases)

            CalendarView()
                .tabItem { Label("日历", systemImage: "calendar") }
                .tag(AppTab.calendar)

            SettingsView()
                .tabItem { Label("设置", systemImage: "gearshape") }
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
        Group {
            #if os(macOS)
            List(selection: $activeTab) {
                sidebarContent
            }
            #else
            List {
                sidebarContent
            }
            #endif
        }
        .navigationTitle("连接")
        #if os(macOS)
        .listStyle(.sidebar)
        #endif
    }

    @ViewBuilder
    private var sidebarContent: some View {
        Section("连接") {
            sidebarItem(tab: .search, icon: "magnifyingglass", label: "搜索")
            sidebarItem(tab: .contacts, icon: "person.3.fill", label: "人脉")
            sidebarItem(tab: .cases, icon: "doc.text.fill", label: "案件")
            sidebarItem(tab: .calendar, icon: "calendar", label: "日历")
        }
        Section {
            sidebarItem(tab: .settings, icon: "gearshape", label: "设置")
        }
    }

    private func sidebarItem(tab: AppTab, icon: String, label: String) -> some View {
        Button {
            activeTab = tab
        } label: {
            Label(label, systemImage: icon)
        }
        .buttonStyle(.plain)
        #if os(macOS)
        .tag(tab)
        #endif
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
            "选择一项",
            systemImage: "rectangle.lefthalf.inset.filled",
            description: Text("从列表中选择一个人脉、案件或事件。")
        )
    }
}
