import SwiftUI
import SwiftData

// listStyle 统一使用 .inset，跨平台兼容 iOS 和 macOS

/// 人脉详情页——基本信息 + 关联联系人（介绍人链）+ 关联案件（区分当事人/经办人）+ 互动时间线
struct ContactDetailView: View {
    let contact: Contact
    @Environment(\.modelContext) private var modelContext
    @Query var allRelations: [ContactRelation]
    @State private var showEdit = false
    @State private var showAddInteraction = false
    @State private var showAllInteractions = false
    @State private var showAddRelation = false
    @State private var showNetworkGraph = false

    var body: some View {
        List {
            // MARK: - 基本信息

            Section("基本信息") {
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
                    LabeledContent("电话", value: phone)
                }
                if let wechat = contact.wechat {
                    LabeledContent("微信", value: wechat)
                }
                if let email = contact.email {
                    LabeledContent("邮箱", value: email)
                }

                // 机构
                if let org = contact.organization {
                    LabeledContent("机构") {
                        HStack(spacing: 4) {
                            Text(org.name)
                            Text("· \(org.type.rawValue)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    if !contact.rolesInOrg.isEmpty {
                        LabeledContent("机构内角色") {
                            Text(contact.rolesInOrg.map(\.rawValue).joined(separator: ", "))
                        }
                    }
                }

                // 关系
                LabeledContent("关系") {
                    Text(contact.relationshipStage.rawValue)
                }
                if let referrer = contact.referrer {
                    NavigationLink {
                        ContactDetailView(contact: referrer)
                    } label: {
                        LabeledContent("介绍人") {
                            Text(referrer.name)
                        }
                    }
                }

                // 技能标签
                if !contact.skillTags.isEmpty {
                    LabeledContent("技能") {
                        Text(contact.skillTags.joined(separator: ", "))
                    }
                }

                // 软信息
                if let pref = contact.preferences {
                    LabeledContent("偏好/兴趣", value: pref)
                }
                if let bday = contact.birthday {
                    LabeledContent("生日") {
                        Text(bday.formatted(date: .long, time: .omitted))
                    }
                }
                if let notes = contact.notes {
                    LabeledContent("备注", value: notes)
                }
            }

            // MARK: - 关联联系人（介绍人链）

            if let referrals = contact.referrals, !referrals.isEmpty {
                Section("人脉圈") {
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
                Section("关联案件 (\(participations.count))") {
                    // 当事人相关
                    let partyCases = participations.filter { $0.role.category == .partyRelated }
                    if !partyCases.isEmpty {
                        caseGroup(title: "当事人相关", participations: partyCases)
                    }

                    // 经办人员
                    let officialCases = participations.filter { $0.role.category == .officialRelated }
                    if !officialCases.isEmpty {
                        caseGroup(title: "经办人员", participations: officialCases)
                    }
                }
            }

            // MARK: - 关系网络

            let directRelations = allRelations.filter {
                $0.source?.id == contact.id || $0.target?.id == contact.id
            }
            Section {
                // 按关系类型分组
                let grouped = Dictionary(grouping: directRelations) { $0.type }
                ForEach(grouped.keys.sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { type in
                    let rels = grouped[type] ?? []
                    ForEach(rels) { rel in
                        let peer = rel.source?.id == contact.id ? rel.target : rel.source
                        if let peerContact = peer {
                            NavigationLink {
                                ContactDetailView(contact: peerContact)
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: type.icon)
                                        .foregroundStyle(relationColor(type))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(peerContact.name)
                                            .font(.subheadline.weight(.medium))
                                        HStack(spacing: 4) {
                                            Text(type.rawValue)
                                                .font(.caption)
                                                .foregroundStyle(relationColor(type))
                                            if let note = rel.note {
                                                Text("· \(note)")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                    Spacer()
                                    if let role = peerContact.roleTags.first {
                                        RoleBadge(role: role, size: .small)
                                    }
                                }
                            }
                        }
                    }
                }

                if directRelations.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "person.line.dotted.person")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("还没有建立人脉关系")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }

                // 操作按钮
                HStack(spacing: 16) {
                    Button {
                        showAddRelation = true
                    } label: {
                        Label("添加关系", systemImage: "person.badge.plus")
                            .font(.subheadline)
                    }

                    if !directRelations.isEmpty {
                        Button {
                            showNetworkGraph = true
                        } label: {
                            Label("网络图", systemImage: "circle.hexagongrid")
                                .font(.subheadline)
                        }
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
            } header: {
                HStack {
                    Text("关系网络")
                    Spacer()
                    Text("\(directRelations.count)")
                        .foregroundStyle(.secondary)
                }
            }

            // MARK: - 互动记录

            if let interactions = contact.interactions, !interactions.isEmpty {
                let sorted = interactions.sorted(by: { $0.date > $1.date })
                let showAll = showAllInteractions
                let displayed = showAll ? sorted : Array(sorted.prefix(5))
                let hasMore = !showAll && sorted.count > 5

                Section {
                    ForEach(displayed) { interaction in
                        interactionRow(interaction)
                    }

                    if hasMore {
                        Button {
                            withAnimation { showAllInteractions = true }
                        } label: {
                            HStack {
                                Spacer()
                                Text("查看全部 \(sorted.count) 条互动")
                                    .font(.subheadline)
                                Image(systemName: "chevron.down")
                                Spacer()
                            }
                            .foregroundStyle(.blue)
                        }
                    }
                } header: {
                    HStack {
                        Text("互动时间线 (\(sorted.count))")
                        Spacer()
                        Button {
                            showAddInteraction = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                Section("互动记录") {
                    VStack(spacing: 12) {
                        Image(systemName: "clock.arrow.2.circlepath")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("还没有互动记录")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button {
                            showAddInteraction = true
                        } label: {
                            Label("记录第一条互动", systemImage: "plus")
                                .font(.subheadline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
            }
        }
        .listStyle(.inset)
        .navigationTitle(contact.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("编辑") { showEdit = true }
            }
        }
        .sheet(isPresented: $showEdit) {
            ContactEditView(contact: contact)
        }
        .sheet(isPresented: $showAddInteraction) {
            InteractionEditView(contact: contact)
        }
        .sheet(isPresented: $showAddRelation) {
            RelationshipEditView(preselectedSource: contact)
        }
        .sheet(isPresented: $showNetworkGraph) {
            NavigationStack {
                NetworkGraphView(center: contact)
            }
        }
    }

    // MARK: - 互动行

    private func interactionRow(_ interaction: Interaction) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(interaction.type.icon)
                Text(interaction.type.rawValue)
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(interactionColor(interaction.type).opacity(0.12))
                    .foregroundStyle(interactionColor(interaction.type))
                    .clipShape(.capsule)

                Spacer()

                Text(interaction.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(interaction.detail)
                .font(.subheadline)

            HStack(spacing: 12) {
                if let amount = interaction.amount {
                    Label(
                        amount.formatted(.currency(code: "CNY")),
                        systemImage: "yensign.circle"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                if let followUp = interaction.nextFollowUpDate {
                    Label(
                        "Follow-up: \(followUp.formatted(date: .abbreviated, time: .omitted))",
                        systemImage: followUp < Date() ? "bell.badge" : "bell"
                    )
                    .font(.caption)
                    .foregroundStyle(followUp < Date() ? .orange : .secondary)
                }
            }
        }
        .contextMenu {
            Button(role: .destructive) {
                modelContext.delete(interaction)
                try? modelContext.save()
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
    }

    private func relationColor(_ type: RelationType) -> Color {
        switch type {
        case .colleague: .blue
        case .classmate: .green
        case .relative: .red
        case .business: .orange
        case .friend: .purple
        case .acquaintance: .gray
        case .neighbor: .mint
        case .other: .secondary
        }
    }

    private func interactionColor(_ type: InteractionType) -> Color {
        switch type {
        case .giftGiven:     .orange
        case .giftReceived:  .blue
        case .favorGiven:    .green
        case .favorReceived: .teal
        case .visit:         .purple
        case .phoneCall:     .indigo
        case .wechat:        .mint
        case .meeting:       .cyan
        case .meal:          .pink
        case .other:         .secondary
        }
    }

    @ViewBuilder
    private func caseGroup(title: String, participations: [CaseParticipant]) -> some View {
        ForEach(participations) { participation in
            if let caseRecord = participation.caseRecord {
                NavigationLink {
                    CaseDetailView(caseRecord: caseRecord)
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
