import SwiftUI
import SwiftData

/// 人脉列表页 — 搜索框 + 角色胶囊筛选 + 排序切换 + 简化联系人卡片
struct PersonListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Person.importance, order: .reverse), SortDescriptor(\Person.name)])
    private var allPersons: [Person]
    @State private var searchText = ""
    @State private var selectedRole: PersonRoleType? = nil
    @State private var sortMode: PersonSortMode = .connection
    @FocusState private var isSearchFocused: Bool
    @State private var starFeedbackTrigger = false
    @State private var searchFocusToken: NSObjectProtocol?

    enum PersonSortMode: String, CaseIterable {
        case connection = "连接"; case name = "姓名"
        var systemImage: String {
            switch self { case .connection: return "bolt.horizontal.fill"; case .name: return "textformat.abc" }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SearchBar(text: $searchText, placeholder: "搜索你网络里的任何人...")
                    .focused($isSearchFocused).padding(.horizontal, Spacing.base).padding(.top, Spacing.sm).padding(.bottom, Spacing.sm)
                roleFilterBar.searchFocusAnimation(isFocused: isSearchFocused || !searchText.isEmpty)
                sortToggleBar
                ScrollView {
                    LazyVStack(spacing: Spacing.md) {
                        if !importantPersons.isEmpty {
                            sectionHeader("★ 重要")
                            ForEach(Array(importantPersons.enumerated()), id: \.element.id) { index, person in
                                NavigationLink { PersonDetailPlaceholderView(person: person) } label: { PersonRow(person: person) }
                                    .buttonStyle(.plain).staggerEntrance(index: index)
                                    .swipeActions(edge: .trailing) {
                                        Button { withAnimation(.easeInOut(duration: 0.2)) { toggleStar(person) } } label: { Label(person.importance >= 5 ? "取消星标" : "星标", systemImage: person.importance >= 5 ? "star.slash" : "star.fill") }.tint(.coralWarm)
                                        Button { withAnimation(.easeInOut(duration: 0.2)) { person.isArchived.toggle() } } label: { Label("归档", systemImage: "archivebox.fill") }.tint(.textTertiary)
                                    }
                                    .contextMenu {
                                        if let phone = person.phone, !phone.isEmpty { Button { UIPasteboard.general.string = phone } label: { Label("复制电话", systemImage: "phone.fill") } }
                                        if let email = person.email, !email.isEmpty { Button { Clipboard.copy(email) } label: { Label("复制邮箱", systemImage: "envelope.fill") } }
                                        NavigationLink { PersonEditPlaceholderView() } label: { Label("编辑", systemImage: "pencil") }
                                        Button { withAnimation(.easeInOut(duration: 0.2)) { toggleStar(person) } } label: { Label(person.importance >= 5 ? "取消星标" : "星标", systemImage: person.importance >= 5 ? "star.slash" : "star.fill") }
                                    }
                                    #if os(iOS)
                                    .sensoryFeedback(.impact(.light), trigger: starFeedbackTrigger)
                                    #endif
                            }
                        }
                        if !regularPersons.isEmpty {
                            sectionHeader(searchText.isEmpty && selectedRole == nil ? "你的网络" : "匹配结果")
                            ForEach(Array(regularPersons.enumerated()), id: \.element.id) { index, person in
                                NavigationLink { PersonDetailPlaceholderView(person: person) } label: { PersonRow(person: person) }
                                    .buttonStyle(.plain).staggerEntrance(index: index)
                                    .swipeActions(edge: .trailing) {
                                        Button { withAnimation(.easeInOut(duration: 0.2)) { toggleStar(person) } } label: { Label(person.importance >= 5 ? "取消星标" : "星标", systemImage: person.importance >= 5 ? "star.slash" : "star.fill") }.tint(.coralWarm)
                                        Button { withAnimation(.easeInOut(duration: 0.2)) { person.isArchived.toggle() } } label: { Label("归档", systemImage: "archivebox.fill") }.tint(.textTertiary)
                                    }
                                    .contextMenu {
                                        if let phone = person.phone, !phone.isEmpty { Button { UIPasteboard.general.string = phone } label: { Label("复制电话", systemImage: "phone.fill") } }
                                        if let email = person.email, !email.isEmpty { Button { Clipboard.copy(email) } label: { Label("复制邮箱", systemImage: "envelope.fill") } }
                                        NavigationLink { PersonEditPlaceholderView() } label: { Label("编辑", systemImage: "pencil") }
                                        Button { withAnimation(.easeInOut(duration: 0.2)) { toggleStar(person) } } label: { Label(person.importance >= 5 ? "取消星标" : "星标", systemImage: person.importance >= 5 ? "star.slash" : "star.fill") }
                                    }
                                    #if os(iOS)
                                    .sensoryFeedback(.impact(.light), trigger: starFeedbackTrigger)
                                    #endif
                            }
                        }
                        if filteredPersons.isEmpty { emptyStateView }
                    }
                    .padding(.horizontal, Spacing.base).padding(.vertical, Spacing.md)
                }
                .background(Color.surfaceLight)
            }
            .background(Color.surfaceLight).navigationTitle("人脉")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink { PersonEditPlaceholderView() } label: { Image(systemName: "plus.circle.fill").font(.system(size: 22)).foregroundColor(.tealLink) }
                }
            }
        }
        .onAppear {
            searchFocusToken = NotificationCenter.default.publisher(for: .islandLinkFocusSearch).sink { _ in isSearchFocused = true }
        }
        .onDisappear {
            if let token = searchFocusToken { NotificationCenter.default.removeObserver(token) }
        }
    }

    @ViewBuilder
    private var roleFilterBar: some View {
        if isSearchFocused || !searchText.isEmpty || selectedRole != nil {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    roleFilterChip(label: "全部", systemImage: "person.2", color: .oceanDeep, isSelected: selectedRole == nil) { withAnimation(.easeInOut(duration: 0.2)) { selectedRole = nil } }
                    ForEach(PersonRoleType.allCases) { roleType in
                        roleFilterChip(label: "\(roleType.rawValue)", systemImage: roleType.systemImage, color: roleType.swiftUIColor, isSelected: selectedRole == roleType) {
                            withAnimation(.easeInOut(duration: 0.2)) { selectedRole = (selectedRole == roleType) ? nil : roleType }
                        }
                    }
                }
                .padding(.horizontal, Spacing.base).padding(.bottom, Spacing.sm)
            }
        }
    }

    private func roleFilterChip(label: String, systemImage: String, color: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) { Image(systemName: systemImage).font(.system(size: 12, weight: .medium)); Text(label).font(.cnCaption1) }
                .foregroundColor(isSelected ? .white : color).padding(.horizontal, Spacing.md).padding(.vertical, Spacing.sm)
                .background(Capsule(style: .continuous).fill(isSelected ? color : color.opacity(0.12)))
        }.buttonStyle(.plain)
    }

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View { HStack { Text(title).font(.cnTitle3).foregroundColor(.textPrimary); Spacer() }.padding(.top, Spacing.lg) }

    @ViewBuilder
    private var sortToggleBar: some View {
        HStack(spacing: Spacing.sm) {
            Spacer()
            ForEach(PersonSortMode.allCases, id: \.self) { mode in
                Button { withAnimation(.easeInOut(duration: 0.2)) { sortMode = mode } } label: {
                    HStack(spacing: 3) { Image(systemName: mode.systemImage).font(.system(size: 10, weight: .medium)); Text(mode.rawValue).font(.cnCaption2) }
                        .foregroundColor(sortMode == mode ? .white : .textSecondary).padding(.horizontal, Spacing.sm).padding(.vertical, Spacing.xs)
                        .background(Capsule(style: .continuous).fill(sortMode == mode ? Color.tealLink : Color.surfaceCard))
                        .overlay(Capsule(style: .continuous).stroke(sortMode == mode ? Color.clear : Color.divider, lineWidth: 1))
                }.buttonStyle(.plain)
            }
        }.padding(.horizontal, Spacing.base).padding(.bottom, Spacing.sm)
    }

    private var emptyStateView: some View {
        VStack(spacing: Spacing.base) {
            Spacer().frame(height: 60)
            Image(systemName: "person.2.slash").font(.system(size: 48)).foregroundColor(.tealLink.opacity(0.5))
            Text(searchText.isEmpty ? "还没有联系人。加第一位？" : "没有匹配的联系人").font(.cnHeadline).foregroundColor(.textPrimary)
            Text(searchText.isEmpty ? "每个案件背后都有人。从第一个人开始。" : "换个关键词或调整筛选条件试试").font(.cnBody).foregroundColor(.textSecondary).multilineTextAlignment(.center).padding(.horizontal, Spacing.xxl)
        }
    }

    private var filteredPersons: [Person] {
        var result = allPersons.filter { !$0.isArchived }
        if let role = selectedRole { result = result.filter { $0.roleTypes.contains(role) } }
        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            let q = searchText.lowercased()
            result = result.filter { $0.name.localizedStandardContains(q) || $0.pinyin.contains(q) || $0.pinyinInitials.contains(q) || ($0.org?.localizedStandardContains(q) ?? false) }
        }
        result = applySort(result)
        return result
    }

    private func applySort(_ persons: [Person]) -> [Person] {
        switch sortMode {
        case .connection:
            return persons.sorted { a, b in
                let aDate = a.lastActiveDate ?? Date.distantPast; let bDate = b.lastActiveDate ?? Date.distantPast
                if aDate != bDate { return aDate > bDate }; return a.importance > b.importance
            }
        case .name: return persons.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
        }
    }

    private var importantPersons: [Person] { filteredPersons.filter { $0.importance >= 4 } }
    private var regularPersons: [Person] { filteredPersons.filter { $0.importance < 4 } }

    private func toggleStar(_ person: Person) { person.importance = person.importance >= 5 ? 3 : 5; starFeedbackTrigger.toggle() }
}

