import SwiftUI
import SwiftData

/// 人脉关系网络图——以当前联系人为中心，展示关联网络
struct NetworkGraphView: View {
    let center: Contact
    @Environment(\.modelContext) private var modelContext
    @Query var allRelations: [ContactRelation]

    @State private var nodes: [GraphNode] = []
    @State private var edges: [GraphEdge] = []
    @State private var scale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 0) {
            // 统计
            HStack(spacing: 24) {
                statItem("直接关系", "\(edges.count)", .blue)
                statItem("关联人数", "\(nodes.count - 1)", .green)
                statItem("一度人脉", "\(nodes.filter { abs($0.x) < 150 && abs($0.y) < 150 }.count - 1)", .orange)
            }
            .padding(.vertical, 8)
            .background(.bar)

            // 图面
            GeometryReader { geo in
                ZStack {
                    // 连线
                    ForEach(edges) { edge in
                        Path { path in
                            path.move(to: edge.from.point(in: geo.size))
                            path.addLine(to: edge.to.point(in: geo.size))
                        }
                        .stroke(edge.color.opacity(0.4), lineWidth: max(1, 3 * scale))
                    }

                    // 节点
                    ForEach(nodes) { node in
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(node.isCenter ? Color.blue : Color.secondary.opacity(0.15))
                                    .frame(width: max(40, 56 * scale), height: max(40, 56 * scale))
                                Text(String(node.contact.name.prefix(1)))
                                    .font(.system(size: max(14, 20 * scale), weight: .bold))
                                    .foregroundStyle(node.isCenter ? .white : .primary)
                            }
                            Text(node.contact.name)
                                .font(.system(size: max(8, 11 * scale)))
                                .lineLimit(1)
                                .frame(width: 72)
                        }
                        .position(node.point(in: geo.size))
                    }
                }
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = value.magnitude
                        }
                )
            }
        }
        .navigationTitle("\(center.name) 的关系网络")
        .onAppear {
            #if os(iOS)
            layoutGraph(in: UIScreen.main.bounds.size)
            #else
            layoutGraph(in: CGSize(width: 600, height: 500))
            #endif
        }
    }

    // MARK: 布局算法（简单力导向）

    private func layoutGraph(in size: CGSize) {
        // Center node at origin (positioned relative to center)
        var allNodes: [GraphNode] = [GraphNode(contact: center, x: 0, y: 0, isCenter: true)]
        var allEdges: [GraphEdge] = []
        var placedIDs: Set<UUID> = [center.id]

        // 1st degree: direct relations
        var firstDegree: [GraphNode] = []
        for rel in allRelations {
            guard let src = rel.source, let tgt = rel.target else { continue }
            var related: Contact?
            if src.id == center.id { related = tgt }
            else if tgt.id == center.id { related = src }
            guard let relContact = related, !placedIDs.contains(relContact.id) else { continue }

            placedIDs.insert(relContact.id)
            let node = GraphNode(contact: relContact, x: 0, y: 0, isCenter: false)
            allNodes.append(node)
            firstDegree.append(node)
            allEdges.append(GraphEdge(from: allNodes[0], to: node, type: rel.type))
        }

        // Arrange 1st degree in a circle
        let circleRadius: CGFloat = 120
        for (i, _) in firstDegree.enumerated() {
            let angle = (2 * .pi / CGFloat(firstDegree.count)) * CGFloat(i) - .pi / 2
            firstDegree[i].x = cos(angle) * circleRadius
            firstDegree[i].y = sin(angle) * circleRadius
        }

        // 2nd degree (limited to avoid clutter)
        let max2nd = 12
        var secondCount = 0
        for fNode in firstDegree {
            guard secondCount < max2nd else { break }
            for rel in allRelations {
                guard let src = rel.source, let tgt = rel.target else { continue }
                var related: Contact?
                if src.id == fNode.contact.id { related = tgt }
                else if tgt.id == fNode.contact.id { related = src }
                guard let relContact = related, !placedIDs.contains(relContact.id) else { continue }
                guard relContact.id != center.id else { continue }

                placedIDs.insert(relContact.id)
                let angle: CGFloat = .random(in: 0...(.pi * 2))
                let dist: CGFloat = 180 + .random(in: 0...60)
                let sNode = GraphNode(
                    contact: relContact,
                    x: fNode.x + cos(angle) * dist * 0.8,
                    y: fNode.y + sin(angle) * dist * 0.8,
                    isCenter: false
                )
                allNodes.append(sNode)
                allEdges.append(GraphEdge(from: fNode, to: sNode, type: rel.type))
                secondCount += 1
                if secondCount >= max2nd { break }
            }
        }

        nodes = allNodes
        edges = allEdges
    }

    private func statItem(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.title3.weight(.bold)).foregroundStyle(color)
            Text(label).font(.system(size: 10)).foregroundStyle(.secondary)
        }
    }
}

// MARK: - 图节点

@Observable
final class GraphNode: Identifiable {
    let id = UUID()
    let contact: Contact
    var x: CGFloat
    var y: CGFloat
    let isCenter: Bool

    init(contact: Contact, x: CGFloat, y: CGFloat, isCenter: Bool) {
        self.contact = contact; self.x = x; self.y = y; self.isCenter = isCenter
    }

    func point(in size: CGSize) -> CGPoint {
        CGPoint(x: size.width / 2 + x, y: size.height / 2 + y)
    }
}

// MARK: - 图边

struct GraphEdge: Identifiable {
    let id = UUID()
    let from: GraphNode
    let to: GraphNode
    let type: RelationType

    var color: Color {
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

    var point: CGPoint {
        CGPoint(x: (from.x + to.x) / 2, y: (from.y + to.y) / 2)
    }
}

#Preview {
    NavigationStack {
        NetworkGraphView(center: Contact(name: "测试"))
    }
}
