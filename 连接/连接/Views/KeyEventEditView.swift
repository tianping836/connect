import SwiftUI
import SwiftData

/// 创建 / 编辑大事记（关联到案件）
struct KeyEventEditView: View {
    var event: KeyEvent? = nil
    var preselectedDate: Date? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \CaseRecord.caseName) var allCases: [CaseRecord]

    @State private var selectedCase: CaseRecord?
    @State private var eventType: KeyEventType = .courtHearing
    @State private var title = ""
    @State private var detail = ""
    @State private var date: Date
    @State private var reminderEnabled = true
    @State private var reminderDays: [Int] = [7, 3, 1]
    @State private var showDeleteConfirm = false

    private var isEditing: Bool { event != nil }

    init(event: KeyEvent? = nil, preselectedDate: Date? = nil) {
        self.event = event
        self.preselectedDate = preselectedDate
        _date = State(initialValue: preselectedDate ?? Date())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("事件") {
                    Picker("类型", selection: $eventType) {
                        ForEach(KeyEventType.allCases) { t in
                            HStack {
                                Circle()
                                    .fill(Color(hex: CalendarViewModel.colorHex(for: t)))
                                    .frame(width: 8, height: 8)
                                Text(t.rawValue)
                            }.tag(t)
                        }
                    }

                    TextField("标题 *", text: $title)
                }

                Section("案件 & 日期") {
                    Picker("关联案件", selection: $selectedCase) {
                        Text("无").tag(nil as CaseRecord?)
                        ForEach(allCases) { c in Text(c.caseName).tag(c as CaseRecord?) }
                    }

                    DatePicker("日期", selection: $date, displayedComponents: .date)
                }

                Section("详情") {
                    TextField("详情", text: $detail, axis: .vertical)
                        .lineLimit(3)
                }

                Section("提醒") {
                    Toggle("启用提醒", isOn: $reminderEnabled)

                    if reminderEnabled {
                        reminderDaysPicker
                            .listRowInsets(.init(top: 4, leading: 0, bottom: 4, trailing: 0))
                    }
                }
            }
            .navigationTitle(isEditing ? "编辑" : "新建事件")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .destructiveAction) {
                    if isEditing {
                        Button(role: .destructive) { showDeleteConfirm = true } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { saveEvent() }.disabled(title.isEmpty)
                }
            }
            .alert("删除此事件？", isPresented: $showDeleteConfirm) {
                Button("删除", role: .destructive) { deleteEvent() }
                Button("取消", role: .cancel) {}
            } message: {
                Text("事件「\(event?.title ?? "")」及其提醒将被删除。")
            }
            .onAppear { loadExisting() }
        }
    }

    // MARK: - 提醒天数选择

    private var reminderDaysPicker: some View {
        HStack(spacing: 12) {
            ForEach([1, 3, 7, 14, 30], id: \.self) { day in
                Button {
                    if reminderDays.contains(day) {
                        reminderDays.removeAll { $0 == day }
                    } else {
                        reminderDays.append(day)
                        reminderDays.sort(by: >)
                    }
                } label: {
                    Text("\(day)天")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(reminderDays.contains(day) ? Color.blue.opacity(0.15) : Color.secondary.opacity(0.1))
                        .foregroundStyle(reminderDays.contains(day) ? .blue : .secondary)
                        .clipShape(.capsule)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - 保存

    private func saveEvent() {
        let savedEvent: KeyEvent
        if let existing = event {
            existing.eventType = eventType
            existing.title = title
            existing.detail = detail.isEmpty ? nil : detail
            existing.date = date
            existing.caseRecord = selectedCase
            existing.reminderEnabled = reminderEnabled
            existing.reminderDays = reminderEnabled ? reminderDays : []
            if let c = selectedCase { existing.caseRecord = c; c.keyEvents?.append(existing) }
            savedEvent = existing
        } else {
            let newEvent = KeyEvent(
                caseRecord: selectedCase,
                eventType: eventType,
                date: date,
                title: title,
                detail: detail.isEmpty ? nil : detail,
                reminderEnabled: reminderEnabled,
                reminderDays: reminderEnabled ? reminderDays : []
            )
            modelContext.insert(newEvent)
            selectedCase?.keyEvents?.append(newEvent)
            savedEvent = newEvent
        }
        try? modelContext.save()
        // 调度本地通知
        NotificationService.shared.schedule(for: savedEvent)
        dismiss()
    }

    private func deleteEvent() {
        guard let existing = event else { return }
        // 取消该事件的全部通知
        NotificationService.shared.cancelAll(forEventID: existing.id)
        // 从案件关联中移除
        existing.caseRecord?.keyEvents?.removeAll { $0.id == existing.id }
        modelContext.delete(existing)
        try? modelContext.save()
        dismiss()
    }

    private func loadExisting() {
        guard let existing = event else { return }
        selectedCase = existing.caseRecord
        eventType = existing.eventType
        title = existing.title
        detail = existing.detail ?? ""
        date = existing.date
        reminderEnabled = existing.reminderEnabled
        reminderDays = existing.reminderDays
    }
}
