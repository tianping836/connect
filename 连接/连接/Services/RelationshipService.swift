import Foundation
import SwiftData

// MARK: - 路径节点

/// BFS 路径中的一个节点
final class PathNode: Identifiable {
    let id: UUID
    let contact: Contact
    let relation: ContactRelation?
    let previous: PathNode?
    var depth: Int

    init(id: UUID, contact: Contact, relation: ContactRelation?, previous: PathNode?, depth: Int) {
        self.id = id; self.contact = contact; self.relation = relation
        self.previous = previous; self.depth = depth
    }

    /// 回溯完整路径
    func fullPath() -> [PathNode] {
        var result: [PathNode] = [self]
        var current = self
        while let prev = current.previous {
            result.insert(prev, at: 0)
            current = prev
        }
        return result
    }
}

// MARK: - 去重候选

struct DuplicateCandidate: Identifiable {
    let id = UUID()
    let existingContact: Contact
    let newName: String
    let matchReason: String       // "同名" / "同手机" / "拼音相似"
    let confidence: Int           // 1-5
}

// MARK: - 关系网络服务

@MainActor
final class RelationshipService {
    static let shared = RelationshipService()
    private init() {}

    // MARK: 路径查找 (BFS)

    /// 查找两个人之间最短的关系路径
    /// - Returns: 路径节点数组（从 start 到 end），找不到返回 nil
    func findShortestPath(
        from start: Contact,
        to end: Contact,
        allRelations rels: [ContactRelation]
    ) -> [PathNode]? {
        guard start.id != end.id else { return [PathNode(id: start.id, contact: start, relation: nil, previous: nil, depth: 0)] }

        // 构建邻接表
        var adj: [UUID: [(Contact, ContactRelation)]] = [:]
        for rel in rels {
            guard let src = rel.source, let tgt = rel.target else { continue }
            adj[src.id, default: []].append((tgt, rel))
            adj[tgt.id, default: []].append((src, rel))  // 反向也可达
        }

        // BFS
        var visited: Set<UUID> = [start.id]
        var queue: [PathNode] = [PathNode(id: start.id, contact: start, relation: nil, previous: nil, depth: 0)]

        while !queue.isEmpty {
            let current = queue.removeFirst()
            let neighbors = adj[current.id] ?? []

            for (neighbor, relation) in neighbors {
                guard !visited.contains(neighbor.id) else { continue }
                let nextNode = PathNode(id: neighbor.id, contact: neighbor, relation: relation, previous: current, depth: current.depth + 1)

                if neighbor.id == end.id {
                    return nextNode.fullPath()
                }

                visited.insert(neighbor.id)
                queue.append(nextNode)
            }
        }

        return nil
    }

    // MARK: 关系网络

    /// 获取某个人周围 depth 度的关系网
    func findNetwork(
        around center: Contact,
        depth: Int,
        allRelations rels: [ContactRelation]
    ) -> (nodes: Set<UUID>, edges: [(ContactRelation, UUID, UUID)]) {
        var nodes: Set<UUID> = [center.id]
        var edges: [(ContactRelation, UUID, UUID)] = []
        var frontier: Set<UUID> = [center.id]

        for _ in 0..<depth {
            var nextFrontier: Set<UUID> = []
            for nodeID in frontier {
                for rel in rels {
                    guard let srcID = rel.source?.id, let tgtID = rel.target?.id else { continue }
                    if srcID == nodeID, !nodes.contains(tgtID) {
                        nodes.insert(tgtID)
                        edges.append((rel, srcID, tgtID))
                        nextFrontier.insert(tgtID)
                    } else if tgtID == nodeID, !nodes.contains(srcID) {
                        nodes.insert(srcID)
                        edges.append((rel, tgtID, srcID))
                        nextFrontier.insert(srcID)
                    }
                }
            }
            frontier = nextFrontier
        }

        return (nodes, edges)
    }

