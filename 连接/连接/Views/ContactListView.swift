import SwiftUI
import SwiftData
import Contacts

// MARK: - 平台适配

#if os(iOS)
private let searchFieldPlacement: SearchFieldPlacement = .navigationBarDrawer(displayMode: .always)
#else
private let searchFieldPlacement: SearchFieldPlacement = .automatic
#endif

/// 人脉列表页——搜索 / 角色筛选 / 排序 / 分组展示
struct ContactListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Contact.name) private var contacts: [Contact]

    @State private var viewModel = ContactListViewModel()
    @State private var showAddContact = false
    @State private var showImportContacts = false
    @State private var isImportingAll = false
    @State private var importResult: String?
    @FocusState private var searchFocused: Bool

    var body: some View {
        NavigationStack {
            Group {
                if contacts.isEmpty {
                    emptyState
                } else {
                    listContent
                }
            }
            .navigationTitle("人脉")
            .searchable(text: $viewModel.searchText, placement: searchFieldPlacement, prompt: "搜索姓名、单位、技能...")
            .toolbar {
                toolbarContent
            }
            .sheet(isPresented: $showAddContact) {
                ContactEditView()
            }
            .sheet(isPresented: $showImportContacts) {
                ImportContactsView()
            }
            .onReceive(NotificationCenter.default.publisher(for: .newItemRequested)) { notif in
                if let tab = notif.object as? AppTab, tab == .contacts {
                    showAddContact = true
                }
            }
            .onAppear {
                viewModel.loadContacts(contacts)
                syncNewContacts()
            }
            .onChange(of: contacts) { _, newValue in viewModel.loadContacts(newValue) }
            .onChange(of: viewModel.searchText) { _, _ in viewModel.loadContacts(contacts) }
        }
    }

    // MARK: - 列表内容

    private var listContent: some View {
        List {
            // 筛选栏
            Section {
                roleFilterBar
            }

            // 高优先级区（展开）
            if !viewModel.importantContacts.isEmpty && !viewModel.isFiltering {
                Section("⭐ 重要") {
                    ForEach(viewModel.importantContacts) { contact in
                        NavigationLink {
                            ContactDetailView(contact: contact)
                        } label: {
                            ContactRowView(contact: contact)
                        }
                        .swipeActions(edge: .trailing) {
                            Button("归档", systemImage: "archivebox") {
                                archiveContact(contact)
                            }
                            .tint(.gray)
                        }
                    }
                }
            }

            // 按关系阶段分组
            if viewModel.isFiltering {
                Section("\(viewModel.totalCount) 个结果") {
                    ForEach(viewModel.contactsByStage.flatMap(\.1)) { contact in
                        contactRow(contact)
                    }
                }
            } else {
                ForEach(viewModel.contactsByStage, id: \.0) { stage, stageContacts in
                    Section(stage.rawValue) {
                        ForEach(stageContacts) { contact in
                            contactRow(contact)
                        }
                    }
                }
            }
        }
        .listStyle(.inset)
    }

    private func contactRow(_ contact: Contact) -> some View {
        NavigationLink {
            ContactDetailView(contact: contact)
        } label: {
            ContactRowView(contact: contact)
        }
        .swipeActions(edge: .trailing) {
            Button("归档", systemImage: "archivebox") {
                archiveContact(contact)
            }
            .tint(.gray)
        }
        .swipeActions(edge: .leading) {
            Button(contact.importance >= 5 ? "取消星标" : "星标", systemImage: contact.importance >= 5 ? "star.slash" : "star") {
                toggleImportance(contact)
            }
            .tint(.orange)
        }
    }

    // MARK: - 角色筛选栏

    private var roleFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(label: "全部", isSelected: viewModel.selectedRoleFilter == nil) {
                    viewModel.selectedRoleFilter = nil
                }

                ForEach(ContactRole.allCases.prefix(8)) { role in
                    FilterChip(
                        label: role.rawValue,
                        isSelected: viewModel.selectedRoleFilter == role,
                        colorHex: role.colorHex
                    ) {
                        viewModel.selectedRoleFilter = (viewModel.selectedRoleFilter == role) ? nil : role
                    }
                }

                // 排序
                Divider().frame(height: 20)

                Menu {
                    Picker("排序", selection: $viewModel.sortOrder) {
                        ForEach(ContactListViewModel.SortOrder.allCases) { order in
                            Text(order.rawValue).tag(order)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.secondary.opacity(0.15))
                        .clipShape(.capsule)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - 空状态

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("还没有人脉")
                .font(.title3.weight(.medium))

            Text("添加你的第一个人脉\n客户、法官、同事、朋友……")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showAddContact = true
            } label: {
                Label("添加第一个人脉", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - 工具栏

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                showAddContact = true
            } label: {
                Image(systemName: "plus")
            }
            .keyboardShortcut("n", modifiers: .command)
        }
        ToolbarItem(placement: .secondaryAction) {
            HStack(spacing: 12) {
                // 一键导入全部通讯录
                Button {
                    importAllContacts()
                } label: {
                    if isImportingAll {
                        ProgressView().scaleEffect(0.7)
                    } else {
                        Image(systemName: "arrow.down.doc")
                    }
                }
                .disabled(isImportingAll)
                .keyboardShortcut("i", modifiers: .command)

                Menu {
                    Toggle("显示已归档", isOn: $viewModel.showArchived)
                    Divider()
                    Button {
                        showImportContacts = true
                    } label: {
                        Label("选择导入...", systemImage: "person.crop.circle.badge.plus")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }

    // MARK: - 操作

    private func archiveContact(_ contact: Contact) {
        withAnimation {
            contact.isArchived = true
            try? modelContext.save()
        }
    }

    private func toggleImportance(_ contact: Contact) {
        withAnimation {
            contact.importance = contact.importance >= 5 ? 3 : 5
            try? modelContext.save()
        }
    }

    // MARK: - 自动同步新增联系人

    /// 检查通讯录中是否有新联系人，静默导入
    private func syncNewContacts() {
        let lastImport = UserDefaults.standard.double(forKey: "last_contact_import")
        // 从未导入过，跳过自动同步（用户可能想手动控制首次导入）
        guard lastImport > 0 else { return }

        Task {
            let status = ContactImporter.shared.authorizationStatus
            guard status == .authorized else { return }
            do {
                let all = try await ContactImporter.shared.fetchAllContacts()
                guard !all.isEmpty else { return }
                let count = try ContactImporter.shared.importSelected(all, modelContext: modelContext)
                if count > 0 {
                    UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "last_contact_import")
                    await MainActor.run { viewModel.loadContacts(contacts) }
                }
            } catch { /* 静默失败，不影响使用 */ }
        }
    }

    // MARK: - 一键导入通讯录

    private func importAllContacts() {
        isImportingAll = true
        importResult = nil
        Task {
            let granted = await ContactImporter.shared.requestAccess()
            guard granted else {
                await MainActor.run {
                    importResult = "通讯录权限未授权，请在系统设置中开启"
                    isImportingAll = false
                }
                return
            }
            do {
                let count = try await ContactImporter.shared.importAll(modelContext: modelContext)
                UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "last_contact_import")
                await MainActor.run {
                    importResult = "已导入 \(count) 位联系人"
                    isImportingAll = false
                    // 刷新列表
                    viewModel.loadContacts(contacts)
                }
            } catch {
                await MainActor.run {
                    importResult = "导入失败: \(error.localizedDescription)"
                    isImportingAll = false
                }
            }
        }
    }
}

// MARK: - 筛选胶囊

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    var colorHex: String? = nil
    let action: () -> Void

    private var accentColor: Color {
        if let hex = colorHex {
            Color(hex: hex)
        } else {
            .accentColor
        }
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isSelected ? accentColor.opacity(0.15) : Color.secondary.opacity(0.15))
                .foregroundStyle(isSelected ? accentColor : .secondary)
                .clipShape(.capsule)
                .overlay(
                    Capsule()
                        .stroke(isSelected ? accentColor.opacity(0.3) : .clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#if DEBUG
#Preview {
    let container = ModelContainer.appContainer
    let context = container.mainContext
    PreviewData.create(modelContext: context)
    return ContactListView()
        .modelContainer(container)
}
#endif
