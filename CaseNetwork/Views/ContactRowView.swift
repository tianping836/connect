import SwiftUI
import SwiftData

/// 联系人列表行——单行展示：头像首字母 / 姓名 / 角色标签 / 机构 / 关联案件数
struct ContactRowView: View {
    let contact: Contact

    var body: some View {
        HStack(spacing: 12) {
            // 头像
            AvatarView(name: contact.name, importance: contact.importance)

            // 信息区
            VStack(alignment: .leading, spacing: 4) {
                // 姓名 + 重要度
                HStack(spacing: 6) {
                    Text(contact.name)
                        .font(.body.weight(.medium))
                        .lineLimit(1)

                    if contact.importance >= 4 {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }

                // 角色标签 + 机构
                HStack(spacing: 4) {
                    if let mainRole = contact.roleTags.first {
                        RoleBadge(role: mainRole, size: .small)
                    }

                    if let orgName = contact.organization?.name {
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text(orgName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                // 关联案件数 + 最近联系
                HStack(spacing: 8) {
                    if let count = contact.caseParticipations?.count, count > 0 {
                        Label("\(count)案", systemImage: "doc.text")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }

                    if let lastContact = contact.lastContactDate {
                        Label(lastContact.relativeFormatted, systemImage: "clock")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    if contact.hasUpdate {
                        Text("有更新")
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(.orange.opacity(0.15))
                            .foregroundStyle(.orange)
                            .clipShape(.capsule)
                    }
                }
            }

            Spacer()

            // 关系阶段指示器
            RelationshipStageIndicator(stage: contact.relationshipStage)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 子组件

/// 联系人首字母头像
struct AvatarView: View {
    let name: String
    let importance: Int

    private var initial: String {
        String(name.prefix(1))
    }

    private var color: Color {
        switch importance {
        case 5: .red
        case 4: .orange
        case 3: .blue
        default: .gray
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 40, height: 40)

            Text(initial)
                .font(.system(.callout, design: .rounded).weight(.bold))
                .foregroundStyle(color)
        }
    }
}

/// 角色标签胶囊
enum RoleBadgeSize {
    case small, normal
}

struct RoleBadge: View {
    let role: ContactRole
    var size: RoleBadgeSize = .normal

    private var fontSize: Font {
        size == .small ? .caption2 : .caption
    }

    var body: some View {
        Text(role.rawValue)
            .font(fontSize.weight(.medium))
            .padding(.horizontal, size == .small ? 6 : 8)
            .padding(.vertical, size == .small ? 2 : 3)
            .background(Color(hex: role.colorHex).opacity(0.12))
            .foregroundStyle(Color(hex: role.colorHex))
            .clipShape(.capsule)
    }
}

/// 关系阶段点指示器
struct RelationshipStageIndicator: View {
    let stage: RelationshipStage

    private var color: Color {
        switch stage {
        case .newAcquaintance: .gray
        case .familiar:         .blue
        case .trusted:          .green
        case .canRefer:         .orange
        }
    }

    private var label: String {
        switch stage {
        case .newAcquaintance: "新识"
        case .familiar:         "熟悉"
        case .trusted:          "信任"
        case .canRefer:         "可引荐"
        }
    }

    var body: some View {
        VStack(spacing: 2) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - 工具扩展

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted))
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
}

extension Date {
    var relativeFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