// MARK: - 人脉详情占位

struct PersonDetailPlaceholderView: View {
    let person: Person
    @AppStorage("caseModuleEnabled") private var caseModuleEnabled: Bool = true

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.base) {
                VStack(spacing: Spacing.sm) {
                    if let primaryRole = person.roleTypes.first { LargeAvatarPlaceholder(roleType: primaryRole) }
                    Text(person.name).font(.cnTitle1).foregroundColor(.textPrimary)
                    HStack(spacing: Spacing.xs) { ForEach(person.roleTypes, id: \.self) { roleType in RoleTypeTag(roleType: roleType) } }
                    if let org = person.org { Text(person.title.map { "\($0) · \(org)" } ?? org).font(.cnSubhead).foregroundColor(.textSecondary) }
                }.padding(Spacing.base).cardStyleSolid()
                if hasContactInfo { contactCard }
                if caseModuleEnabled && !person.casesByRole.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("参与的案件").font(.cnTitle3).foregroundColor(.textPrimary).padding(.horizontal, Spacing.base).padding(.vertical, Spacing.md)
                        Divider().background(Color.divider)
                        ForEach(person.casesByRole, id: \.0.rawValue) { roleType, casePersons in
                            ForEach(casePersons, id: \.id) { cp in
                                if let c = cp.case {
                                    VStack(alignment: .leading, spacing: 2) { Text(c.name).font(.cnHeadline).foregroundColor(.textPrimary); HStack { Text(cp.role).font(.cnCaption1).foregroundColor(.textSecondary); StatusBadge(status: c.caseStatus) } }
                                        .padding(.horizontal, Spacing.base).padding(.vertical, Spacing.md)
                                    Divider().background(Color.divider).padding(.leading, Spacing.base)
                                }
                            }
                        }
                    }.background(Color.surfaceCard).clipShape(RoundedRectangle(cornerRadius: CornerRadius.card)).cardShadow()
                }
            }.padding(.horizontal, Spacing.base).padding(.vertical, Spacing.md)
        }.background(Color.surfaceLight).navigationTitle("人脉详情").navigationBarTitleDisplayMode(.inline)
    }

    private var hasContactInfo: Bool { person.phone != nil || person.email != nil || person.wechat != nil || person.address != nil }

    private var contactCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("联系方式").font(.cnTitle3).foregroundColor(.textPrimary)
            if let phone = person.phone { contactRow(icon: "phone.fill", text: phone) }
            if let email = person.email { contactRow(icon: "envelope.fill", text: email) }
            if let wechat = person.wechat { contactRow(icon: "message.fill", text: wechat) }
            if let address = person.address { contactRow(icon: "mappin.and.ellipse", text: address) }
        }.padding(Spacing.base).cardStyleSolid()
    }

    private func contactRow(icon: String, text: String) -> some View {
        HStack(spacing: Spacing.md) { Image(systemName: icon).font(.system(size: 16)).foregroundColor(.tealLink).frame(width: 24); Text(text).font(.cnBody).foregroundColor(.textPrimary) }
    }
}

