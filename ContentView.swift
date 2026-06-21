import SwiftUI
import SwiftData

/// App 根导航 — 4 Tab 布局
/// 人脉 | 事项 | 日历 | 设置
/// 「事项」Tab 内嵌分段选择器切换事件/案件
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("caseModuleEnabled") private var caseModuleEnabled: Bool = true
    @SceneStorage("selectedTab") private var selectedTab = 0
    @SceneStorage("lastViewedPersonID") private var lastViewedPersonID: String?
    @SceneStorage("lastViewedCaseID") private var lastViewedCaseID: String?
    @SceneStorage("lastViewedEventID") private var lastViewedEventID: String?
    @State private var mattersSegment: MattersSegment = .events

    // MARK: iPad 键盘快捷键
    @State private var showNewEventSheet = false
    @State private var showNewPersonSheet = false

    /// 跨平台宽屏判断：iPad 和 Mac 走侧栏布局，iPhone 走 TabView
    private var isPadOrMac: Bool {
        #if os(macOS)
        return true
        #else
        return UIDevice.current.userInterfaceIdiom == .pad
            || UIDevice.current.userInterfaceIdiom == .mac
        #endif
    }

    enum MattersSegment: String, CaseIterable {
        case events = "事件"
        case cases = "案件"
    }

    var body: some View {
        Group {
            if isPadOrMac {
                iPadLayout
            } else {
                iPhoneLayout
            }
        }
        .onAppear {
            NotificationManager.shared.requestAuthorization()
            CalendarSyncManager.shared.requestCalendarAccess()
            SpotlightIndexManager.shared.rebuildAllIndices(modelContext: modelContext)
            OnboardingManager.shared.mark(.firstLaunch)
        }
        .onKeyPress(.tab, modifiers: .command) {
            return .ignored
        }
        .onKeyPress(keys: ["1", "2", "3", "4"], phases: .down) { press in
            guard press.modifiers == .command else { return .ignored }
            switch press.characters {
            case "1": selectedTab = 0
            case "2": selectedTab = 1
            case "3": selectedTab = 2
            case "4": selectedTab = 3
            default: break
            }
            return .handled
        }
        .onKeyPress("n", modifiers: .command) {
            switch selectedTab {
            case 0: showNewPersonSheet = true
            case 1, 2: showNewEventSheet = true
            default: showNewEventSheet = true
            }
            return .handled
        }
        .onKeyPress("f", modifiers: .command) {
            NotificationCenter.default.post(name: .islandLinkFocusSearch, object: nil)
            return .handled
        }
        .onboardingGuides()
        .sheet(isPresented: $showNewEventSheet) {
            EventEditView()
        }
        .sheet(isPresented: $showNewPersonSheet) {
            PersonEditPlaceholderView()
        }
    }

    static let focusSearchNotification = Notification.Name("islandLinkFocusSearch")

    // MARK: - iPhone 布局（TabView）

    private var iPhoneLayout: some View {
        TabView(selection: $selectedTab) {
            PersonListView()
                .tabItem {
                    Label("人脉", systemImage: "person.2.fill")
                        .environment(\.symbolVariants, .none)
                }
                .tag(0)

            mattersTab
                .tabItem {
                    Label("事项", systemImage: "list.bullet.rectangle.fill")
                        .environment(\.symbolVariants, .none)
                }
                .tag(1)

            CalendarView()
                .tabItem {
                    Label("日历", systemImage: "calendar.fill")
                        .environment(\.symbolVariants, .none)
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape.fill")
                        .environment(\.symbolVariants, .none)
                }
                .tag(3)
        }
        .tint(.tealLink)
        .toolbarBackground(.regularMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }

    // MARK: - iPad 布局（NavigationSplitView 侧栏）

    private var iPadLayout: some View {
        NavigationSplitView {
            sidebarContent
                .navigationSplitViewColumnWidth(220)
        } content: {
            sidebarDetailContent
                .navigationSplitViewColumnWidth(320)
        } detail: {
            Text("选择一项查看详情")
                .font(.cnBody)
                .foregroundColor(.textTertiary)
        }
        .navigationSplitViewStyle(.balanced)
    }

    private var sidebarContent: some View {
        List(selection: $selectedTab) {
            Section {
                Label("人脉", systemImage: "person.2.fill")
                    .tag(0)
                Label("事项", systemImage: "list.bullet.rectangle.fill")
                    .tag(1)
                Label("日历", systemImage: "calendar.fill")
                    .tag(2)
                Label("设置", systemImage: "gearshape.fill")
                    .tag(3)
            } header: {
                Label("屿连", systemImage: "dolphin.fill")
                    .font(.cnTitle2)
                    .foregroundColor(.oceanDeep)
                    .textCase(nil)
                    .padding(.bottom, Spacing.sm)
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(.regularMaterial)
    }

    @ViewBuilder
    private var sidebarDetailContent: some View {
        switch selectedTab {
        case 0: PersonListView()
        case 1: mattersContent
        case 2: CalendarView()
        case 3: SettingsView()
        default: PersonListView()
        }
    }

    // MARK: - 「事项」Tab

    private var mattersTab: some View {
        NavigationStack {
            VStack(spacing: 0) {
                OverviewCard(data: OverviewCardData(modelContext: modelContext))

                mattersSegmentPicker
                    .padding(.horizontal, Spacing.base)
                    .padding(.top, Spacing.sm)
                    .padding(.bottom, Spacing.sm)

                mattersContent
            }
            .background(Color.surfaceLight)
            .navigationTitle("事项")
        }
    }

    private var mattersSegmentPicker: some View {
        let segments = caseModuleEnabled
            ? MattersSegment.allCases
            : [MattersSegment.events]

        return HStack(spacing: 0) {
            ForEach(segments, id: \.self) { segment in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        mattersSegment = segment
                    }
                } label: {
                    Text(segment.rawValue)
                        .font(.cnSubhead)
                        .fontWeight(mattersSegment == segment ? .semibold : .regular)
                        .foregroundColor(mattersSegment == segment ? .white : .textSecondary)
                        .padding(.vertical, Spacing.sm)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.button)
                                .fill(mattersSegment == segment ? Color.tealLink : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Spacing.xs)
        .background(Color.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button))
    }

    @ViewBuilder
    private var mattersContent: some View {
        if matterSegmentsVisible.count > 1 {
            TabView(selection: $mattersSegment) {
                EventListView()
                    .tag(MattersSegment.events)

                if caseModuleEnabled {
                    CaseListView()
                        .tag(MattersSegment.cases)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        } else {
            EventListView()
        }
    }

    private var matterSegmentsVisible: [MattersSegment] {
        caseModuleEnabled ? MattersSegment.allCases : [.events]
    }
}

// MARK: - 案件列表页（内嵌到事项 Tab）

struct CaseListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Case.updatedAt, order: .reverse)
    private var allCases: [Case]

    @State private var selectedStatus: CaseStatus? = nil
    @State private var searchText = ""

    @StateObject private var focusFilter = FocusFilterObserver()

    var body: some View {
        VStack(spacing: 0) {
            FocusFilterIndicator(filterObserver: focusFilter)
                .padding(.top, Spacing.sm)

            SearchBar(text: $searchText, placeholder: "搜索案件名称、案号...")
                .padding(.horizontal, Spacing.base)
                .padding(.vertical, Spacing.sm)

            statusCapsuleBar

            ScrollView {
                LazyVStack(spacing: Spacing.md) {
                    ForEach(groupedCases, id: \.status) { group in
                        sectionHeader(group.status.rawValue, count: group.items.count)

                        ForEach(Array(group.items.enumerated()), id: \.element.id) { index, caseItem in
                            NavigationLink {
                                CaseDetailPlaceholderView(caseItem: caseItem)
                            } label: {
                                CaseCard(caseItem: caseItem)
                            }
                            .buttonStyle(.plain)
                            .staggerEntrance(index: index)
                        }
                    }

                    if filteredCases.isEmpty {
                        emptyStateView
                    }
                }
                .padding(.horizontal, Spacing.base)
                .padding(.vertical, Spacing.md)
            }
            .background(Color.surfaceLight)
        }
        .background(Color.surfaceLight)
    }

    private var statusCapsuleBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                StatusCapsule(
                    status: .consulting,
                    count: filteredCases.count,
                    isSelected: selectedStatus == nil
                )
                .overlay(
                    Text("全部")
                        .font(.cnSubhead)
                        .foregroundColor(selectedStatus == nil ? .white : .textSecondary)
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedStatus = nil
                    }
                }

                ForEach(CaseStatus.allCases) { status in
                    let count = allCases.filter { $0.caseStatus == status }.count
                    StatusCapsule(
                        status: status,
                        count: count,
                        isSelected: selectedStatus == status
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedStatus = (selectedStatus == status) ? nil : status
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.base)
            .padding(.vertical, Spacing.sm)
        }
    }

    private var filteredCases: [Case] {
        var result = allCases.filter { !$0.isArchived }

        if let status = selectedStatus {
            result = result.filter { $0.caseStatus == status }
        }

        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            let q = searchText.lowercased()
            result = result.filter {
                $0.name.localizedStandardContains(q) ||
                ($0.caseNumber?.localizedStandardContains(q) ?? false) ||
                ($0.court?.localizedStandardContains(q) ?? false)
            }
        }

        result = focusFilter.filterCases(result)

        return result
    }

    private var groupedCases: [(status: CaseStatus, items: [Case])] {
        let grouped = Dictionary(grouping: filteredCases) { $0.caseStatus }
        return CaseStatus.allCases.compactMap { status in
            guard let items = grouped[status], !items.isEmpty else { return nil }
            return (status, items)
        }
    }

    @ViewBuilder
    private func sectionHeader(_ title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(.cnTitle3)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)
            Spacer()
            Text("\(count)")
                .font(.cnSubhead)
                .foregroundColor(.textTertiary)
        }
        .padding(.top, Spacing.lg)
    }

    private var emptyStateView: some View {
        VStack(spacing: Spacing.base) {
            Spacer().frame(height: 60)
            Image(systemName: "folder.fill")
                .font(.system(size: 48))
                .foregroundColor(.tealLink.opacity(0.6))
            Text("还没有案件")
                .font(.cnHeadline)
                .foregroundColor(.textPrimary)
            Text(searchText.isEmpty
                ? "添加你的第一个案件，开始管理人脉关联"
                : "没有匹配的案件，试试换个关键词")
                .font(.cnBody)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xxl)
        }
    }
}

