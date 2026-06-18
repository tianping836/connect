import SwiftUI
import SwiftData

/// 新建 / 编辑联系人表单
struct ContactEditView: View {
    var contact: Contact?  // nil = 新建模式

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Organization.name) private var organizations: [Organization]
    @Query(sort: \Contact.name) private var allContacts: [Contact]

    // MARK: - 表单字段

    @State private var name = ""
    @State private var phone = ""
    @State private var wechat = ""
    @State private var email = ""
    @State private var selectedRoles: Set<ContactRole> = []
    @State private var selectedOrg: Organization?
    @State private var selectedOrgRoles: Set<OrgRole> = []
    @State private var selectedReferrer: Contact?
    @State private var importance = 3
    @State private var relationshipStage = RelationshipStage.newAcquaintance
    @State private var skillTagsText = ""
    @State private var preferences = ""
    @State private var notes = ""
    @State private var birthday: Date?
    @State private var hasBirthday = false
    @State private var contactReminderDays: Int?

    private var isEditing: Bool { contact != nil }
    private var title: String { isEditing ? "编辑" : "新建人脉" }

    var body: some View {
        NavigationStack {
            Form {
                // 基础信息
                Section("基本信息") {
                    TextField("姓名 *", text: $name)
                    TextField("电话", text: $phone)
                    TextField("微信", text: $wechat)
                    TextField("邮箱", text: $email)
                }

                // 角色 + 机构
                Section("角色与机构") {
                    roleSelector

                    Picker("机构", selection: $selectedOrg) {
                        Text("无").tag(nil as Organization?)
                        ForEach(organizations) { org in
                            Text(org.name).tag(org as Organization?)
                        }
                    }

                    if selectedOrg != nil {
                        orgRoleSelector
                    }
                }

                // 人脉链
                Section("人脉链") {
                    Picker("介绍人", selection: $selectedReferrer) {
                        Text("无").tag(nil as Contact?)
                        ForEach(allContacts.filter { $0.id != contact?.id }) { person in
                            Text(person.name).tag(person as Contact?)
                        }
                    }
                }

                // 关系深度
                Section("关系") {
                    Picker("阶段", selection: $relationshipStage) {
                        ForEach(RelationshipStage.allCases) { stage in
                            Text(stage.rawValue).tag(stage)
                        }
                    }

                    Stepper("重要度: \(String(repeating: "⭐", count: importance))", value: $importance, in: 1...5)
                }

                // 技能标签
                Section("技能") {
                    TextField("逗号分隔，如: 税务, 诉讼", text: $skillTagsText)
                }

                // 软信息
                Section("软信息") {
                    TextField("偏好 / 兴趣", text: $preferences)
                    Toggle("有生日", isOn: $hasBirthday)
                    if hasBirthday {
                        DatePicker("生日", selection: Binding(
                            get: { birthday ?? Date() },
                            set: { birthday = $0 }
                        ), displayedComponents: .date)
                    }
                }

                // 提醒
                Section("提醒") {
                    Picker("联系提醒周期", selection: $contactReminderDays) {
                        Text("无").tag(nil as Int?)
                        Text("7 天").tag(7 as Int?)
                        Text("14 天").tag(14 as Int?)
                        Text("30 天").tag(30 as Int?)
                        Text("90 天").tag(90 as Int?)
                    }
                }

                // 备注
                Section("备注") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { saveContact() }
                        .disabled(name.isEmpty)
                }
            }
            .onAppear { loadExistingData() }
        }
    }

    // MARK: - 角色选择器

    private var roleSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(ContactRole.allCases) { role in
                    Button {
                        if selectedRoles.contains(role) {
                            selectedRoles.remove(role)
                        } else {
                            selectedRoles.insert(role)
                        }
                    } label: {
                        Text(role.rawValue)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(selectedRoles.contains(role) ? Color(hex: role.colorHex).opacity(0.15) : Color.secondary.opacity(0.15))
                            .foregroundStyle(selectedRoles.contains(role) ? Color(hex: role.colorHex) : .secondary)
                            .clipShape(.capsule)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var orgRoleSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(OrgRole.allCases) { role in
                    Button {
                        if selectedOrgRoles.contains(role) {
                            selectedOrgRoles.remove(role)
                        } else {
                            selectedOrgRoles.insert(role)
                        }
                    } label: {
                        Text(role.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(selectedOrgRoles.contains(role) ? .blue.opacity(0.1) : Color.secondary.opacity(0.15))
                            .foregroundStyle(selectedOrgRoles.contains(role) ? .blue : .secondary)
                            .clipShape(.capsule)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - 保存

    private func saveContact() {
        let skills = skillTagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        if let existing = contact {
            // 更新
            existing.name = name
            existing.phone = phone.isEmpty ? nil : phone
            existing.wechat = wechat.isEmpty ? nil : wechat
            existing.email = email.isEmpty ? nil : email
            existing.roleTags = Array(selectedRoles)
            existing.organization = selectedOrg
            existing.rolesInOrg = Array(selectedOrgRoles)
            existing.referrer = selectedReferrer
            existing.importance = importance
            existing.relationshipStage = relationshipStage
            existing.skillTags = skills
            existing.preferences = preferences.isEmpty ? nil : preferences
            existing.birthday = hasBirthday ? birthday : nil
            existing.notes = notes.isEmpty ? nil : notes
            existing.contactReminderDays = contactReminderDays
            existing.updatedAt = Date()
        } else {
            // 新建
            let newContact = Contact(
                name: name,
                phone: phone.isEmpty ? nil : phone,
                wechat: wechat.isEmpty ? nil : wechat,
                email: email.isEmpty ? nil : email,
                roleTags: Array(selectedRoles),
                organization: selectedOrg,
                rolesInOrg: Array(selectedOrgRoles),
                referrer: selectedReferrer,
                importance: importance,
                relationshipStage: relationshipStage,
                skillTags: skills,
                preferences: preferences.isEmpty ? nil : preferences,
                birthday: hasBirthday ? birthday : nil,
                notes: notes.isEmpty ? nil : notes,
                contactReminderDays: contactReminderDays
            )
            modelContext.insert(newContact)
        }
        try? modelContext.save()
        dismiss()
    }

    private func loadExistingData() {
        guard let contact else { return }
        name = contact.name
        phone = contact.phone ?? ""
        wechat = contact.wechat ?? ""
        email = contact.email ?? ""
        selectedRoles = Set(contact.roleTags)
        selectedOrg = contact.organization
        selectedOrgRoles = Set(contact.rolesInOrg)
        selectedReferrer = contact.referrer
        importance = contact.importance
        relationshipStage = contact.relationshipStage
        skillTagsText = contact.skillTags.joined(separator: ", ")
        preferences = contact.preferences ?? ""
        notes = contact.notes ?? ""
        if let bday = contact.birthday {
            hasBirthday = true
            birthday = bday
        }
        contactReminderDays = contact.contactReminderDays
    }
}

#if DEBUG
#Preview {
    let container = ModelContainer.appContainer
    let context = container.mainContext
    PreviewData.create(modelContext: context)
    return ContactEditView()
        .modelContainer(container)
}
#endif
