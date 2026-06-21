import SwiftUI
import SwiftData

/// 日历页 — 融合 CaseEvent 和 Event 的月视图 + 即将到来列表
struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CaseEvent.date, order: .forward) private var caseEvents: [CaseEvent]
    @Query(sort: \Event.date, order: .forward) private var events: [Event]
    @AppStorage("caseModuleEnabled") private var caseModuleEnabled: Bool = true
    @State private var selectedDate: Date = Date()
    @State private var currentMonth: Date = Date()
    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.base) {
                    statsRow.padding(.horizontal, Spacing.base)
                    monthGridView.padding(.horizontal, Spacing.base)
                    Divider().padding(.vertical, Spacing.sm)
                    selectedDateDetails.padding(.horizontal, Spacing.base)
                    upcomingSection.padding(.horizontal, Spacing.base)
                }.padding(.vertical, Spacing.md)
            }.background(Color.surfaceLight).navigationTitle("日历")
        }
    }

    private var statsRow: some View {
        HStack(spacing: 0) {
            statItem(value: "\(eventsThisMonth.count + (caseModuleEnabled ? caseEventsThisMonth.count : 0))", label: "本月互动"); Spacer()
            Text("·").foregroundColor(.textTertiary); Spacer()
            statItem(value: "\(caseModuleEnabled ? caseEventsThisMonth.filter { $0.eventType == .trial }.count : 0)", label: "开庭"); Spacer()
            Text("·").foregroundColor(.textTertiary); Spacer()
            statItem(value: "\(events.filter { $0.status.isActive }.count)", label: "进行中")
        }.padding(.vertical, Spacing.sm)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 2) { Text(value).font(.cnTitle3.monospacedDigit()).foregroundColor(.textPrimary); Text(label).font(.cnCaption1).foregroundColor(.textTertiary) }
    }

    private var monthGridView: some View {
        let days = daysInMonth()
        let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
        return VStack(spacing: Spacing.sm) {
            HStack {
                Button { withAnimation(.easeInOut(duration: 0.3)) { currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth } } label: { Image(systemName: "chevron.left").font(.system(size: 16, weight: .medium)).foregroundColor(.tealLink) }
                Spacer()
                Text(currentMonth.formatted(.dateTime.year().month(.wide))).font(.cnTitle2).foregroundColor(.textPrimary)
                Spacer()
                Button { withAnimation(.easeInOut(duration: 0.3)) { currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth } } label: { Image(systemName: "chevron.right").font(.system(size: 16, weight: .medium)).foregroundColor(.tealLink) }
            }
            HStack(spacing: 0) { ForEach(weekdaySymbols, id: \.self) { day in Text(day).font(.cnCaption2).foregroundColor(.textTertiary).frame(maxWidth: .infinity) } }
            LazyVGrid(columns: columns, spacing: Spacing.sm) {
                ForEach(days, id: \.self) { date in if let date = date { dayCell(date: date) } else { Color.clear.frame(height: 40) } }
            }
        }.padding(Spacing.base).cardStyleSolid()
    }

    private func dayCell(date: Date) -> some View {
        let isToday = calendar.isDateInToday(date)
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let hasEvents = dayHasEvents(date); let hasCaseEvents = dayHasCaseEvents(date)
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { selectedDate = date }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    if isToday { Circle().fill(Color.tealLink).frame(width: 32, height: 32) }
                    if isSelected && !isToday { Circle().stroke(Color.oceanDeep.opacity(0.4), lineWidth: 2).frame(width: 32, height: 32) }
                    Text("\(calendar.component(.day, from: date))").font(.cnSubhead).foregroundColor(isToday ? .white : (isSelected ? .oceanDeep : .textPrimary))
                }
                HStack(spacing: 2) {
                    if hasEvents { Circle().fill(Color.tealLink).frame(width: 3, height: 3) }
                    if hasCaseEvents && caseModuleEnabled { Circle().fill(Color.coralWarm).frame(width: 3, height: 3) }
                }
            }.frame(height: 44)
        }.buttonStyle(.plain)
    }

    @ViewBuilder
    private var selectedDateDetails: some View {
        let dayEvents = eventsForDate(selectedDate)
        let dayCaseEvents = caseModuleEnabled ? caseEventsForDate(selectedDate) : []
        if !dayEvents.isEmpty || !dayCaseEvents.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(selectedDate.formatted(date: .complete, time: .omitted)).font(.cnTitle3).foregroundColor(.textPrimary)
                ForEach(dayCaseEvents, id: \.id) { ce in
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: ce.eventType.systemImage).font(.system(size: 14)).foregroundColor(.coralWarm)
                        VStack(alignment: .leading, spacing: 2) { Text(ce.title).font(.cnHeadline).foregroundColor(.textPrimary); if let caseName = ce.case?.name { Text(caseName).font(.cnCaption1).foregroundColor(.textSecondary) } }
                        Spacer()
                    }.padding(Spacing.md).background(Color.surfaceCard).clipShape(RoundedRectangle(cornerRadius: CornerRadius.nestedCard))
                }
                ForEach(dayEvents, id: \.id) { event in
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: event.eventType.systemImage).font(.system(size: 14)).foregroundColor(event.eventType.swiftUIColor)
                        VStack(alignment: .leading, spacing: 2) { Text(event.title).font(.cnHeadline).foregroundColor(.textPrimary); if let location = event.location { Text(location).font(.cnCaption1).foregroundColor(.textSecondary) } }
                        Spacer(); EventStatusBadge(status: event.status)
                    }.padding(Spacing.md).background(Color.surfaceCard).clipShape(RoundedRectangle(cornerRadius: CornerRadius.nestedCard))
                }
            }
        } else { emptyDateCell }
    }

    private var emptyDateCell: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "calendar.badge.plus").font(.system(size: 36)).foregroundColor(.tealLink.opacity(0.4))
            Text("这天没有安排").font(.cnHeadline).foregroundColor(.textPrimary)
            Text("添加事件或开庭日期，我们会提前提醒你").font(.cnBody).foregroundColor(.textSecondary).multilineTextAlignment(.center)
            NavigationLink { EventEditView() } label: { Text("添加事件").font(.cnHeadline).foregroundColor(.white).padding(.horizontal, Spacing.xl).padding(.vertical, Spacing.sm).background(Color.tealLink).clipShape(RoundedRectangle(cornerRadius: CornerRadius.button)) }.padding(.top, Spacing.xs)
        }.padding(.vertical, Spacing.xxl)
    }

    private var upcomingSection: some View {
        let upcoming = upcomingItems
        return VStack(alignment: .leading, spacing: Spacing.sm) {
            if !upcoming.isEmpty {
                Text("即将到来").font(.cnTitle3).foregroundColor(.textPrimary).padding(.top, Spacing.base)
                ForEach(upcoming.prefix(10), id: \.id) { item in upcomingItemRow(item) }
            }
        }
    }

    @ViewBuilder
    private func upcomingItemRow(_ item: UpcomingItem) -> some View {
        HStack(spacing: Spacing.md) {
            switch item.source {
            case .caseEvent(let ce): Image(systemName: ce.eventType.systemImage).font(.system(size: 14)).foregroundColor(.coralWarm)
            case .event(let ev): Image(systemName: ev.eventType.systemImage).font(.system(size: 14)).foregroundColor(ev.eventType.swiftUIColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title).font(.cnHeadline).foregroundColor(.textPrimary)
                HStack(spacing: Spacing.sm) {
                    Text(item.date.formatted(.dateTime.month(.abbreviated).day())).font(.cnCaption1).foregroundColor(.textSecondary)
                    if let subtitle = item.subtitle { Text("·").foregroundColor(.textTertiary); Text(subtitle).font(.cnCaption1).foregroundColor(.textTertiary) }
                }
            }
            Spacer()
        }.padding(Spacing.md).background(Color.surfaceCard).clipShape(RoundedRectangle(cornerRadius: CornerRadius.nestedCard)).cardShadow()
    }

    private var weekdaySymbols: [String] { let formatter = DateFormatter(); formatter.locale = Locale(identifier: "zh_CN"); return formatter.veryShortWeekdaySymbols }

    private func daysInMonth() -> [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: currentMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)) else { return [] }
        let firstWeekday = calendar.component(.weekday, from: firstDay) - 1
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        for day in 1...range.count { if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) { days.append(date) } }
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }

    private func dayHasEvents(_ date: Date) -> Bool { events.contains { event in if let eventDate = event.date { return calendar.isDate(eventDate, inSameDayAs: date) }; return false } }
    private func dayHasCaseEvents(_ date: Date) -> Bool { caseEvents.contains { ce in calendar.isDate(ce.date, inSameDayAs: date) } }
    private func eventsForDate(_ date: Date) -> [Event] { events.filter { event in if let eventDate = event.date { return calendar.isDate(eventDate, inSameDayAs: date) }; return false } }
    private func caseEventsForDate(_ date: Date) -> [CaseEvent] { caseEvents.filter { calendar.isDate($0.date, inSameDayAs: date) } }
    private var eventsThisMonth: [Event] { events.filter { event in if let eventDate = event.date { return calendar.isDate(eventDate, equalTo: currentMonth, toGranularity: .month) }; return false } }
    private var caseEventsThisMonth: [CaseEvent] { caseEvents.filter { calendar.isDate($0.date, equalTo: currentMonth, toGranularity: .month) } }

    private var upcomingItems: [UpcomingItem] {
        var items: [UpcomingItem] = []
        for ce in caseEvents where !ce.isCompleted && ce.date > Date() { items.append(UpcomingItem(id: "ce-\(ce.id)", title: ce.title, date: ce.date, subtitle: ce.case?.name, source: .caseEvent(ce))) }
        for ev in events where ev.status.isActive { if let date = ev.date, date > Date() { items.append(UpcomingItem(id: "ev-\(ev.id)", title: ev.title, date: date, subtitle: ev.location, source: .event(ev))) } }
        return items.sorted { $0.date < $1.date }
    }
}

struct UpcomingItem: Identifiable {
    let id: String; let title: String; let date: Date; let subtitle: String?
    enum Source { case caseEvent(CaseEvent); case event(Event) }
    let source: Source
}