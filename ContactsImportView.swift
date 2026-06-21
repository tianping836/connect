import SwiftUI
import SwiftData
import Contacts

/// 通讯录导入界面
/// 三入口：人脉列表空状态 / 人脉列表顶部横幅 / 设置页
struct ContactsImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var importManager = ContactsImportManager.shared

    @Query(sort: \Person.name) private var existingPersons: [Person]

    @State private var entries: [ContactsImportManager.ImportEntry] = []
    @State private var selectAll = false
    @State private var isImporting = false
    @State private var importComplete = false
    @State private var importedCount = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if importComplete {
                    importCompleteView
                } else if !importManager.isAuthorized {
                    permissionRequestView
                } else if entries.isEmpty {
                    loadingView
                } else {
                    importListView
                }
            }
            .navigationTitle("导入通讯录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                if importComplete {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("完成") { dismiss() }
                    }
                }
            }
            .task {
                await loadContacts()
            }
        }
    }

    // MARK: - 权限请求

    private var permissionRequestView: some View {
        VStack(spacing: Spacing.xl) {
            Spacer().frame(height: 60)

            ZStack {
                Circle()
                    .fill(Color.tealLink.opacity(0.1))
                    .frame(width: 96, height: 96)
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 40))
                    .foregroundColor(.tealLink)
            }

            Text("访问通讯录")
                .font(.cnTitle2)
                .foregroundColor(.textPrimary)

            Text("屿连需要访问你的系统通讯录，
将联系人导入你的人脉网络。")
                .font(.cnBody)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xxl)

            Button {
                Task {
                    let granted = await importManager.requestAccess()
                    if granted {
                        await loadContacts()
                    }
                }
            } label: {
                Text("允许访问")
                    .font(.cnBody.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.xxl)
                    .padding(.vertical, Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.button)
                            .fill(Color.tealLink)
                    )
            }

            Text("你的通讯录数据仅存储在本机，不会上传。")
                .font(.cnCaption1)
                .foregroundColor(.textTertiary)
                .padding(.top, Spacing.sm)

            Spacer()
        }
    }

    // MARK: - 加载中

    private var loadingView: some View {
        VStack(spacing: Spacing.base) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("正在读取通讯录...")
                .font(.cnBody)
                .foregroundColor(.textSecondary)
            Spacer()
        }
    }

    // MARK: - 导入列表

    private var importListView: some View {
        VStack(spacing: 0) {
            statsCard
                .padding(.horizontal, Spacing.base)
                .padding(.top, Spacing.base)

            HStack {
                Toggle("全选", isOn: $selectAll)
                    .labelsHidden()
                    .onChange(of: selectAll) { _, newValue in
                        entries = entries.map { entry in
                            var e = entry
                            if case .new = entry.status {
                                e.isSelected = newValue
                            }
                            return e
                        }
                    }
                Text("全选")
                    .font(.cnSubhead)
                    .foregroundColor(.tealLink)
                Spacer()
                Text("\(selectedCount) 位已选")
                    .font(.cnSubhead)
                    .foregroundColor(.textTertiary)
            }
            .padding(.horizontal, Spacing.base)
            .padding(.vertical, Spacing.sm)

            Divider()
                .padding(.horizontal, Spacing.base)

            List {
                if !newEntries.isEmpty {
                    Section {
                        ForEach($entries.filter { if case .new = $0.wrappedValue.status { return true }; return false }) { $entry in
                            contactRow(entry: $entry)
                        }
                    } header: {
                        Text("新发现 · \(newEntries.count) 人")
                    }
                }

                let importedEntries = entries.filter { if case .alreadyImported = $0.status { return true }; return false }
                if !importedEntries.isEmpty {
                    Section {
                        ForEach(importedEntries) { entry in
                            HStack(spacing: Spacing.md) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.statusSuccess)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.name)
                                        .font(.cnBody)
                                        .foregroundColor(.textSecondary)
                                    if let org = entry.org {
                                        Text(org)
                                            .font(.cnCaption1)
                                            .foregroundColor(.textTertiary)
                                    }
                                }

                                Spacer()

                                Text("已导入")
                                    .font(.cnCaption2)
                                    .foregroundColor(.textTertiary)
                                    .padding(.horizontal, Spacing.sm)
                                    .padding(.vertical, 2)
                                    .background(Color.textTertiary.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.tag))
                            }
                            .padding(.vertical, Spacing.xs)
                        }
                    } header: {
                        Text("已导入 · \(importedEntries.count) 人")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.surfaceLight)

            if selectedCount > 0 && !isImporting {
                Button {
                    importSelected()
                } label: {
                    Text("导入 \(selectedCount) 位联系人")
                        .font(.cnBody.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.button)
                                .fill(Color.tealLink)
                        )
                }
                .padding(.horizontal, Spacing.base)
                .padding(.vertical, Spacing.md)
                .background(.regularMaterial)
            }

            if isImporting {
                HStack(spacing: Spacing.sm) {
                    ProgressView()
                    Text("正在导入...")
                        .font(.cnSubhead)
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(.regularMaterial)
            }
        }
    }

    // MARK: - 统计卡片

    private var statsCard: some View {
        HStack(spacing: 0) {
            statItem(value: "\(importManager.allContacts.count)", label: "通讯录")
            Spacer()
            Text("·").foregroundColor(.textTertiary)
            Spacer()
            statItem(value: "\(importedEntries.count)", label: "已导入")
            Spacer()
            Text("·").foregroundColor(.textTertiary)
            Spacer()
            statItem(value: "\(newEntries.count)", label: "新发现")
        }
        .padding(.vertical, Spacing.md)
        .padding(.horizontal, Spacing.base)
        .background(Color.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.cnTitle3.monospacedDigit())
                .foregroundColor(.textPrimary)
            Text(label)
                .font(.cnCaption1)
                .foregroundColor(.textTertiary)
        }
    }

    private func contactRow(entry: Binding<contactsimportmanager.importentry>) -> some View {
        HStack(spacing: Spacing.md) {
            Button {
                entry.wrappedValue.isSelected.toggle()
            } label: {
                Image(systemName: entry.wrappedValue.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(entry.wrappedValue.isSelected ? .tealLink : .textTertiary)
            }
            .buttonStyle(.plain)

            ZStack {
                Circle()
                    .fill(Color.tealLink.opacity(0.1))
                    .frame(width: 40, height: 40)
                Text(String(entry.wrappedValue.name.prefix(1)))
                    .font(.cnHeadline)
                    .foregroundColor(.tealLink)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.wrappedValue.name)
                    .font(.cnBody)
                    .foregroundColor(.textPrimary)
                if let phone = entry.wrappedValue.phone {
                    Text(phone)
                        .font(.cnCaption1)
                        .foregroundColor(.textTertiary)
                }
            }

            Spacer()

            if let org = entry.wrappedValue.org {
                Text(org)
                    .font(.cnCaption2)
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 2)
                    .background(Color.textTertiary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.tag))
            }
        }
        .padding(.vertical, Spacing.xs)
    }

    // MARK: - 导入完成

    private var importCompleteView: some View {
        VStack(spacing: Spacing.base) {
            Spacer().frame(height: 80)

            ZStack {
                Circle()
                    .fill(Color.statusSuccess.opacity(0.1))
                    .frame(width: 96, height: 96)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.statusSuccess)
            }

            Text("导入完成")
                .font(.cnTitle2)
                .foregroundColor(.textPrimary)

            Text("已从通讯录导入 \(importedCount) 位联系人，
现在你可以在「人脉」中查看他们。")
                .font(.cnBody)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xxl)

            Spacer()
        }
    }

    // MARK: - 数据操作

    private var newEntries: [ContactsImportManager.ImportEntry] {
        entries.filter { if case .new = $0.status { return true }; return false }
    }

    private var importedEntries: [ContactsImportManager.ImportEntry] {
        entries.filter { if case .alreadyImported = $0.status { return true }; return false }
    }

    private var selectedCount: Int {
        entries.filter { $0.isSelected }.count
    }

    private func loadContacts() async {
        guard importManager.isAuthorized else { return }

        let contacts = importManager.fetchAllContacts()

        entries = contacts.map { contact in
            let name = importManager.fullName(for: contact)
            let phone = importManager.primaryPhone(for: contact)
            let org = importManager.organization(for: contact)
            let status: ContactsImportManager.ImportStatus =
                importManager.findExistingPerson(for: contact, in: existingPersons) != nil
                ? .alreadyImported : .new

            return ContactsImportManager.ImportEntry(
                id: contact.identifier,
                contact: contact,
                name: name,
                phone: phone,
                org: org,
                status: status,
                isSelected: false
            )
        }
    }

    private func importSelected() {
        isImporting = true
        let selected = entries.filter { $0.isSelected && (if case .new = $0.status { true } else { false }) }

        for entry in selected {
            _ = importManager.importContact(entry.contact, into: modelContext)
        }

        try? modelContext.save()
        importedCount = selected.count
        isImporting = false
        importComplete = true
    }
}
</contactsimportmanager.importentry>