import SwiftUI
import SwiftData

/// 检测重复联系人并允许合并
struct DuplicateMergeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Contact.name) private var allContacts: [Contact]

    @State private var duplicateGroups: [[Contact]] = []
    @State private var selectedToKeep: Contact?
    @State private var selectedToDiscard: Contact?
    @State private var showMergeConfirm = false

    var body: some View {
        NavigationStack {
            Group {
                if duplicateGroups.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.green)
                        Text("未发现重复联系人")
                            .font(.title3)
                        Text("当前 \(allContacts.count) 位联系人信息均已去重")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(duplicateGroups.indices, id: \.self) { idx in
                            let group = duplicateGroups[idx]
                            Section("疑似重复 #\(idx + 1)") {
                                ForEach(group) { contact in
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(contact.name).font(.subheadline.weight(.medium))
                                            if let phone = contact.phone {
                                                Text(phone).font(.caption).foregroundStyle(.secondary)
                                            }
                                            if let org = contact.organization {
                                                Text(org.name).font(.caption2).foregroundStyle(.tertiary)
                                            }
                                        }
                                        Spacer()
                                        if selectedToKeep?.id == contact.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.green)
                                        }
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        if selectedToKeep == nil {
                                            selectedToKeep = contact
                                            selectedToDiscard = group.first { $0.id != contact.id }
                                            showMergeConfirm = true
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("去重检查")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("刷新") { detectDuplicates() }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .onAppear { detectDuplicates() }
            .alert("合并联系人", isPresented: $showMergeConfirm) {
                Button("取消", role: .cancel) {
                    selectedToKeep = nil; selectedToDiscard = nil
                }
                Button("合并", role: .destructive) {
                    performMerge()
                }
            } message: {
                if let keep = selectedToKeep, let discard = selectedToDiscard {
                    Text("将「\(discard.name)」的所有关联数据迁移到「\(keep.name)」并删除前者。\n此操作不可撤销。")
                }
            }
        }
    }

    private func detectDuplicates() {
        var groups: [[Contact]] = []
        let contacts = allContacts

        for i in 0..<contacts.count {
            var group = [contacts[i]]
            for j in (i + 1)..<contacts.count {
                let candidates = RelationshipService.shared.detectDuplicates(
                    for: contacts[j], in: [contacts[i]]
                )
                if !candidates.isEmpty {
                    group.append(contacts[j])
                }
            }
            if group.count > 1 {
                // 去重：不添加已在其他组中的
                let existingIDs = groups.flatMap { $0.map(\.id) }
                let newGroup = group.filter { !existingIDs.contains($0.id) }
                if newGroup.count > 1 {
                    groups.append(newGroup)
                }
            }
        }

        duplicateGroups = groups
    }

    private func performMerge() {
        guard let keep = selectedToKeep, let discard = selectedToDiscard else { return }
        RelationshipService.shared.mergeContacts(keep: keep, discard: discard, modelContext: modelContext)
        selectedToKeep = nil
        selectedToDiscard = nil
        detectDuplicates()
    }
}

#Preview {
    DuplicateMergeView()
        .modelContainer(for: [Contact.self])
}
