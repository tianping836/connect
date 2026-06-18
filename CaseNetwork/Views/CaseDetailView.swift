import SwiftUI
import SwiftData

/// 案件详情页——基本信息 + 参与人（按角色分组）+ 大事记时间轴 + 关联机构
struct CaseDetailView: View {
    let caseRecord: CaseRecord
    @Environment(\.modelContext) private var modelContext
    @State private var showEdit = false
    @State private var showAddParticipant = false

    var body: some View {
        List {
            // MARK: - 基本信息

            Section("Case Information") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        CaseStageBadge(stage: caseRecord.caseStage)
                        Spacer()
                        if let date = caseRecord.filingDate {
                            Text("File: \(date.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Text(caseRecord.caseName)
                        .font(.title3.weight(.bold))

                    if let courtNum = caseRecord.courtCaseNumber {
                        LabeledContent("Case No.", value: courtNum)
                    }
                    if let internalNum = caseRecord.internalCaseNumber {
                        LabeledContent("Ref No.", value: internalNum)
                    }
                    LabeledContent("Type") {
                        Text(caseRecord.caseType.rawValue)
                    }
                    if let amount = caseRecord.claimAmount {
                        LabeledContent("Amount") {
                            Text(amount.formatted(.currency(code: "CNY")))
                        }
                    }
                    if let summary = caseRecord.claimSummary {
                        LabeledContent("Claim") {
                            Text(summary).lineLimit(3)
                        }
                    }
                    if let result = caseRecord.caseResult {
                        LabeledContent("Result") {
                            Text(result)
                                .foregroundStyle(.green)
                        }
                    }
                    if let org = caseRecord.acceptedOrganization {
                        LabeledContent("Organization") {
                            Text("\(org.name) · \(org.type.rawValue)")
                        }
                    }
                    if let notes = caseRecord.notes {
                        LabeledContent("Notes", value: notes)
                    }
                }
            }

            // MARK: - 参与人

            Section {
                ForEach(participantsGrouped, id: \.category) { group in
                    participantsGroup(group.label, group.items)
                }

                Button {
                    showAddParticipant = true
                } label: {
                    Label("Add participant", systemImage: "person.badge.plus")
                }
            } header: {
                HStack {
                    Text("Participants")
                    Spacer()
                    Text("\(caseRecord.participants?.count ?? 0)")
                        .foregroundStyle(.secondary)
                }
            }

            // MARK: - 大事记时间轴

            if let events = caseRecord.keyEvents, !events.isEmpty {
                Section("Timeline") {
                    ForEach(events.sorted(by: { $0.date > $1.date })) { event in
                        timelineRow(event)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    deleteTimelineEvent(event)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }

            // MARK: - 关联案件（同机构/同委托人）

            if let relatedCases = relatedCases, !relatedCases.isEmpty {
                Section("Related Cases") {
                    ForEach(relatedCases) { related in
                        NavigationLink {
                            CaseDetailView(caseRecord: related)
                        } label: {
                            CaseRowView(caseRecord: related)
                        }
                    }
                }
            }
        }
        .listStyle(.inset)
        .navigationTitle(caseRecord.caseName)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showEdit = true }
            }
        }
        .sheet(isPresented: $showEdit) {
            CaseEditView(caseRecord: caseRecord)
        }
        .sheet(isPresented: $showAddParticipant) {
            AddParticipantSheet(caseRecord: caseRecord)
        }
    }

    // MARK: - 参与人分组

    private struct ParticipantGroup {
        let category: String
        let label: String
        let items: [CaseParticipant]
    }

    private var participantsGrouped: [ParticipantGroup] {
        guard let parts = caseRecord.participants else { return [] }
        let grouped = Dictionary(grouping: parts) { $0.role.category }
        return [
            ParticipantGroup(category: "official", label: "Officers", items: grouped[.officialRelated] ?? []),
            ParticipantGroup(category: "party", label: "Parties & Contacts", items: grouped[.partyRelated] ?? []),
        ].filter { !$0.items.isEmpty }
    }

    @ViewBuilder
    private func participantsGroup(_ label: String, _ items: [CaseParticipant]) -> some View {
        ForEach(items) { participation in
            if let contact = participation.contact {
                NavigationLink {
                    ContactDetailView(contact: contact)
                } label: {
                    HStack(spacing: 10) {
                        AvatarView(name: contact.name, importance: contact.importance)
                            .frame(width: 32, height: 32)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(contact.name)
                                .font(.subheadline.weight(.medium))
                            Text(participation.role.rawValue + (participation.roleDetail.map { " · \($0)" } ?? ""))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        RoleBadge(role: contact.roleTags.first ?? .other, size: .small)
                    }
                }
            }
        }
    }

    // MARK: - 大事记行

    private func timelineRow(_ event: KeyEvent) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // 时间轴点 + 线
            VStack(spacing: 0) {
                Circle()
                    .fill(Color(hex: eventTypeColor(event.eventType)))
                    .frame(width: 10, height: 10)
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 2)
            }
            .frame(width: 12)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(event.eventType.rawValue)
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: eventTypeColor(event.eventType)).opacity(0.1))
                        .foregroundStyle(Color(hex: eventTypeColor(event.eventType)))
                        .clipShape(.capsule)

                    Spacer()

                    Text(event.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(event.title)
                    .font(.subheadline.weight(.medium))

                if let detail = event.detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if event.reminderEnabled {
                    HStack(spacing: 4) {
                        Image(systemName: "bell")
                            .font(.caption2)
                        Text("Remind \(event.reminderDays.map(String.init).joined(separator: "/"))d")
                            .font(.caption2)
                    }
                    .foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func eventTypeColor(_ type: KeyEventType) -> String {
        switch type {
        case .filing:              "#1976D2"
        case .courtHearing:        "#D32F2F"
        case .evidenceDeadline:    "#F57C00"
        case .mediation:           "#7B1FA2"
        case .sentencing:          "#D32F2F"
        case .appeal:              "#F57C00"
        case .closing:             "#388E3C"
        case .clientMeeting:       "#00796B"
        case .evidenceSubmission:  "#455A64"
        case .ruling:              "#512DA8"
        case .other:               "#616161"
        }
    }

    // MARK: - 删除大事记

    private func deleteTimelineEvent(_ event: KeyEvent) {
        NotificationService.shared.cancelAll(for: event)
        caseRecord.keyEvents?.removeAll { $0.id == event.id }
        modelContext.delete(event)
        try? modelContext.save()
    }

    // MARK: - 关联案件

    private var relatedCases: [CaseRecord]? {
        guard let org = caseRecord.acceptedOrganization else { return nil }
        let orgCases = org.acceptedCases?.filter { $0.id != caseRecord.id } ?? []
        return orgCases.isEmpty ? nil : Array(orgCases.prefix(3))
    }
}