// MARK: - 新建人脉占位

struct PersonEditPlaceholderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subManager: SubscriptionManager
    @State private var name = ""; @State private var org = ""; @State private var title_ = ""
    @State private var phone = ""; @State private var notes = ""
    @State private var selectedRoles: [PersonRoleType] = []

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("姓名（必填）", text: $name).textContentType(.name)
                    HStack { ForEach(selectedRoles, id: \.self) { role in RoleTypeTag(roleType: role) } }
                    Picker("角色类型", selection: Binding(get: { selectedRoles.first ?? .other }, set: { newRole in if !selectedRoles.contains(newRole) { selectedRoles.append(newRole) } })) { ForEach(PersonRoleType.allCases) { roleType in Text(roleType.rawValue).tag(roleType) } }
                }
                Section("单位信息") { TextField("单位", text: $org).textContentType(.organizationName); TextField("职务", text: $title_).textContentType(.jobTitle) }
                Section("联系方式") { TextField("电话", text: $phone).textContentType(.telephoneNumber) }
                Section("备注") { TextField("备注", text: $notes, axis: .vertical).lineLimit(2...4).textContentType(.none) }
            }
            .scrollContentBackground(.hidden).background(Color.surfaceLight).navigationTitle("新建联系人").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("保存") { savePerson() }.fontWeight(.semibold).disabled(name.trimmingCharacters(in: .whitespaces).isEmpty) }
            }
        }
    }

    private func savePerson() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        guard subManager.canAddPerson else { subManager.showUpgradeSheet = true; return }
        let person = Person(name: trimmedName, roleTypes: selectedRoles, org: org.trimmingCharacters(in: .whitespaces).isEmpty ? nil : org, title: title_.trimmingCharacters(in: .whitespaces).isEmpty ? nil : title_, phone: phone.trimmingCharacters(in: .whitespaces).isEmpty ? nil : phone, notes: notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes)
        modelContext.insert(person); try? modelContext.save(); dismiss()
    }
}