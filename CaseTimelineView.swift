import SwiftUI
import SwiftData
struct CaseTimelineView: View {
    @Environment(\.modelContext) private var modelContext
    let caseItem: Case
    @State private var collapsedMonths: Set<string> = []
    @State private var showNewNoteSheet = false
    private let calendar = Calendar.current
    private var timelineEntries: [TimelineEntry] {
        var entries: [TimelineEntry] = []
        for event in caseItem.events { entries.append(TimelineEntry(id: event.persistentModelID.hashValue, title: event.title, date: event.date, type: .caseEvent(event.eventType), subtitle: event.note, isCompleted: event.isCompleted, isPinned: false)) }
        for note in caseItem.caseNotes { entries.append(TimelineEntry(id: note.persistentModelID.hashValue, title: note.title, date: note.timestamp, type: .note, subtitle: note.content, isCompleted: false, isPinned: note.isPinned)) }
        entries.sort { a, b in if a.isPinned != b.isPinned { return a.isPinned }; return a.date > b.date }
        return entries
    }
    private var groupedEntries: [(key: String, entries: [TimelineEntry])] {
        let grouped = Dictionary(grouping: timelineEntries) { monthKey(for: $0.date) }
        return grouped.sorted { $0.key > $1.key }
    }
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if timelineEntries.isEmpty { emptyTimeline }
                else { ForEach(groupedEntries, id: \.key) { month, entries in monthSection(month: month, entries: entries) } }
                Color.clear.frame(height: Spacing.xxl * 2)
            }.padding(.horizontal, Spacing.base).padding(.top, Spacing.base)
        }.background(Color.surfaceLight).navigationTitle("案件时间线").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .primaryAction) { Button { showNewNoteSheet = true } label: { Image(systemName: "square.and.pencil").font(.system(size: 18)).foregroundColor(.tealLink) }.accessibilityLabel("添加笔记") } }
        .sheet(isPresented: $showNewNoteSheet) { CaseNoteEditView(caseItem: caseItem) }
    }
    private var emptyTimeline: some View {
        VStack(spacing: Spacing.base) {
            Spacer().frame(height: 80)
            Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90").font(.system(size: 48)).foregroundColor(.tealLink.opacity(0.4))
            Text("还没有时间节点").font(.cnTitle3).foregroundColor(.textPrimary)
            Text("添加开庭、举证期限或随手笔记，
这里会变成这个案件的完整故事。").font(.cnBody).foregroundColor(.textSecondary).multilineTextAlignment(.center).padding(.horizontal, Spacing.xxl)
            Button { showNewNoteSheet = true } label: { Label("写第一条笔记", systemImage: "square.and.pencil").font(.cnSubhead).foregroundColor(.white).padding(.horizontal, Spacing.lg).padding(.vertical, Spacing.md).background(Color.tealLink).clipShape(RoundedRectangle(cornerRadius: CornerRadius.button)) }.padding(.top, Spacing.sm)
        }
    }
    private func monthSection(month: String, entries: [TimelineEntry]) -> some View {
        let isCollapsed = collapsedMonths.contains(month)
        return VStack(spacing: 0) {
            Button { withAnimation(.easeInOut(duration: 0.25)) { if isCollapsed { collapsedMonths.remove(month) } else { collapsedMonths.insert(month) } } } label: {
                HStack(spacing: Spacing.sm) { Text(month).font(.cnTitle3).foregroundColor(.textPrimary); Spacer(); Text("\(entries.count)条").font(.cnSubhead).foregroundColor(.textTertiary); Image(systemName: isCollapsed ? "chevron.right" : "chevron.down").font(.system(size: 12, weight: .medium)).foregroundColor(.textTertiary) }.padding(.vertical, Spacing.md)
            }.buttonStyle(.plain)
            if !isCollapsed { VStack(spacing: 0) { ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in timelineNode(entry: entry, isFirst: index == 0, isLast: index == entries.count - 1) } }.padding(.bottom, Spacing.base) }
        }
    }
    @ViewBuilder private func timelineNode(entry: TimelineEntry, isFirst: Bool, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(spacing: 0) {
                if !isFirst { Rectangle().fill(Color.divider).frame(width: 2).frame(height: Spacing.base) } else { Color.clear.frame(height: Spacing.base) }
                ZStack { Circle().fill(entry.dotBackground).frame(width: 28, height: 28); Image(systemName: entry.type.systemImage).font(.system(size: 12, weight: .semibold)).foregroundColor(entry.dotForeground) }
                if !isLast { Rectangle().fill(Color.divider).frame(width: 2).frame(height: Spacing.base) } else { Color.clear.frame(height: Spacing.base) }
            }.frame(width: 36)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: Spacing.sm) { if entry.isPinned { Image(systemName: "pin.fill").font(.system(size: 10)).foregroundColor(.coralWarm) }; Text(formatDate(entry.date)).font(.cnCaption1).foregroundColor(.textTertiary); if entry.isCompleted { HStack(spacing: 3) { Image(systemName: "checkmark.circle.fill").font(.system(size: 10)); Text("已完成") }.font(.cnCaption2).foregroundColor(.statusSuccess) } }
                Text(entry.title).font(.cnHeadline).foregroundColor(.textPrimary).lineLimit(2)
                if let subtitle = entry.subtitle, !subtitle.isEmpty { Text(subtitle).font(.cnSubhead).foregroundColor(.textSecondary).lineLimit(3).padding(.top, 2) }
            }.padding(.leading, Spacing.md).padding(.vertical, Spacing.sm)
        }.padding(.leading, Spacing.xs)
    }
    private func formatDate(_ date: Date) -> String { let f = DateFormatter(); f.locale = Locale(identifier: "zh_CN"); if calendar.isDateInToday(date) { f.dateFormat = "今天 HH:mm" } else if calendar.isDateInYesterday(date) { f.dateFormat = "'昨天' HH:mm" } else if calendar.isDate(date, equalTo: Date(), toGranularity: .year) { f.dateFormat = "M月d日 HH:mm" } else { f.dateFormat = "yyyy年M月d日" }; return f.string(from: date) }
    private func monthKey(for date: Date) -> String { let f = DateFormatter(); f.locale = Locale(identifier: "zh_CN"); f.dateFormat = "yyyy年M月"; return f.string(from: date) }
}
private struct TimelineEntry { let id: Int; let title: String; let date: Date; let type: TimelineEntryType; let subtitle: String?; let isCompleted: Bool; let isPinned: Bool
    var dotBackground: Color { switch type { case .caseEvent(let et): if case .trial = et { return .coralWarm.opacity(0.15) }; if case .evidenceDeadline = et { return .statusWarning.opacity(0.15) }; return .tealLink.opacity(0.12); case .note: return .statusInfo.opacity(0.1) } }
    var dotForeground: Color { switch type { case .caseEvent(let et): if case .trial = et { return .coralWarm }; if case .evidenceDeadline = et { return .statusWarning }; return .tealLink; case .note: return .statusInfo } }
}
struct CaseNoteEditView: View {
    @Environment(\.modelContext) private var modelContext; @Environment(\.dismiss) private var dismiss
    let caseItem: Case; var existingNote: CaseNote? = nil
    @State private var title = ""; @State private var content = ""; @State private var timestamp = Date(); @State private var isPinned = false; @State private var hasCustomTimestamp = false
    private var isEditing: Bool { existingNote != nil }
    var body: some View {
        NavigationStack {
            Form {
                Section("笔记标题") { TextField("例如：第一次会见当事人记录", text: $title).textContentType(.none) }
                Section("笔记内容") { TextEditor(text: $content).frame(minHeight: 120).font(.cnBody) }
                Section("时间") { Toggle("自定义时间戳", isOn: $hasCustomTimestamp); if hasCustomTimestamp { DatePicker("时间", selection: $timestamp) } }
                Section { Toggle(isOn: $isPinned) { Label("钉在时间线顶部", systemImage: "pin.fill").foregroundColor(.coralWarm) } }
            }.navigationTitle(isEditing ? "编辑笔记" : "新建笔记").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button("保存") { saveNote(); dismiss() }.disabled(title.trimmingCharacters(in: .whitespaces).isEmpty).fontWeight(.semibold) } }
            .onAppear { if let note = existingNote { title = note.title; content = note.content; timestamp = note.timestamp; isPinned = note.isPinned; hasCustomTimestamp = true } }
        }
    }
    private func saveNote() {
        if let note = existingNote { note.title = title; note.content = content; note.timestamp = hasCustomTimestamp ? timestamp : Date(); note.isPinned = isPinned; note.updatedAt = Date() }
        else { let note = CaseNote(title: title, content: content, timestamp: hasCustomTimestamp ? timestamp : Date(), case: caseItem, isPinned: isPinned); modelContext.insert(note) }
        try? modelContext.save()
    }
}
enum TimelineEntryType { case caseEvent(CaseEventType); case note
    var systemImage: String { switch self { case .caseEvent(let et): switch et { case .trial: return "hammer.fill"; case .evidenceDeadline: return "clock.badge.exclamationmark"; case .filing: return "doc.text.fill"; case .sentencing: return "gavel.fill"; case .hearing: return "person.2.fill"; case .deadline: return "calendar.badge.exclamationmark" }; case .note: return "pencil.line" } }
}