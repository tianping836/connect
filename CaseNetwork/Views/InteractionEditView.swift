import SwiftUI
import SwiftData

/// 新增/编辑互动记录
struct InteractionEditView: View {
    let contact: Contact
    var existingInteraction: Interaction? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var type: InteractionType = .other
    @State private var date: Date = Date()
    @State private var detail: String = ""
    @State private var amountString: String = ""
    @State private var hasFollowUp: Bool = false
    @State private var followUpDate: Date = Date().addingTimeInterval(86400 * 30)

    init(contact: Contact, existing: Interaction? = nil) {
        self.contact = contact
        self.existingInteraction = existing
        if let e = existing {
            _type = State(initialValue: e.type)
            _date = State(initialValue: e.date)
            _detail = State(initialValue: e.detail)
            _amountString = State(initialValue: e.amount.map { String($0) } ?? "")
            _hasFollowUp = State(initialValue: e.nextFollowUpDate != nil)
            _followUpDate = State(initialValue: e.nextFollowUpDate ?? Date().addingTimeInterval(86400 * 30))
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 4), spacing: 8) {
                        ForEach(InteractionType.allCases) { t in
                            typeButton(t)
                        }
                    }
                }

                Section {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("What happened", text: $detail, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Amount (optional)") {
                    HStack {
                        Text("¥")
                            .foregroundStyle(.secondary)
                        TextField("0.00", text: $amountString)
                        #if os(iOS)
                            .keyboardType(.decimalPad)
                        #endif
                    }
                }

                Section {
                    Toggle("Follow-up reminder", isOn: $hasFollowUp)
                    if hasFollowUp {
                        DatePicker("Next follow-up", selection: $followUpDate, displayedComponents: .date)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(existingInteraction != nil ? "Edit interaction" : "New interaction")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(detail.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        #if os(iOS)
        .presentationDetents([.medium, .large])
        #endif
    }

    @ViewBuilder
    private func typeButton(_ t: InteractionType) -> some View {
        Button {
            type = t
        } label: {
            VStack(spacing: 4) {
                Text(t.icon)
                    .font(.title3)
                Text(t.rawValue)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(type == t ? interactionColor(t).opacity(0.12) : Color.clear)
            .foregroundStyle(type == t ? interactionColor(t) : .secondary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(type == t ? interactionColor(t).opacity(0.3) : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func save() {
        if let existing = existingInteraction {
            existing.type = type
            existing.date = date
            existing.detail = detail
            existing.amount = Double(amountString)
            existing.nextFollowUpDate = hasFollowUp ? followUpDate : nil
        } else {
            let interaction = Interaction(
                contact: contact,
                type: type,
                date: date,
                detail: detail,
                amount: Double(amountString),
                nextFollowUpDate: hasFollowUp ? followUpDate : nil
            )
            modelContext.insert(interaction)
        }
        try? modelContext.save()
        dismiss()
    }

    private func interactionColor(_ type: InteractionType) -> Color {
        switch type {
        case .giftGiven:   .orange
        case .giftReceived: .blue
        case .favorGiven:  .green
        case .favorReceived: .teal
        case .visit:       .purple
        case .phoneCall:   .indigo
        case .wechat:      .mint
        case .meeting:     .cyan
        case .meal:        .pink
        case .other:       .secondary
        }
    }
}

// MARK: - 互动类型图标

extension InteractionType {
    var icon: String {
        switch self {
        case .giftGiven:    "gift.fill"
        case .giftReceived: "gift"
        case .favorGiven:   "hand.raised.fill"
        case .favorReceived: "hands.and.sparkles"
        case .visit:        "figure.walk"
        case .phoneCall:    "phone.fill"
        case .wechat:       "message.fill"
        case .meeting:      "person.2.fill"
        case .meal:         "fork.knife"
        case .other:        "ellipsis.circle"
        }
    }
}

#if DEBUG
#Preview {
    let container = ModelContainer.appContainer
    let ctx = container.mainContext
    PreviewData.create(modelContext: ctx)
    let contacts = try! ctx.fetch(FetchDescriptor<Contact>())
    return InteractionEditView(contact: contacts.first!)
        .modelContainer(container)
}
#endif
