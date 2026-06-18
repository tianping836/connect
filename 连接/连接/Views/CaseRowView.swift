import SwiftUI
import SwiftData

/// 案件列表行——案由 / 案号 / 机构 / 阶段 / 参与人数 / 下一步关键日期
struct CaseRowView: View {
    let caseRecord: CaseRecord
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HStack(spacing: 12) {
            // 类型图标
            VStack {
                Image(systemName: caseTypeIcon)
                    .font(.title3)
                    .foregroundStyle(caseTypeColor)
                    .frame(width: 36, height: 36)
                    .background(caseTypeColor.opacity(0.1))
                    .clipShape(.rect(cornerRadius: 8))
            }

            // 信息区
            VStack(alignment: .leading, spacing: 4) {
                Text(caseRecord.caseName)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    if let courtNum = caseRecord.courtCaseNumber {
                        Text(courtNum)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if let internalNum = caseRecord.internalCaseNumber {
                        Text(internalNum)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let org = caseRecord.acceptedOrganization {
                        Text("·")
                        Text(org.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                HStack(spacing: 8) {
                    // 参与人数
                    if let count = caseRecord.participants?.count, count > 0 {
                        Label("\(count)", systemImage: "person.2")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }

                    // 关键日期
                    if let nextEvent = nextUpcomingEvent {
                        Label(nextEvent.title, systemImage: "calendar.badge.clock")
                            .font(.caption2)
                            .foregroundStyle(nextEvent.isOverdue ? .red : .orange)
                    }

                    // 标的额
                    if let amount = caseRecord.claimAmount {
                        Text(amount.formatted(.currency(code: "CNY").precision(.fractionLength(0))))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // 阶段标签
            CaseStageBadge(stage: caseRecord.caseStage)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(caseRecord.caseName), \(caseRecord.caseStage.rawValue), \(caseRecord.participants?.count ?? 0) 人参与")
        .contextMenu {
            Button {
                NotificationCenter.default.post(name: .editCaseRequested, object: caseRecord)
            } label: {
                Label("编辑", systemImage: "pencil")
            }

            Button {
                NotificationCenter.default.post(name: .newItemRequested, object: AppTab.cases)
            } label: {
                Label("新建案件", systemImage: "doc.badge.plus")
            }

            Divider()

            Button(role: .destructive) {
                deleteCase()
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
    }

    private func deleteCase() {
        caseRecord.keyEvents?.forEach {
            NotificationService.shared.cancelAll(for: $0)
            modelContext.delete($0)
        }
        caseRecord.participants?.forEach { modelContext.delete($0) }
        caseRecord.acceptedOrganization?.acceptedCases?.removeAll { $0.id == caseRecord.id }
        modelContext.delete(caseRecord)
        try? modelContext.save()
    }

    private var caseTypeIcon: String {
        switch caseRecord.caseType {
        case .criminal:       "gavel"
        case .civil:          "doc.text"
        case .administrative: "building.2"
        case .arbitration:    "hand.raised"
        case .nonLitigation:  "checkmark.seal"
        }
    }

    private var caseTypeColor: Color {
        switch caseRecord.caseType {
        case .criminal:       .red
        case .civil:          .blue
        case .administrative: .orange
        case .arbitration:    .purple
        case .nonLitigation:  .green
        }
    }

    /// 最近即将到来的关键日期
    private var nextUpcomingEvent: (title: String, isOverdue: Bool)? {
        guard let events = caseRecord.keyEvents, !events.isEmpty else { return nil }
        let now = Date()
        let future = events.filter { $0.date > now }.sorted(by: { $0.date < $1.date })
        if let next = future.first {
            return (next.title, false)
        }
        if let last = events.sorted(by: { $0.date > $1.date }).first {
            return (last.title, true)
        }
        return nil
    }
}
