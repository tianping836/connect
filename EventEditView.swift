import SwiftUI
import SwiftData

/// 新建/编辑事件表单
struct EventEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subManager: SubscriptionManager
    var existingEvent: Event? = nil
    var defaultCase: Case? = nil
    @State private var title = ""
    @State private var eventType: EventType = .other
    @State private var status: EventStatus = .planned
    @State private var date: Date = Date()
    @State private var hasDate: Bool = true
    @State private var isAllDay: Bool = true
    @State private var hasEndDate: Bool = false
    @State private var endDate: Date = Date()
    @State private var location = ""
    @State private var summary = ""
    @State private var notes = ""
    @State private var shouldRemind: Bool = false
    @State private var reminderOffset: TimeInterval = 0
    @State private var alertLevel: AlertLevel = .reminder
    @State private var syncToCalendar: Bool = false
    @State private var selectedPersons: [Person] = []
    @State private var showPersonPicker = false
    @State private var selectedCases: [Case] = []
    @State private var showCasePicker = false
    @State private var isDropTargeted = false
    @Query(sort: \Person.name) private var allPersons: [Person]
    @Query(sort: \Case.name) private var allCases: [Case]
    @AppStorage("caseModuleEnabled") private var caseModuleEnabled: Bool = true
    private var isEditing: Bool { existingEvent != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("事件标题", text: $title).textContentType(.none)
                    Picker("类型", selection: $eventType) {
                        ForEach(EventType.allCases) { type in
                            Label(type.rawValue, systemImage: type.systemImage).tag(type)
                        }
                    }
                    if isEditing {
                        Picker("状态", selection: $status) {
                            ForEach(EventStatus.allCases) { s in Text(s.rawValue).tag(s) }
                        }
                    }
                }
                Section("日期时间") {
                    Toggle("设置日期", isOn: $hasDate)
                    if hasDate {
                        QuickDatePicker(date: $date, hasDate: $hasDate, isAllDay: isAllDay)
                        Toggle("全天事件", isOn: $isAllDay)
                        Toggle("结束日期", isOn: $hasEndDate)
                        if hasEndDate { DatePicker("结束日期", selection: $endDate, displayedComponents: [.date]) }
                    }
                    Toggle("提前提醒", isOn: $shouldRemind)
                        .onChange(of: shouldRemind) { _, newValue in
                            if newValue && reminderOffset == 0 {
                                reminderOffset = (eventType == .hearing || eventType == .deadline) ? 86_400 : 1_800
                            }
                        }
                    if shouldRemind {
                        Picker("提醒时间", selection: $reminderOffset) {
                            Text("事件开始时").tag(0.0); Text("提前 5 分钟").tag(300.0)
                            Text("提前 15 分钟").tag(900.0); Text("提前 30 分钟").tag(1_800.0)
                            Text("提前 1 小时").tag(3_600.0); Text("提前 1 天").tag(86_400.0)
                            Text("提前 2 天").tag(172_800.0)
                        }
                        Picker("提醒级别", selection: $alertLevel) {
                            ForEach(AlertLevel.allCases) { level in
                                Label(level.rawValue, systemImage: level.systemImage).tag(level)
                            }
                        }
                    }
                    if caseModuleEnabled {
                        Toggle("同步到系统日历", isOn: $syncToCalendar)
                            .onChange(of: hasDate) { _, newValue in if !newValue { syncToCalendar = false } }
                    }
                }
                Section("地点与描述") {
                    TextField("地点（选填）", text: $location).textContentType(.fullStreetAddress)
                    TextField("事件描述（选填）", text: $summary, axis: .vertical).lineLimit(2...5).textContentType(.none)
                }
                Section { if selectedPersons.isEmpty {
                    Button { showPersonPicker = true } label: {
                        Label("添加参与人", systemImage: "person.badge.plus")
                    }.foregroundColor(.tealLink)
                } else {
                    ForEach(selectedPersons, id: \.id) { person in
                        HStack {
                            if let primaryRole = person.roleTypes.first { AvatarPlaceholder(roleType: primaryRole, size: 32) }
                            VStack(alignment: .leading) { Text(person.name).font(.cnHeadline); if let org = person.org { Text(org).font(.cnCaption1).foregroundColor(.textSecondary) } }
                            Spacer()
                        }
                    }.onDelete { indices in selectedPersons.remove(atOffsets: indices) }
                    Button { showPersonPicker = true } label: { Label("添加更多参与人", systemImage: "plus") }.foregroundColor(.tealLink)
                } } header: { Text("参与人") }
                if caseModuleEnabled {
                    Section { if selectedCases.isEmpty {
                        Button { showCasePicker = true } label: { Label("关联案件（选填）", systemImage: "link") }.foregroundColor(.tealLink)
                    } else {
                        ForEach(selectedCases, id: \.id) { c in
                            HStack { Image(systemName: c.caseType.systemImage).foregroundColor(.textSecondary); VStack(alignment: .leading) { Text(c.name).font(.cnHeadline); if let caseNumber = c.caseNumber { Text(caseNumber).font(.cnCaption1).foregroundColor(.textSecondary) } }; Spacer() }
                        }.onDelete { indices in selectedCases.remove(atOffsets: indices) }
                        Button { showCasePicker = true } label: { Label("关联更多案件", systemImage: "plus") }.foregroundColor(.tealLink)
                    } } header: { Text("关联案件") }
                }
                Section("备注") { TextField("私有备注（选填）", text: $notes, axis: .vertical).lineLimit(2...5).textContentType(.none) }
            }
            .scrollContentBackground(.hidden).background(Color.surfaceLight)
            .navigationTitle(isEditing ? "编辑事件" : "新建事件").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("保存") { saveEvent() }.fontWeight(.semibold).disabled(title.trimmingCharacters(in: .whitespaces).isEmpty) }
            }
            .sheet(isPresented: $showPersonPicker) { personPickerSheet }
            .sheet(isPresented: $showCasePicker) { casePickerSheet }
            .onAppear { loadExistingEvent(); applySmartDefaults() }
            .onChange(of: selectedCases) { _, newCases in
                if !isEditing && !newCases.isEmpty && eventType == .other { eventType = .hearing; shouldRemind = true; reminderOffset = 86_400; alertLevel = .critical }
            }
            .dropDestination(for: String.self) { items, _ in handleDroppedPersonIDs(items); return true } isTargeted: { targeted in isDropTargeted = targeted }
        }
    }
    private func handleDroppedPersonIDs(_ ids: [String]) {
        let allPersonIDs = Set(ids); let existingIDs = Set(selectedPersons.map { $0.id })
        let newPersons = allPersons.filter { allPersonIDs.contains($0.id) && !existingIDs.contains($0.id) }
        selectedPersons.append(contentsOf: newPersons)
    }
    private func loadExistingEvent() {
        guard let event = existingEvent else { return }
        title = event.title; eventType = event.eventType; status = event.status
        if let d = event.date { date = d; hasDate = true } else { hasDate = false }
        isAllDay = event.isAllDay; if let ed = event.endDate { endDate = ed; hasEndDate = true }
        location = event.location ?? ""; summary = event.summary ?? ""; notes = event.notes ?? ""
        shouldRemind = event.shouldRemind; reminderOffset = event.reminderOffset ?? 0; alertLevel = event.alertLevel
        selectedPersons = event.participants; selectedCases = event.linkedCases
    }
    private func applySmartDefaults() {
        guard !isEditing else { return }
        if let dc = defaultCase {
            if !selectedCases.contains(where: { $0.id == dc.id }) { selectedCases = [dc] }
            eventType = .hearing; shouldRemind = true; reminderOffset = 86_400; alertLevel = .critical
        }
    }
    private func saveEvent() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else { return }
        if !isEditing && !subManager.canAddCaseOrEvent { subManager.showUpgradeSheet = true; return }
        let savedEvent: Event
        if let event = existingEvent {
            event.title = trimmedTitle; event.eventType = eventType; event.status = status
            event.date = hasDate ? date : nil; event.endDate = hasEndDate ? endDate : nil; event.isAllDay = isAllDay
            event.location = location.trimmingCharacters(in: .whitespaces).isEmpty ? nil : location
            event.summary = summary.trimmingCharacters(in: .whitespaces).isEmpty ? nil : summary
            event.notes = notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes
            event.shouldRemind = shouldRemind; event.reminderOffset = shouldRemind ? reminderOffset : nil
            event.alertLevel = alertLevel; event.updatedAt = Date()
            updateEventPersons(for: event); updateEventCases(for: event); savedEvent = event
        } else {
            let event = Event(title: trimmedTitle, eventType: eventType, status: .planned, date: hasDate ? date : nil, endDate: hasEndDate ? endDate : nil, isAllDay: isAllDay, location: location.trimmingCharacters(in: .whitespaces).isEmpty ? nil : location, summary: summary.trimmingCharacters(in: .whitespaces).isEmpty ? nil : summary, notes: notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes, shouldRemind: shouldRemind)
            event.reminderOffset = shouldRemind ? reminderOffset : nil; event.alertLevel = alertLevel
            modelContext.insert(event); updateEventPersons(for: event); updateEventCases(for: event); savedEvent = event
        }
        try? modelContext.save()
        if !isEditing { OnboardingManager.shared.mark(.firstEventAdded); if eventType == .hearing { OnboardingManager.shared.mark(.firstHearingAdded) } }
        if shouldRemind { NotificationManager.shared.scheduleReminder(for: savedEvent) } else { NotificationManager.shared.cancelReminder(for: savedEvent) }
        if hasDate && syncToCalendar { CalendarSyncManager.shared.syncToSystemCalendar(event: savedEvent) } else if !syncToCalendar { CalendarSyncManager.shared.removeFromSystemCalendar(event: savedEvent) }
        dismiss()
    }
    private func updateEventPersons(for event: Event) {
        event.eventPersons.forEach { modelContext.delete($0) }
        for (index, person) in selectedPersons.enumerated() { let ep = EventPerson(person: person, event: event, role: "参与者"); ep.sortOrder = index; modelContext.insert(ep) }
    }
    private func updateEventCases(for event: Event) {
        event.eventCases.forEach { modelContext.delete($0) }
        for c in selectedCases { let ec = EventCase(event: event, case: c); modelContext.insert(ec) }
    }
    private var personPickerSheet: some View {
        NavigationStack {
            List { ForEach(allPersons, id: \.id) { person in
                Button { if !selectedPersons.contains(where: { $0.id == person.id }) { selectedPersons.append(person) } } label: {
                    HStack { if let primaryRole = person.roleTypes.first { AvatarPlaceholder(roleType: primaryRole, size: 36) }; VStack(alignment: .leading, spacing: 2) { Text(person.name).font(.cnHeadline).foregroundColor(.textPrimary); if let org = person.org { Text(org).font(.cnCaption1).foregroundColor(.textSecondary) } }; Spacer(); if selectedPersons.contains(where: { $0.id == person.id }) { Image(systemName: "checkmark").foregroundColor(.tealLink) } }
                }
            } }.listStyle(.insetGrouped).navigationTitle("选择参与人").toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { showPersonPicker = false } } }
        }
    }
    private var casePickerSheet: some View {
        NavigationStack {
            List { ForEach(allCases, id: \.id) { c in
                Button { if !selectedCases.contains(where: { $0.id == c.id }) { selectedCases.append(c) } else { selectedCases.removeAll { $0.id == c.id } } } label: {
                    HStack { Image(systemName: c.caseType.systemImage).foregroundColor(.textSecondary); VStack(alignment: .leading, spacing: 2) { Text(c.name).font(.cnHeadline).foregroundColor(.textPrimary); if let caseNumber = c.caseNumber { Text(caseNumber).font(.cnCaption1).foregroundColor(.textSecondary) } }; Spacer(); if selectedCases.contains(where: { $0.id == c.id }) { Image(systemName: "checkmark").foregroundColor(.tealLink) } }
                }
            } }.listStyle(.insetGrouped).navigationTitle("关联案件").toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { showCasePicker = false } } }
        }
    }
}