// MARK: - 案件详情页（含时间线入口）

struct CaseDetailPlaceholderView: View {
    let caseItem: Case

    @State private var showTimeline = false
    @State private var caseEventsCount = 0
    @State private var caseNotesCount = 0
    @State private var showNewEventSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.base) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    StatusBadge(status: caseItem.caseStatus)
                    Text(caseItem.name)
                        .font(.cnTitle2)
                        .foregroundColor(.textPrimary)
                    if let caseNumber = caseItem.caseNumber {
                        Text(caseNumber)
                            .font(.cnMonoFootnote)
                            .foregroundColor(.textSecondary)
                    }
                    if let court = caseItem.court {
                        Label(court, systemImage: "building.2")
                            .font(.cnSubhead)
                            .foregroundColor(.textSecondary)
                    }
                    if let summary = caseItem.summary {
                        Divider()
                        Text(summary)
                            .font(.cnBody)
                            .foregroundColor(.textPrimary)
                    }
                }
                .padding(Spacing.base)
                .cardStyleSolid()

                timelineEntryCard

                if !caseItem.personsByRole.isEmpty {
                    RoleGroupSection(groupedPersons: caseItem.personsByRole)
                }
            }
            .padding(.horizontal, Spacing.base)
            .padding(.vertical, Spacing.md)
        }
        .background(Color.surfaceLight)
        .navigationTitle("案件详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showNewEventSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.tealLink)
                }
                .accessibilityLabel("添加事件")
            }
        }
        .sheet(isPresented: $showTimeline) {
            NavigationStack {
                CaseTimelineView(caseItem: caseItem)
            }
        }
        .sheet(isPresented: $showNewEventSheet) {
            EventEditView(defaultCase: caseItem)
        }
        .onAppear {
            caseEventsCount = caseItem.events.count
            caseNotesCount = caseItem.caseNotes.count
        }
    }

    private var timelineEntryCard: some View {
        let total = caseEventsCount + caseNotesCount

        return Button {
            showTimeline = true
            OnboardingManager.shared.mark(.firstConnectionExplored)
        } label: {
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.tealLink.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.tealLink)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("案件时间线")
                        .font(.cnHeadline)
                        .foregroundColor(.textPrimary)

                    Text(total > 0
                        ? "\(caseEventsCount) 个事件 · \(caseNotesCount) 条笔记"
                        : "添加开庭、举证期限或笔记，记录案件进展")
                        .font(.cnCaption1)
                        .foregroundColor(.textTertiary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.textTertiary)
            }
            .padding(Spacing.base)
            .cardStyleSolid()
        }
        .buttonStyle(.plain)
    }
}