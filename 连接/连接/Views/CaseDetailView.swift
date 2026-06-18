import SwiftUI
import UIKit
import SwiftData

/// 案件详情页——基本信息 + 参与人（按角色分组）+ 大事记时间轴 + 关联机构
struct CaseDetailView: View {
    let caseRecord: CaseRecord
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Contact.name) private var allContacts: [Contact]
    @State private var showEdit = false
    @State private var showAddParticipant = false
    @State private var showDropToast = false
    @State private var droppedContactName = ""
    @State private var showFileDropToast = false
    @State private var droppedFileName = ""

    var body: some View {
        List {
            // MARK: - 基本信息

            Section("案件信息") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        CaseStageBadge(stage: caseRecord.caseStage)
                        Spacer()
                        if let date = caseRecord.filingDate {
                            Text("立案: \(date.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Text(caseRecord.caseName)
                        .font(.title3.weight(.bold))

                    if let courtNum = caseRecord.courtCaseNumber {
                        LabeledContent("案号", value: courtNum)
                    }
                    if let internalNum = caseRecord.internalCaseNumber {
                        LabeledContent("委托号", value: internalNum)
                    }
                    LabeledContent("类型") {
                        Text(caseRecord.caseType.rawValue)
                    }
                    if let amount = caseRecord.claimAmount {
                        LabeledContent("标的额") {
                            Text(amount.formatted(.currency(code: "CNY")))
                        }
                    }
                    if let summary = caseRecord.claimSummary {
                        LabeledContent("诉请") {
                            Text(summary).lineLimit(3)
                        }
                    }
                    if let result = caseRecord.caseResult {
                        LabeledContent("结果") {
                            Text(result)
                                .foregroundStyle(.green)
                        }
                    }
                    if let org = caseRecord.acceptedOrganization {
                        LabeledContent("机构") {
                            Text("\(org.name) · \(org.type.rawValue)")
                        }
                    }
                    if let notes = caseRecord.notes {
                        LabeledContent("备注", value: notes)
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
                    Label("添加参与人", systemImage: "person.badge.plus")
                }
            } header: {
                HStack {
                    Text("参与人")
                    Spacer()
                    Text("\(caseRecord.participants?.count ?? 0)")
                        .foregroundStyle(.secondary)
                }
            }

            // MARK: - 文书附件

            Section {
                if caseRecord.documentPaths.isEmpty {
                    HStack {
                        Image(systemName: "tray")
                            .foregroundStyle(.secondary)
                        Text("从访达拖放文件到此处")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                } else {
                    ForEach(Array(caseRecord.documentPaths.enumerated()), id: \.offset) { idx, path in
                        let url = URL(fileURLWithPath: path)
                        HStack {
                            Image(systemName: fileIcon(for: url.pathExtension))
                                .foregroundStyle(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(url.lastPathComponent)
                                    .font(.subheadline)
                                Text(url.pathExtension.uppercased())
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button {
                                openFile(url)
                            } label: {
                                Image(systemName: "arrow.up.forward.app")
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                        }
                        .contextMenu {
                            Button {
                                openFile(url)
                            } label: {
                                Label("打开", systemImage: "arrow.up.forward.app")
                            }
                            #if os(macOS)
                            Button {
                                NSWorkspace.shared.activateFileViewerSelecting([url])
                            } label: {
                                Label("在访达中显示", systemImage: "folder")
                            }
                            #endif
                            Divider()
                            Button(role: .destructive) {
                                removeDocument(at: idx)
                            } label: {
                                Label("移除", systemImage: "trash")
                            }
                        }
                    }
                }
            } header: {
                HStack {
                    Text("文书附件")
                    Spacer()
                    Text("\(caseRecord.documentPaths.count)")
                        .foregroundStyle(.secondary)
                }
            }

            // MARK: - 大事记时间轴

            if let events = caseRecord.keyEvents, !events.isEmpty {
                Section("大事记") {
                    ForEach(events.sorted(by: { $0.date > $1.date })) { event in
                        timelineRow(event)
                            .contextMenu {
                                Button {
                                    NotificationCenter.default.post(name: .editKeyEventRequested, object: event)
                                } label: {
                                    Label("编辑", systemImage: "pencil")
                                }
                                Divider()
                                Button(role: .destructive) {
                                    deleteTimelineEvent(event)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    deleteTimelineEvent(event)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                    }
                }
            }

            // MARK: - 关联案件（同机构/同委托人）

            if let relatedCases = relatedCases, !relatedCases.isEmpty {
                Section("关联案件") {
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
        .dropDestination(for: String.self) { items, _ in
            guard let uuidStr = items.first,
                  let uuid = UUID(uuidString: uuidStr),
                  let contact = allContacts.first(where: { $0.id == uuid }),
                  !(caseRecord.participants?.contains(where: { $0.contact?.id == uuid }) ?? false)
            else { return false }
            addParticipantFromDrop(contact)
            return true
        }
        .dropDestination(for: URL.self) { urls, _ in
            handleFileDrop(urls)
        }
        .overlay(alignment: .bottom) {
            if showDropToast || showFileDropToast {
                VStack(spacing: 8) {
                    if showDropToast {
                        Text("\(droppedContactName) 已添加到案件")
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial, in: .capsule)
                    }
                    if showFileDropToast {
                        Text("\(droppedFileName) 已添加")
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial, in: .capsule)
                    }
                }
                .padding(.bottom, 16)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: showDropToast)
        .navigationTitle(caseRecord.caseName)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("编辑") { showEdit = true }
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
            ParticipantGroup(category: "official", label: "经办人员", items: grouped[.officialRelated] ?? []),
            ParticipantGroup(category: "party", label: "当事人相关", items: grouped[.partyRelated] ?? []),
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
                        Text("提前 \(event.reminderDays.map(String.init).joined(separator: "/")) 天提醒")
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

    // MARK: - 拖放添加参与人

    private func addParticipantFromDrop(_ contact: Contact) {
        let participant = CaseParticipant(
            caseRecord: caseRecord,
            contact: contact,
            role: .other,
            roleDetail: nil,
            notes: nil
        )
        modelContext.insert(participant)
        caseRecord.participants?.append(participant)
        try? modelContext.save()

        droppedContactName = contact.name
        withAnimation {
            showDropToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showDropToast = false }
        }
    }

    // MARK: - 文件拖放

    private func handleFileDrop(_ urls: [URL]) -> Bool {
        let fm = FileManager.default
        // 在 app 的 Documents 下创建案件专属目录
        let docsDir = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let caseDir = docsDir.appendingPathComponent("CaseDocuments/\(caseRecord.id.uuidString)")
        try? fm.createDirectory(at: caseDir, withIntermediateDirectories: true)

        var added = false
        for srcURL in urls {
            let destURL = caseDir.appendingPathComponent(srcURL.lastPathComponent)
            // 避免覆盖：同名文件加序号
            let finalURL = uniqueURL(for: destURL)
            do {
                try fm.copyItem(at: srcURL, to: finalURL)
                var paths = caseRecord.documentPaths
                paths.append(finalURL.path)
                caseRecord.documentPaths = paths
                try? modelContext.save()
                droppedFileName = finalURL.lastPathComponent
                added = true
            } catch {
                print("[CaseDetail] Failed to copy file: \(error)")
            }
        }

        if added {
            withAnimation { showFileDropToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { showFileDropToast = false }
            }
        }
        return added
    }

    private func uniqueURL(for url: URL) -> URL {
        let fm = FileManager.default
        let base = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension
        let dir = url.deletingLastPathComponent()
        var candidate = url
        var counter = 1
        while fm.fileExists(atPath: candidate.path) {
            candidate = dir.appendingPathComponent("\(base)_\(counter).\(ext)")
            counter += 1
        }
        return candidate
    }

    private func removeDocument(at index: Int) {
        var paths = caseRecord.documentPaths
        guard index < paths.count else { return }
        let path = paths.remove(at: index)
        try? FileManager.default.removeItem(atPath: path)
        caseRecord.documentPaths = paths
        try? modelContext.save()
    }

    private func openFile(_ url: URL) {
        #if os(macOS)
        NSWorkspace.shared.open(url)
        #elseif os(iOS)
        UIApplication.shared.open(url)
        #endif
    }

    private func fileIcon(for ext: String) -> String {
        switch ext.lowercased() {
        case "pdf": "doc.richtext"
        case "doc", "docx": "doc.text"
        case "xls", "xlsx": "tablecells"
        case "jpg", "jpeg", "png", "gif", "heic": "photo"
        case "mp4", "mov": "film"
        case "mp3", "wav", "m4a": "waveform"
        case "zip", "rar", "7z": "archivebox"
        default: "doc"
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