    // MARK: 智能去重

    /// 检测联系人库中可能重复的条目
    func detectDuplicates(for newContact: Contact, in allContacts: [Contact]) -> [DuplicateCandidate] {
        var candidates: [DuplicateCandidate] = []

        for existing in allContacts where existing.id != newContact.id {
            var reasons: [String] = []
            var confidence = 0

            // 1. 完全同名（中文）
            if existing.name == newContact.name {
                reasons.append("同名")
                confidence = max(confidence, 5)
            }

            // 2. 拼音相同但汉字不同（如 王朝阳 / 王朝扬）
            if let existingPY = existing.name.applyingTransform(.toLatin, reverse: false)?
                .lowercased().replacingOccurrences(of: " ", with: ""),
               let newPY = newContact.name.applyingTransform(.toLatin, reverse: false)?
                .lowercased().replacingOccurrences(of: " ", with: ""),
               existingPY == newPY, existing.name != newContact.name {
                reasons.append("拼音相同")
                confidence = max(confidence, 3)
            }

            // 3. 手机号完全匹配
            if let phone = newContact.phone, !phone.isEmpty,
               phone == existing.phone {
                reasons.append("手机号相同")
                confidence = max(confidence, 5)
            }

            // 4. 同机构 + 同名（姓氏相同也算一个线索）
            if let org = newContact.organization, org.id == existing.organization?.id {
                let existingLastName = String(existing.name.prefix(1))
                let newLastName = String(newContact.name.prefix(1))
                if existingLastName == newLastName {
                    reasons.append("同机构同姓")
                    confidence = max(confidence, 2)
                }
            }

            if !reasons.isEmpty {
                candidates.append(DuplicateCandidate(
                    existingContact: existing,
                    newName: newContact.name,
                    matchReason: reasons.joined(separator: "、"),
                    confidence: confidence
                ))
            }
        }

        return candidates.sorted { $0.confidence > $1.confidence }
    }

    // MARK: 合并联系人

    /// 将 source 合并到 target，删除 source
    func mergeContacts(keep target: Contact, discard source: Contact, modelContext: ModelContext) {
        // 1. 迁移 CaseParticipant
        if let participations = source.caseParticipations {
            for p in participations {
                p.contact = target
            }
        }

        // 2. 迁移 ContactRelation
        if let srcRels = source.sourceRelations {
            for r in srcRels { r.source = target }
        }
        if let tgtRels = source.targetRelations {
            for r in tgtRels { r.target = target }
        }

        // 3. 迁移 Interaction
        if let interactions = source.interactions {
            for i in interactions { i.contact = target }
        }

        // 4. 迁移 referrer 链
        if let referrals = source.referrals {
            for r in referrals { r.referrer = target }
        }
        if let referrer = source.referrer {
            // 如果 target 没有介绍人，继承 source 的
            if target.referrer == nil { target.referrer = referrer }
        }

        // 5. 合并软信息（target 没有的就补上）
        if target.phone == nil { target.phone = source.phone }
        if target.wechat == nil { target.wechat = source.wechat }
        if target.email == nil { target.email = source.email }
        if target.organization == nil { target.organization = source.organization }
        if target.notes == nil { target.notes = source.notes }
        if target.birthday == nil { target.birthday = source.birthday }

        // 合并技能标签
        var mergedSkills = Set(target.skillTags)
        source.skillTags.forEach { mergedSkills.insert($0) }
        target.skillTags = Array(mergedSkills)

        // 合并角色标签
        var mergedRoles = Set(target.roleTags)
        source.roleTags.forEach { mergedRoles.insert($0) }
        target.roleTags = Array(mergedRoles)

        // 取较高重要度
        target.importance = max(target.importance, source.importance)

        // 6. 更新时戳
        target.updatedAt = Date()

        // 7. 删除 source
        modelContext.delete(source)
        try? modelContext.save()
    }
}
