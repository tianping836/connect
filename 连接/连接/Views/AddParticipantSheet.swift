import SwiftUI
import SwiftData

/// 添加参与人弹窗——搜索联系人 + 选择 + 设定角色（核心高频交互）
struct AddParticipantSheet: View {
    let caseRecord: CaseRecord

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Contact.name) private var allContacts: [Contact]

    @State private var searchText = ""
    @State private var selectedContact: Contact?
    @State private var selectedRole: ParticipantRole = .other
    @State private var roleDetail = ""
    @State private var participantNotes = ""
    @State private var showNewContactSheet = false

    private var existingContactIDs: Set<UUID> {
        Set(caseRecord.participants?.compactMap { $0.contact?.id } ?? [])
    }

    private var filteredContacts: [Contact] {
        let available = allContacts.filter { !existingContactIDs.contains($0.id) }
        guard !searchText.isEmpty else { return available }
        return available.filter { $0.matchesSearchQuery(searchText) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if selectedContact == nil {
                    contactSelectionView
                } else {
                    roleAssignmentView
                }
            }
            .navigationTitle("添加参与人")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .searchable(text: $searchText, prompt: "搜索姓名、电话、机构……")
            .sheet(isPresented: $showNewContactSheet) {
                ContactEditView()
            }
            .dropDestination(for: String.self) { items, _ in
                guard let uuidStr = items.first,
                      let uuid = UUID(uuidString: uuidStr),
                      let contact = allContacts.first(where: { $0.id == uuid }),
                      !existingContactIDs.contains(contact.id)
                else { return false }
                withAnimation {
                    selectedContact = contact
                    // 预填角色
                    if contact.roleTags.contains(.judge) || contact.roleTags.contains(.clerk) {
                        selectedRole = .presidingJudge
                    } else if contact.roleTags.contains(.prosecutor) {
                        selectedRole = .prosecutorInCharge
                    } else if contact.roleTags.contains(.party) {
                        selectedRole = .client
                    } else if contact.roleTags.contains(.lawyer) {
                        selectedRole = .coCounsel
                    }
                }
                return true
            }
        }
    }

    // MARK: - 第一步：选择联系人

    private var contactSelectionView: some View {
        List {
            // 常用联系人（按互动频次）
            let frequent = filteredContacts
                .filter { ($0.interactions?.count ?? 0) > 0 }
                .sorted { ($0.interactions?.count ?? 0) > ($1.interactions?.count ?? 0) }
                .prefix(5)
            if !frequent.isEmpty && searchText.isEmpty {
                Section("常用") {
                    ForEach(Array(frequent)) { contact in
                        contactRow(contact)
                    }
                }
            }

            // 按角色分组
            if searchText.isEmpty {
                ForEach(ContactRole.allCases) { role in
                    let byRole = filteredContacts.filter { $0.roleTags.contains(role) }
                    if !byRole.isEmpty {
                        Section(role.rawValue) {
                            ForEach(byRole) { contact in
                                contactRow(contact)
                            }
                        }
                    }
                }
            } else {
                Section("\(filteredContacts.count) 个结果") {
                    ForEach(filteredContacts) { contact in
                        contactRow(contact)
                    }
                }
            }

            // 快捷新建
            Section {
                Button {
                    showNewContactSheet = true
                } label: {
                    Label("新建联系人: \"\(searchText)\"", systemImage: "person.badge.plus")
                }
                .disabled(searchText.isEmpty)
            }
        }
        .listStyle(.inset)
    }

    private func contactRow(_ contact: Contact) -> some View {
        Button {
            withAnimation {
                selectedContact = contact
                // 预填角色：根据联系人角色标签推测本案角色
                if contact.roleTags.contains(.judge) || contact.roleTags.contains(.clerk) {
                    selectedRole = .presidingJudge
                } else if contact.roleTags.contains(.prosecutor) {
                    selectedRole = .prosecutorInCharge
                } else if contact.roleTags.contains(.party) {
                    selectedRole = .client
                } else if contact.roleTags.contains(.lawyer) {
                    selectedRole = .coCounsel
                }
            }
        } label: {
            HStack(spacing: 10) {
                AvatarView(name: contact.name, importance: contact.importance)
                    .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(contact.name)
                        .font(.subheadline.weight(.medium))
                    if let org = contact.organization {
                        Text(org.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if let firstRole = contact.roleTags.first {
                    RoleBadge(role: firstRole, size: .small)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - 第二步：指定角色

    private var roleAssignmentView: some View {
        Form {
            // 已选联系人
            Section {
                HStack(spacing: 12) {
                    AvatarView(name: selectedContact?.name ?? "", importance: selectedContact?.importance ?? 3)
                        .frame(width: 48, height: 48)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedContact?.name ?? "")
                            .font(.headline)
                        if let org = selectedContact?.organization {
                            Text(org.name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Button("更换") {
                    withAnimation { selectedContact = nil }
                }
            }

            // 角色选择
            Section("在本案中的角色") {
                Picker("角色", selection: $selectedRole) {
                    ForEach(ParticipantRole.allCases) { role in
                        HStack {
                            Text(role.rawValue)
                            Text("· \(role.category.rawValue)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }.tag(role)
                    }
                }
                .pickerStyle(.menu)

                TextField("具体职务（选填）", text: $roleDetail, prompt: Text("如: 审判长"))
            }

            // 备注
            Section("备注") {
                TextField("参与备注", text: $participantNotes, axis: .vertical)
                    .lineLimit(2)
            }

            // 确认
            Section {
                Button {
                    addParticipant()
                } label: {
                    Label("确认添加", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private func addParticipant() {
        guard let contact = selectedContact else { return }
        let participant = CaseParticipant(
            caseRecord: caseRecord,
            contact: contact,
            role: selectedRole,
            roleDetail: roleDetail.isEmpty ? nil : roleDetail,
            notes: participantNotes.isEmpty ? nil : participantNotes
        )
        modelContext.insert(participant)
        caseRecord.participants?.append(participant)
        try? modelContext.save()
        dismiss()
    }
}
