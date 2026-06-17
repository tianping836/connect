import SwiftUI
import SwiftData

// listStyle 统一使用 .inset，跨平台兼容 iOS 和 macOS

/// 人脉详情页——基本信息 + 关联联系人（介绍人链）+ 关联案件（区分当事人/经办人）
struct ContactDetailView: View {
    let contact: Contact
    @Environment(\.modelContext) private var modelContext
    @State private var showEdit = false

    var body: some View {
        List {
            // MARK: - 基本信息

            Section("Info") {
                VStack(spacing: 12) {
                    // 头像 + 姓名 + 角色
                    HStack(spacing: 16) {
                        AvatarView(name: contact.name, importance: contact.importance)
                            .frame(width: 56, height: 56)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(contact.name)
                                    .font(.title3.weight(.bold))

                                ForEach(0..<contact.importance, id: \.self) { _ in
                                    Image(systemName: "star.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.orange)
                                }
                            }

                            if !contact.roleTags.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 4) {
                                        ForEach(contact.roleTags, id: \.self) { role in
                                            RoleBadge(role: role)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // 联系方式
                if let phone = contact.phone {
                    LabeledContent("Phone", value: phone)
                }
                if let wechat = contact.wechat {
                    LabeledContent("WeChat", value: wechat)
                }
                if let email = contact.email {
                    LabeledContent("Email", value: email)
                }

                // 机构
                if let org = contact.organization {
                    LabeledContent("Organization") {
                        HStack(spacing: 4) {
                            Text(org.name)
                            Text("· \(org.type.rawValue)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    if !contact.rolesInOrg.isEmpty {
                        LabeledContent("Role in org") {
                            Text(contact.rolesInOrg.map(\.rawValue).joined(separator: ", "))
                        }
                    }
                }

                // 关系
                LabeledContent("Relationship") {
                    Text(contact.relationshipStage.rawValue)
                }
                if let referrer = contact.referrer {
                    NavigationLink {
                        ContactDetailView(contact: referrer)
                    } label: {
                        LabeledContent("Referrer") {
                            Text(referrer.name)
                        }
                    }
                }

                // 技能标签
                if !contact.skillTags.isEmpty {
                    LabeledContent("Skills") {
                        Text(contact.skillTags.joined(separator: ", "))
                    }
                }

                // 软信息
                if let pref = contact.preferences {
                    LabeledContent("Preferences / Interests", value: pref)
                }
                if let bday = contact.birthday {
                    LabeledContent("Birthday") {
                        Text(bday.formatted(date: .long, time: .omitted))
                    }
                }
                if let notes = contact.notes {
                    LabeledContent("Notes", value: notes)
                }
            }

            // MARK: - 关联联系人（介绍人链）

            if let referrals = contact.referrals, !referrals.isEmpty {
                Section("Introduced") {
                    ForEach(referrals) { person in
                        NavigationLink {
                            ContactDetailView(contact: person)
                        } label: {
                            ContactRowView(contact: person)
                        }
                    }
                }
            }

            // MARK: - 关联案件

            if let participations = contact.caseParticipations, !participations.isEmpty {
                Section("Related cases (\(participations.count))") {
                    // 当事人相关
                    let partyCases = participations.filter { $0.role.category == .partyRelated }
                    if !partyCases.isEmpty {
                        caseGroup(title: "Client relation", participations: partyCases)
                    }

                    // 经办人员
                    let officialCases = participations.filter { $0.role.category == .officialRelated }
                    if !officialCases.isEmpty {
                        caseGroup(title: "Officer relation", participations: officialCases)
                    }
                }
            }

            // MARK: - 互动记录

            if let interactions = contact.interactions, !interactions.isEmpty {
                Section("Recent interactions") {
                    ForEach(interactions.sorted(by: { $0.date > $1.date }).prefix(5)) { interaction in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(interaction.type.rawValue)
                                    .font(.caption.weight(.medium))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.blue.opacity(0.1))
                                    .foregroundStyle(.blue)
                                    .clipShape(.capsule)

                                Spacer()

                                Text(interaction.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text(interaction.detail)
                                .font(.subheadline)
                            if let amount = interaction.amount {
                                Text("\(amount, format: .currency(code: "CNY"))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.inset)
        .navigationTitle(contact.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showEdit = true }
            }
        }
        .sheet(isPresented: $showEdit) {
            ContactEditView(contact: contact)
        }
    }

    @ViewBuilder
    private func caseGroup(title: String, participations: [CaseParticipant]) -> some View {
        ForEach(participations) { participation in
            if let caseRecord = participation.caseRecord {
                NavigationLink {
                    // CaseDetailView 稍后实现
                    Text(caseRecord.caseName)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(caseRecord.caseName)
                                .font(.subheadline.weight(.medium))
                            Text(participation.role.rawValue + (participation.roleDetail.map { " · \($0)" } ?? ""))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        CaseStageBadge(stage: caseRecord.caseStage)
                    }
                }
            }
        }
    }
}

// MARK: - 子组件

struct CaseStageBadge: View {
    let stage: CaseStage

    private var color: Color {
        stage.isActive ? .orange : .green
    }

    var body: some View {
        Text(stage.rawValue)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .foregroundStyle(color)
            .clipShape(.capsule)
    }
}

#if DEBUG
#Preview {
    let container = ModelContainer.appContainer
    let context = container.mainContext
    PreviewData.create(modelContext: context)
    let contacts = try! context.fetch(FetchDescriptor<Contact>())
    return NavigationStack {
        ContactDetailView(contact: contacts.first!)
    }
    .modelContainer(container)
}
#endif
