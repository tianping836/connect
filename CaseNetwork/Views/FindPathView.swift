import SwiftUI
import SwiftData

/// 查找两个人之间的关系路径
struct FindPathView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Contact.name) private var allContacts: [Contact]
    @Query var allRelations: [ContactRelation]

    @State private var contactA: Contact?
    @State private var contactB: Contact?
    @State private var pathResult: [PathNode]?
    @State private var isSearching = false

    var body: some View {
        NavigationStack {
            Form {
                Section("查找路径") {
                    Picker("联系人 A", selection: $contactA) {
                        Text("请选择").tag(nil as Contact?)
                        ForEach(allContacts) { c in
                            Text(c.name).tag(c as Contact?)
                        }
                    }
                    Picker("联系人 B", selection: $contactB) {
                        Text("请选择").tag(nil as Contact?)
                        ForEach(allContacts) { c in
                            Text(c.name).tag(c as Contact?)
                        }
                    }

                    Button {
                        findPath()
                    } label: {
                        Label("查找连接路径", systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(contactA == nil || contactB == nil || contactA?.id == contactB?.id)
                }

                if let path = pathResult {
                    Section {
                        if path.count == 1 {
                            HStack {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                                Text("同一个人")
                            }
                        } else {
                            VStack(spacing: 0) {
                                ForEach(Array(path.enumerated()), id: \.element.id) { idx, node in
                                    HStack(spacing: 0) {
                                        // 节点
                                        VStack(spacing: 2) {
                                            AvatarView(name: node.contact.name, importance: node.contact.importance)
                                                .frame(width: 36, height: 36)
                                            Text(node.contact.name)
                                                .font(.caption.weight(.medium))
                                                .lineLimit(1)
                                            if let role = node.contact.roleTags.first {
                                                Text(role.rawValue)
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        .frame(width: 72)

                                        if idx < path.count - 1 {
                                            // 连线
                                            VStack(spacing: 2) {
                                                Divider()
                                                if let rel = path[idx + 1].relation {
                                                    HStack(spacing: 2) {
                                                        Image(systemName: rel.type.icon)
                                                            .font(.caption2)
                                                        Text(rel.type.rawValue)
                                                            .font(.caption2)
                                                    }
                                                    .padding(.horizontal, 4)
                                                    .padding(.vertical, 2)
                                                    .background(.secondary.opacity(0.1))
                                                    .clipShape(.capsule)
                                                }
                                                Divider()
                                            }
                                            .frame(width: 60)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 8)

                            // 总结
                            HStack {
                                Image(systemName: "lightbulb.fill").foregroundStyle(.yellow)
                                Text(pathSummary)
                                    .font(.subheadline)
                            }
                        }
                    } header: {
                        Text("连接路径")
                    } footer: {
                        if !path.isEmpty {
                            Text("共 \(path.count - 1) 度关系")
                        }
                    }
                } else if isSearching {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView("搜索中...")
                            Spacer()
                        }
                    }
                } else if contactA != nil, contactB != nil {
                    Section {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                            Text("点上方按钮开始查找")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("关系路径")
        }
    }

    private var pathSummary: String {
        guard let path = pathResult, path.count >= 2 else { return "" }
        let nameA = path.first!.contact.name
        let nameB = path.last!.contact.name
        let depth = path.count - 1

        if depth == 1 {
            let rel = path[1].relation
            return "「\(nameA)」和「\(nameB)」直接相识" + (rel.map { "（\($0.type.rawValue)）" } ?? "")
        } else {
            let via = path[1..<path.count - 1].map { "「\($0.contact.name)」" }.joined(separator: "、")
            return "「\(nameA)」通过 \(via) 连接到「\(nameB)」（\(depth) 度）"
        }
    }

    private func findPath() {
        guard let a = contactA, let b = contactB else { return }
        isSearching = true
        pathResult = nil

        Task {
            let path = RelationshipService.shared.findShortestPath(
                from: a, to: b, allRelations: allRelations
            )
            await MainActor.run {
                pathResult = path
                isSearching = false
            }
        }
    }
}

#Preview {
    FindPathView()
        .modelContainer(for: [Contact.self, ContactRelation.self])
}
