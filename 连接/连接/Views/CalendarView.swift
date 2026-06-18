import SwiftUI
import SwiftData

/// 日历主视图——月/周视图切换 + 统计 + 日期点击
struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query var allKeyEvents: [KeyEvent]
    @Query(sort: \CaseRecord.caseName) var allCases: [CaseRecord]

    @State private var viewModel = CalendarViewModel()
    @State private var showDaySheet = false
    @State private var showAddEvent = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 统计条
                statsBar

                // 月份导航
                monthHeader

                // 星期头
                weekdayHeader

                // 日历网格
                monthGrid

                Divider()

                // 底部：选中日事件列表
                if let selected = viewModel.selectedDate {
                    selectedDayEvents(selected)
                } else {
                    upcomingEvents
                }
            }
            .navigationTitle("日历")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAddEvent = true } label: {
                        Image(systemName: "plus")
                    }
                    .keyboardShortcut("n", modifiers: .command)
                }
                ToolbarItem(placement: .secondaryAction) {
                    Picker("视图", selection: $viewModel.viewMode) {
                        ForEach(CalendarViewModel.ViewMode.allCases, id: \.self) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                }
            }
            .sheet(isPresented: $showDaySheet) {
                if let date = viewModel.selectedDate {
                    DayEventsSheet(date: date, events: viewModel.events(for: date))
                }
            }
            .sheet(isPresented: $showAddEvent) {
                KeyEventEditView()
            }
            .onReceive(NotificationCenter.default.publisher(for: .newItemRequested)) { notif in
                if let tab = notif.object as? AppTab, tab == .calendar {
                    showAddEvent = true
                }
            }
            .onAppear { viewModel.loadEvents(allKeyEvents) }
            .onChange(of: allKeyEvents) { _, new in viewModel.loadEvents(new) }
        }
    }

    // MARK: - 统计条

    private var statsBar: some View {
        HStack(spacing: 24) {
            StatItem(value: "\(viewModel.eventsThisMonth)", label: "本月事件", color: .blue)
            StatItem(value: "\(viewModel.hearingsThisMonth)", label: "开庭", color: .red)
            StatItem(value: "\(allCases.filter(\.caseStage.isActive).count)", label: "进行中", color: .orange)
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(.bar)
    }

    // MARK: - 月份头部

    private var monthHeader: some View {
        HStack {
            Button { viewModel.goToPreviousMonth() } label: {
                Image(systemName: "chevron.left")
            }

            Spacer()

            Button(viewModel.monthTitle) {
                viewModel.goToToday()
            }
            .font(.headline)

            Spacer()

            Button { viewModel.goToNextMonth() } label: {
                Image(systemName: "chevron.right")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .buttonStyle(.plain)
    }

    // MARK: - 星期头

    private var weekdayHeader: some View {
        let weekdays: [String] = ["一", "二", "三", "四", "五", "六", "日"]
        return HStack {
            ForEach(weekdays, id: \.self) { day in
                Text(day)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - 月网格

    private var monthGrid: some View {
        VStack(spacing: 2) {
            ForEach(0..<viewModel.monthGrid.count, id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(0..<7, id: \.self) { col in
                        if let date = viewModel.monthGrid[row][col] {
                            dayCell(date)
                        } else {
                            Color.clear
                                .frame(maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - 日期格

    private func dayCell(_ date: Date) -> some View {
        let isToday = Calendar.current.isDateInToday(date)
        let isSelected = viewModel.selectedDate.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? false
        let dots = viewModel.dotColors(for: date)

        return Button {
            withAnimation {
                viewModel.selectedDate = (viewModel.selectedDate.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? false) ? nil : date
            }
        } label: {
            VStack(spacing: 2) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.caption.weight(isToday ? .bold : .regular))
                    .frame(width: 24, height: 24)
                    .background(isToday ? Color.blue : (isSelected ? Color.blue.opacity(0.15) : .clear))
                    .foregroundStyle(isToday ? .white : (isSelected ? .blue : .primary))
                    .clipShape(.circle)

                // 事件颜色点
                if !dots.isEmpty {
                    HStack(spacing: 2) {
                        ForEach(0..<dots.count, id: \.self) { i in
                            Circle()
                                .fill(dots[i])
                                .frame(width: 4, height: 4)
                        }
                    }
                } else {
                    Color.clear.frame(height: 4)
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 选中日事件

    private func selectedDayEvents(_ date: Date) -> some View {
        let events = viewModel.events(for: date)
        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(date.formatted(.dateTime.month().day().weekday(.wide).locale(Locale(identifier: "zh_CN"))))
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text("\(events.count) 个事件")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.top, 8)

            if events.isEmpty {
                Text("暂无事件")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                List(events) { event in
                    calendarEventRow(event)
                }
                .listStyle(.plain)
                .frame(maxHeight: 200)
            }
        }
        .background(.bar)
    }

    // MARK: - 近期事件

    private var upcomingEvents: some View {
        let upcoming = allKeyEvents
            .filter { Calendar.current.isDate($0.date, inSameDayAs: Date()) || $0.date > Date() }
            .sorted(by: { $0.date < $1.date })
            .prefix(8)

        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("即将到来")
                    .font(.subheadline.weight(.medium))
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 8)

            if upcoming.isEmpty {
                Text("暂无即将到来的事件")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                List(Array(upcoming)) { event in
                    calendarEventRow(event)
                }
                .listStyle(.plain)
                .frame(maxHeight: 200)
            }
        }
        .background(.bar)
    }

    private func calendarEventRow(_ event: KeyEvent) -> some View {
        let hex = CalendarViewModel.colorHex(for: event.eventType)
        return HStack(spacing: 10) {
            Circle()
                .fill(Color(hex: hex))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.subheadline.weight(.medium))
                if let caseName = event.caseRecord?.caseName {
                    Text(caseName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(event.eventType.rawValue)
                .font(.caption2.weight(.medium))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color(hex: hex).opacity(0.1))
                .foregroundStyle(Color(hex: hex))
                .clipShape(.capsule)
        }
        .contextMenu {
            Button {
                NotificationCenter.default.post(name: .editKeyEventRequested, object: event)
            } label: {
                Label("编辑", systemImage: "pencil")
            }

            Divider()

            Button(role: .destructive) {
                deleteEvent(event)
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                deleteEvent(event)
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
    }

    // MARK: - 删除事件

    private func deleteEvent(_ event: KeyEvent) {
        NotificationService.shared.cancelAll(for: event)
        event.caseRecord?.keyEvents?.removeAll { $0.id == event.id }
        modelContext.delete(event)
        try? modelContext.save()
        // 刷新选中日事件
        if let selected = viewModel.selectedDate {
            viewModel.loadEvents(allKeyEvents)
            // 如果当天没事件了，自动收起
            if viewModel.events(for: selected).isEmpty {
                viewModel.selectedDate = nil
            }
        }
    }
}

// MARK: - 统计项

struct StatItem: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
    }
}
