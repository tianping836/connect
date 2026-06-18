import SwiftUI
import UIKit
import Contacts
import SwiftData

/// 从系统通讯录导入联系人——权限请求 → 预览 → 多选导入
struct ImportContactsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var authorizationStatus: CNAuthorizationStatus = .notDetermined
    @State private var allContacts: [CNContact] = []
    @State private var selectedIDs: Set<String> = []
    @State private var isLoading = true
    @State private var importedCount = 0
    @State private var showResult = false

    var body: some View {
        NavigationStack {
            Group {
                switch authorizationStatus {
                case .notDetermined:
                    requestAccessView
                case .denied, .restricted:
                    deniedView
                case .authorized:
                    if isLoading {
                        ProgressView("正在加载通讯录…")
                    } else if showResult {
                        resultView
                    } else {
                        contactList
                    }
                @unknown default:
                    requestAccessView
                }
            }
            .navigationTitle("从通讯录导入")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .task {
                authorizationStatus = ContactImporter.shared.authorizationStatus
                if authorizationStatus == .authorized {
                    await loadContacts()
                }
            }
        }
        #if os(iOS)
        .presentationDetents([.large])
        #endif
    }

    // MARK: - 权限请求

    private var requestAccessView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.system(size: 56))
                .foregroundStyle(.blue)

            Text("访问你的通讯录")
                .font(.title2.weight(.semibold))

            Text("连接需要读取通讯录以导入联系人。你的数据仅存储在本地。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                Task {
                    let granted = await ContactImporter.shared.requestAccess()
                    authorizationStatus = granted ? .authorized : .denied
                    if granted { await loadContacts() }
                }
            } label: {
                Label("允许访问", systemImage: "hand.raised")
                    .frame(maxWidth: 240)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer()
        }
    }

    // MARK: - 拒绝

    private var deniedView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "lock.shield")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text("通讯录访问被拒绝")
                .font(.title2.weight(.semibold))

            Text("请前往 设置 → 隐私 → 通讯录 开启访问权限。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            #if os(iOS)
            Button("打开设置") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.bordered)
            #endif

            Spacer()
        }
    }

    // MARK: - 联系人列表

    private var contactList: some View {
        VStack(spacing: 0) {
            // 全选/反选
            HStack {
                Button(selectedIDs.count == allContacts.count ? "取消全选" : "全选") {
                    if selectedIDs.count == allContacts.count {
                        selectedIDs.removeAll()
                    } else {
                        selectedIDs = Set(allContacts.map(\.identifier))
                    }
                }
                .font(.subheadline)

                Spacer()

                Text("已选 \(selectedIDs.count) 人")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            List {
                ForEach(allContacts, id: \.identifier) { cn in
                    contactRow(cn)
                }
            }
            .listStyle(.inset)

            // 底部导入按钮
            if !selectedIDs.isEmpty {
                VStack {
                    Button {
                        importSelected()
                    } label: {
                        Label("导入 \(selectedIDs.count) 人", systemImage: "arrow.down.doc")
                            .frame(maxWidth: 300)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.vertical, 12)
                .background(.regularMaterial)
            }
        }
    }

    private func contactRow(_ cn: CNContact) -> some View {
        let isSelected = selectedIDs.contains(cn.identifier)
        let fullName = cn.familyName + cn.givenName
        let phone = cn.phoneNumbers.first?.value.stringValue ?? ""

        return Button {
            if isSelected {
                selectedIDs.remove(cn.identifier)
            } else {
                selectedIDs.insert(cn.identifier)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.blue : Color.secondary)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(fullName.isEmpty ? "No name" : fullName)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    if !phone.isEmpty {
                        Text(phone)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if !cn.organizationName.isEmpty {
                    Text(cn.organizationName)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - 结果

    private var resultView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)

            Text("已导入 \(importedCount) 人")
                .font(.title2.weight(.semibold))

            Text(importedCount > 0 ? "联系人已添加到人脉列表中。" : "未导入新联系人（可能已存在）。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button("完成") { dismiss() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

            Spacer()
        }
    }

    // MARK: - 操作

    private func loadContacts() async {
        isLoading = true
        do {
            allContacts = try await ContactImporter.shared.fetchAllContacts()
        } catch {
            allContacts = []
        }
        isLoading = false
    }

    private func importSelected() {
        let selected = allContacts.filter { selectedIDs.contains($0.identifier) }
        do {
            importedCount = try ContactImporter.shared.importSelected(selected, modelContext: modelContext)
        } catch {
            importedCount = 0
        }
        showResult = true
    }
}

#if DEBUG
#Preview {
    ImportContactsView()
        .modelContainer(for: [Contact.self])
}
#endif
