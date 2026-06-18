import SwiftUI
import SwiftData

/// 创建/编辑两个人之间的关系
struct RelationshipEditView: View {
    var preselectedSource: Contact? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Contact.name) private var allContacts: [Contact]

    @State private var selectedSource: Contact?
    @State private var selectedTarget: Contact?
    @State private var relationType: RelationType = .other
    @State private var note = ""

    private var availableSources: [Contact] {
        allContacts.filter { $0.id != selectedTarget?.id }
    }
    private var availableTargets: [Contact] {
        allContacts.filter { $0.id != selectedSource?.id }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("甲方") {
                    Picker("选择联系人", selection: $selectedSource) {
                        Text("请选择").tag(nil as Contact?)
                        ForEach(availableSources) { c in
                            Text(c.name).tag(c as Contact?)
                        }
                    }
                }

                Section("关系") {
                    Picker("关系类型", selection: $relationType) {
                        ForEach(RelationType.allCases) { t in
                            HStack {
                                Image(systemName: t.icon)
                                Text(t.rawValue)
                            }.tag(t)
                        }
                    }
                    TextField("备注（选填）", text: $note)
                }

                Section("乙方") {
                    Picker("选择联系人", selection: $selectedTarget) {
                        Text("请选择").tag(nil as Contact?)
                        ForEach(availableTargets) { c in
                            Text(c.name).tag(c as Contact?)
                        }
                    }
                }

                if selectedSource != nil, selectedTarget != nil, selectedSource?.id != selectedTarget?.id {
                    Section {
                        Button {
                            save()
                        } label: {
                            Label("确认添加关系", systemImage: "link")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("添加关系")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .onAppear {
                selectedSource = preselectedSource
            }
        }
        #if os(iOS)
        .presentationDetents([.medium, .large])
        #endif
    }

    private func save() {
        guard let src = selectedSource, let tgt = selectedTarget, src.id != tgt.id else { return }

        // 检查是否已有关系
        let allRels = (try? modelContext.fetch(FetchDescriptor<ContactRelation>())) ?? []
        let exists = allRels.contains {
            ($0.source?.id == src.id && $0.target?.id == tgt.id) ||
            ($0.source?.id == tgt.id && $0.target?.id == src.id)
        }
        if exists {
            dismiss()
            return
        }

        let relation = ContactRelation(
            source: src,
            target: tgt,
            type: relationType,
            note: note.isEmpty ? nil : note
        )
        modelContext.insert(relation)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    RelationshipEditView()
        .modelContainer(for: [Contact.self, ContactRelation.self])
}
