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

    private var isEditing: Bool { event != nil }

    init(event: KeyEvent? = nil, preselectedDate: Date? = nil) {
        self.event = event
        self.preselectedDate = preselectedDate
        _date = State(initialValue: preselectedDate ?? Date())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Event") {
                    Picker("Type", selection: $eventType) {
                        ForEach(KeyEventType.allCases) { t in
                            HStack {
                                Circle()
                                    .fill(Color(hex: CalendarViewModel.colorHex(for: t)))
                                    .frame(width: 8, height: 8)
                                Text(t.rawValue)
                            }.tag(t)
                        }
                    }

                    TextField("Title *", text: $title)
                }

                Section("Case & Date") {
                    Picker("Related case", selection: $selectedCase) {
                        Text("None").tag(nil as CaseRecord?)
                        ForEach(allCases) { c in Text(c.caseName).tag(c as CaseRecord?) }
                    }

                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section("Detail") {
                    TextField("Detail", text: $detail, axis: .vertical)
                        .lineLimit(3)
                }

                Section("Reminder") {
                    Toggle("Enable reminder", isOn: $reminderEnabled)

                    if reminderEnabled {
                        reminderDaysPicker
                            .listRowInsets(.init(top: 4, leading: 0, bottom: 4, trailing: 0))
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit" : "New Event")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveEvent() }.disabled(title.isEmpty)
                }
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
                    Text("\(day)d")
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
        if let existing = event {
            existing.eventType = eventType
            existing.title = title
            existing.detail = detail.isEmpty ? nil : detail
            existing.date = date
            existing.caseRecord = selectedCase
            existing.reminderEnabled = reminderEnabled
            existing.reminderDays = reminderEnabled ? reminderDays : []
            if let c = selectedCase { existing.caseRecord = c; c.keyEvents?.append(existing) }
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
        }
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
