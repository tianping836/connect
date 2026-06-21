import SwiftUI
import SwiftData

/// 事件详情页 — 展示事件完整信息、参与人、关联案件
struct EventDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let event: Event
    @State private var showEditSheet = false
    @State private var showDeleteConfirm = false

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.base) {
                headerCard
                if !event.participants.isEmpty { participantsCard }
                if !event.linkedCases.isEmpty { linkedCasesCard }
                if let notes = event.notes, !notes.isEmpty { notesCard(notes) }
                actionButtons
            }
            .padding(.horizontal, Spacing.base).padding(.vertical, Spacing.md)
        }
        .background(Color.surfaceLight).navigationTitle("事件详情").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showEditSheet = true } label: { Image(systemName: "pencil.circle").font(.system(size: 20)).foregroundColor(.tealLink) }.accessibilityLabel("编辑事件")
            }
        }
        .sheet(isPresented: $showEditSheet) { EventEditView(existingEvent: event) }
        .alert("删除事件", isPresented: $showDeleteConfirm) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) { deleteEvent() }
        } message: { Text("确定要删除「\(event.title)」吗？此操作不可撤销。") }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) { EventStatusBadge(status: event.status); EventTypeTag(eventType: event.eventType); Spacer() }
            Text(event.title).font(.cnTitle2).foregroundColor(.textPrimary)
            HStack(spacing: Spacing.base) {
                Label {
                    if let date = event.date {
                        if event.isAllDay { Text(date.formatted(date: .long, time: .omitted)) } else { Text(date.formatted(date: .long, time: .shortened)) }
                    } else { Text("日期待定").foregroundColor(.textTertiary) }
                } icon: { Image(systemName: "calendar").foregroundColor(.tealLink) }
                if let endDate = event.endDate {
                    Label { Text(endDate.formatted(date: .long, time: .omitted)) } icon: { Image(systemName: "calendar.badge.clock").foregroundColor(.tealLink) }
                }
            }
            .font(.cnSubhead).foregroundColor(.textSecondary)
            if let location = event.location, !location.isEmpty {
                Label { Text(location) } icon: { Image(systemName: "mappin.and.ellipse").foregroundColor(.coralWarm) }.font(.cnSubhead).foregroundColor(.textSecondary)
            }
            if let summary = event.summary, !summary.isEmpty {
                Divider().background(Color.divider)
                Text(summary).font(.cnBody).foregroundColor(.textPrimary).fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Spacing.base).cardStyleSolid()
    }

    private var participantsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label { Text("参与人") } icon: { Image(systemName: "person.2.fill").foregroundColor(.tealLink) }.font(.cnTitle3).foregroundColor(.textPrimary)
                Spacer()
                Text("\(event.participants.count)人").font(.cnSubhead).foregroundColor(.textTertiary)
            }
            .padding(.horizontal, Spacing.base).padding(.vertical, Spacing.md)
            Divider().background(Color.divider)
            ForEach(event.eventPersons.sorted(by: { $0.sortOrder < $1.sortOrder }), id: \.id) { ep in
                if let person = ep.person {
                    HStack(spacing: Spacing.md) {
                        if let primaryRole = person.roleTypes.first { AvatarPlaceholder(roleType: primaryRole, size: 36) } else { AvatarPlaceholder(roleType: .other, size: 36) }
                        VStack(alignment: .leading, spacing: 2) { Text(person.name).font(.cnHeadline).foregroundColor(.textPrimary); Text(ep.role).font(.cnCaption1).foregroundColor(.textSecondary) }
                        Spacer()
                        if let org = person.org { Text(org).font(.cnCaption2).foregroundColor(.textTertiary).lineLimit(1) }
                    }
                    .padding(.horizontal, Spacing.base).padding(.vertical, Spacing.md)
                    Divider().background(Color.divider).padding(.leading, Spacing.xxl + Spacing.base)
                }
            }
        }
        .background(Color.surfaceCard).clipShape(RoundedRectangle(cornerRadius: CornerRadius.card)).cardShadow()
    }

    private var linkedCasesCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Label { Text("关联案件") } icon: { Image(systemName: "link").foregroundColor(.tealLink) }.font(.cnTitle3).foregroundColor(.textPrimary).padding(.horizontal, Spacing.base).padding(.vertical, Spacing.md)
            Divider().background(Color.divider)
            ForEach(event.eventCases, id: \.id) { ec in
                if let linkedCase = ec.case {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        HStack { Image(systemName: linkedCase.caseType.systemImage).font(.system(size: 14)).foregroundColor(.textSecondary); Text(linkedCase.name).font(.cnHeadline).foregroundColor(.textPrimary); Spacer(); StatusBadge(status: linkedCase.caseStatus) }
                        if let caseNumber = linkedCase.caseNumber { Text(caseNumber).font(.cnMonoFootnote).foregroundColor(.textSecondary) }
                        if let note = ec.note, !note.isEmpty { Text(note).font(.cnCaption1).foregroundColor(.textTertiary).padding(.top, Spacing.xs) }
                    }
                    .padding(.horizontal, Spacing.base).padding(.vertical, Spacing.md)
                    Divider().background(Color.divider).padding(.leading, Spacing.base)
                }
            }
        }
        .background(Color.surfaceCard).clipShape(RoundedRectangle(cornerRadius: CornerRadius.card)).cardShadow()
    }

    private func notesCard(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label { Text("备注") } icon: { Image(systemName: "note.text").foregroundColor(.textTertiary) }.font(.cnTitle3).foregroundColor(.textPrimary)
            Text(notes).font(.cnBody).foregroundColor(.textSecondary).fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.base).cardStyleSolid()
    }

    private var actionButtons: some View {
        VStack(spacing: Spacing.md) {
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Label("删除事件", systemImage: "trash").font(.cnBody).frame(maxWidth: .infinity).padding(.vertical, Spacing.md)
            }
            .tint(.statusError).buttonStyle(.borderedProminent)
        }
        .padding(.top, Spacing.base)
    }

    private func deleteEvent() {
        modelContext.delete(event)
        try? modelContext.save()
        dismiss()
    }
}