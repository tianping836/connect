import SwiftUI
import SwiftData

/// 事件列表页 — 「事项」Tab 的事件子页
/// 搜索栏 + 类型筛选胶囊 + 即将到来/已完成分组
struct EventListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Event.date, order: .forward)
    private var allEvents: [Event]

    @State private var searchText = ""
    @State private var selectedType: EventType? = nil
    @State private var isSearchFocused = false
    @State private var completionFeedbackTrigger = false
    @State private var eventToDelete: Event?
    @State private var showDeleteAlert = false
    @StateObject private var focusFilter = FocusFilterObserver()
    @State private var searchFocusToken: NSObjectProtocol?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                FocusFilterIndicator(filterObserver: focusFilter).padding(.top, Spacing.sm)
                SearchBar(text: $searchText, placeholder: "搜索你关心的人和事...")
                    .padding(.horizontal, Spacing.base).padding(.top, Spacing.sm).padding(.bottom, Spacing.sm)
                typeFilterBar
                ScrollView {
                    LazyVStack(spacing: Spacing.md) {
                        if !upcomingEvents.isEmpty {
                            sectionHeader("即将到来")
                            ForEach(Array(upcomingEvents.enumerated()), id: \.element.id) { index, event in
                                NavigationLink { EventDetailView(event: event) } label: { EventCard(event: event) }
                                    .buttonStyle(.plain).staggerEntrance(index: index)
                                    .swipeActions(edge: .trailing) {
                                        Button { withAnimation(.easeInOut(duration: 0.3)) { toggleEventCompletion(event) } } label: { Label("标记完成", systemImage: "checkmark.circle") }.tint(.tealLink)
                                        Button(role: .destructive) { eventToDelete = event; showDeleteAlert = true } label: { Label("删除", systemImage: "trash") }.tint(.statusError)
                                    }
                                    .contextMenu {
                                        Button { Clipboard.copy(event.title) } label: { Label("复制标题", systemImage: "doc.on.doc") }
                                        NavigationLink { EventEditView(existingEvent: event) } label: { Label("编辑", systemImage: "pencil") }
                                        Button { withAnimation(.easeInOut(duration: 0.3)) { toggleEventCompletion(event) } } label: { Label("标记完成", systemImage: "checkmark.circle") }
                                    }
                                    #if os(iOS)
                                    .sensoryFeedback(.success, trigger: completionFeedbackTrigger)
                                    #endif
                            }
                        }
                        if !pastEvents.isEmpty {
                            sectionHeader("已完成")
                            ForEach(Array(pastEvents.enumerated()), id: \.element.id) { index, event in
                                NavigationLink { EventDetailView(event: event) } label: { EventCard(event: event) }
                                    .buttonStyle(.plain).staggerEntrance(index: index)
                                    .swipeActions(edge: .trailing) {
                                        Button { withAnimation(.easeInOut(duration: 0.3)) { toggleEventCompletion(event) } } label: { Label("取消完成", systemImage: "arrow.uturn.backward") }.tint(.tealLink)
                                        Button(role: .destructive) { eventToDelete = event; showDeleteAlert = true } label: { Label("删除", systemImage: "trash") }.tint(.statusError)
                                    }
                                    .contextMenu {
                                        Button { Clipboard.copy(event.title) } label: { Label("复制标题", systemImage: "doc.on.doc") }
                                        NavigationLink { EventEditView(existingEvent: event) } label: { Label("编辑", systemImage: "pencil") }
                                        Button { withAnimation(.easeInOut(duration: 0.3)) { toggleEventCompletion(event) } } label: { Label("取消完成", systemImage: "arrow.uturn.backward") }
                                    }
                                    #if os(iOS)
                                    .sensoryFeedback(.success, trigger: completionFeedbackTrigger)
                                    #endif
                            }
                        }
                        if filteredEvents.isEmpty { emptyStateView }
                    }
                    .padding(.horizontal, Spacing.base).padding(.vertical, Spacing.md)
                }
                .background(Color.surfaceLight)
            }
            .background(Color.surfaceLight).navigationTitle("事项")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink { EventEditView() } label: { Image(systemName: "plus.circle.fill").font(.system(size: 22)).foregroundColor(.tealLink) }
                }
            }
            .alert("删除事件", isPresented: $showDeleteAlert, presenting: eventToDelete) { event in
                Button("取消", role: .cancel) {}
                Button("删除", role: .destructive) { deleteEvent(event) }
            } message: { event in Text("确定要删除「\(event.title)」吗？此操作不可撤销。") }
        }
        .onAppear {
            searchFocusToken = NotificationCenter.default.publisher(for: .islandLinkFocusSearch).sink { _ in isSearchFocused = true }
        }
        .onDisappear {
            if let token = searchFocusToken { NotificationCenter.default.removeObserver(token) }
        }
    }

    @ViewBuilder
    private var typeFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                typeFilterChip(label: "全部", systemImage: "tray.full", color: .oceanDeep, isSelected: selectedType == nil) { withAnimation(.easeInOut(duration: 0.2)) { selectedType = nil } }
                ForEach(EventType.allCases) { eventType in
                    typeFilterChip(label: eventType.rawValue, systemImage: eventType.systemImage, color: eventType.swiftUIColor, isSelected: selectedType == eventType) { withAnimation(.easeInOut(duration: 0.2)) { selectedType = (selectedType == eventType) ? nil : eventType } }
                }
            }
            .padding(.horizontal, Spacing.base).padding(.vertical, Spacing.sm)
        }
    }

    private func typeFilterChip(label: String, systemImage: String, color: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: systemImage).font(.system(size: 12, weight: .medium))
                Text(label).font(.cnCaption1)
            }
            .foregroundColor(isSelected ? .white : color).padding(.horizontal, Spacing.md).padding(.vertical, Spacing.sm)
            .background(Capsule(style: .continuous).fill(isSelected ? color : color.opacity(0.12)))
        }.buttonStyle(.plain)
    }

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title).font(.cnTitle3).foregroundColor(.textPrimary)
            Spacer()
            Text("\(title == "即将到来" ? upcomingEvents.count : pastEvents.count)").font(.cnSubhead).foregroundColor(.textTertiary)
        }.padding(.top, Spacing.lg)
    }

    private var emptyStateView: some View {
        VStack(spacing: Spacing.base) {
            Spacer().frame(height: 60)
            Image(systemName: "calendar.badge.plus").font(.system(size: 48)).foregroundColor(.tealLink.opacity(0.6))
            Text(searchText.isEmpty ? "这里会显示你关心的人和事" : "没有匹配的事件").font(.cnHeadline).foregroundColor(.textPrimary)
            Text(searchText.isEmpty ? "记录一次互动，从这里开始" : "试试换个关键词或调整筛选条件").font(.cnBody).foregroundColor(.textSecondary).multilineTextAlignment(.center).padding(.horizontal, Spacing.xxl)
            if searchText.isEmpty {
                NavigationLink { EventEditView() } label: {
                    Text("添加事件").font(.cnHeadline).foregroundColor(.white).padding(.horizontal, Spacing.xl).padding(.vertical, Spacing.md).background(Color.tealLink).clipShape(RoundedRectangle(cornerRadius: CornerRadius.button))
                }.padding(.top, Spacing.sm)
            }
        }
    }

    private var filteredEvents: [Event] {
        var result = allEvents
        if let type = selectedType { result = result.filter { $0.eventType == type } }
        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            let q = searchText.lowercased()
            result = result.filter { $0.title.localizedStandardContains(q) || ($0.location?.localizedStandardContains(q) ?? false) || ($0.summary?.localizedStandardContains(q) ?? false) || $0.participants.contains { $0.name.localizedStandardContains(q) } }
        }
        result = focusFilter.filterEvents(result)
        return result
    }

    private var upcomingEvents: [Event] { filteredEvents.filter { $0.status.isActive } }
    private var pastEvents: [Event] { filteredEvents.filter { !$0.status.isActive } }

    private func toggleEventCompletion(_ event: Event) {
        if event.status == .completed { event.status = .planned } else { event.status = .completed }
        completionFeedbackTrigger.toggle()
    }

    private func deleteEvent(_ event: Event) {
        NotificationManager.shared.cancelReminder(for: event)
        CalendarSyncManager.shared.removeFromSystemCalendar(event: event)
        event.eventPersons.forEach { modelContext.delete($0) }
        event.eventCases.forEach { modelContext.delete($0) }
        modelContext.delete(event)
        try? modelContext.save()
    }
}