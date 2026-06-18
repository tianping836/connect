import SwiftUI
import SwiftData

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
            .navigationTitle("Contacts")
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
            .onAppear { viewModel.loadContacts(contacts) }
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
                Section("Important") {
                    ForEach(viewModel.importantContacts) { contact in
                        NavigationLink {
                            ContactDetailView(contact: contact)
                        } label: {
                            ContactRowView(contact: contact)
                        }
                        .swipeActions(edge: .trailing) {
                            Button("Archive", systemImage: "archivebox") {
                                archiveContact(contact)
                            }
                            .tint(.gray)
                        }
                    }
                }
            }

            // 按关系阶段分组
            if viewModel.isFiltering {
                Section("\(viewModel.totalCount) Result(s)") {
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
            Button("Archive", systemImage: "archivebox") {
                archiveContact(contact)
            }
            .tint(.gray)
        }
        .swipeActions(edge: .leading) {
            Button(contact.importance >= 5 ? "Unstar" : "Star", systemImage: contact.importance >= 5 ? "star.slash" : "star") {
                toggleImportance(contact)
            }
            .tint(.orange)
        }
    }

    // MARK: - 角色筛选栏

    private var roleFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(label: "All", isSelected: viewModel.selectedRoleFilter == nil) {
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
                    Picker("Sort", selection: $viewModel.sortOrder) {
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

            Text("No contacts yet")
                .font(.title3.weight(.medium))

            Text("Add your first contact\nclients, judges, colleagues, friends...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showAddContact = true
            } label: {
                Label("Add your first contact", systemImage: "plus")
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
            Menu {
                Toggle("Show archived", isOn: $viewModel.showArchived)
                Divider()
                Button {
                    showImportContacts = true
                } label: {
                    Label("Import from Contacts", systemImage: "person.crop.circle.badge.plus")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
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
