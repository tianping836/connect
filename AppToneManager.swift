import SwiftUI

enum AppToneManager {
    static func caseClosed(caseName: String, tone: AppTone) -> String {
        switch tone {
        case .professional: return "案件已结案"
        case .warm: return "结案了。\(caseName)，辛苦了。"
        }
    }
    static func deleteCaseTitle(caseName: String, tone: AppTone) -> String {
        switch tone {
        case .professional: return "确认删除案件？"
        case .warm: return "确定删除「\(caseName)」？"
        }
    }
    static func deleteCaseMessage(caseName: String, tone: AppTone) -> String {
        switch tone {
        case .professional: return "删除后无法恢复。"
        case .warm: return "这个案件和所有关联记录将一起删除。确定吗？"
        }
    }
    static func starredPerson(name: String, tone: AppTone) -> String {
        switch tone {
        case .professional: return "已设为重要"
        case .warm: return "记住了。\(name)很重要。"
        }
    }
    static func unstarredPerson(name: String, tone: AppTone) -> String {
        switch tone {
        case .professional: return "已取消星标"
        case .warm: return "好的，\(name)不再星标了。"
        }
    }
    static func deletePersonTitle(name: String, tone: AppTone) -> String {
        switch tone {
        case .professional: return "确认删除联系人？"
        case .warm: return "\(name)将从你的网络里移除。确定？"
        }
    }
    static func archivedPerson(name: String, tone: AppTone) -> String {
        switch tone {
        case .professional: return "已归档"
        case .warm: return "\(name)已归档。随时可以找回来。"
        }
    }
    static func addParticipantPrompt(tone: AppTone) -> String {
        switch tone {
        case .professional: return "添加参与人"
        case .warm: return "这个案件还涉及谁？"
        }
    }
    static func hearingReminder(courtName: String, time: String, tone: AppTone) -> String {
        switch tone {
        case .professional: return "\(time) 开庭 · \(courtName)"
        case .warm: return "\(time)有个庭，在\(courtName)。早点休息。"
        }
    }
    static func eventCompleted(title: String, tone: AppTone) -> String {
        switch tone {
        case .professional: return "已标记完成"
        case .warm: return "「\(title)」完成了。"
        }
    }
    static func eventCreated(title: String, tone: AppTone) -> String {
        switch tone {
        case .professional: return "事件已创建"
        case .warm: return "「\(title)」已加入你的日程。"
        }
    }
    static func emptyPeople(tone: AppTone) -> String {
        switch tone {
        case .professional: return "暂无联系人"
        case .warm: return "还没有联系人。加第一位？"
        }
    }
    static func emptyMatters(tone: AppTone) -> String {
        switch tone {
        case .professional: return "暂无事件"
        case .warm: return "这里会显示你关心的人和事"
        }
    }
    static func emptyCases(tone: AppTone) -> String {
        switch tone {
        case .professional: return "暂无案件"
        case .warm: return "添加你的第一个案件，开始管理人脉关联"
        }
    }
    static func monthlyStats(peopleCount: Int, eventCount: Int, tone: AppTone) -> String {
        switch tone {
        case .professional: return "本月 \(eventCount) 事件"
        case .warm: return "本月和 \(peopleCount) 个人有 \(eventCount) 次互动"
        }
    }
    static func upcomingHearing(date: String, judgeName: String?, courtName: String, tone: AppTone) -> String {
        switch tone {
        case .professional: return "\(date) 开庭 · \(courtName)"
        case .warm:
            if let judge = judgeName { return "\(date) 和\(judge)在\(courtName)" }
            else { return "\(date) 在\(courtName)有个庭" }
        }
    }
    static func confirmDelete(tone: AppTone) -> String {
        switch tone {
        case .professional: return "确认删除？"
        case .warm: return "确定要删除吗？"
        }
    }
    static func saved(tone: AppTone) -> String {
        switch tone {
        case .professional: return "已保存"
        case .warm: return "保存好了。"
        }
    }
    static func newItem(tone: AppTone) -> String {
        switch tone {
        case .professional: return "新建"
        case .warm: return "记一笔"
        }
    }
}

struct AppTonePicker: View {
    @AppStorage("appTone") private var appTone: String = AppTone.professional.rawValue
    private var currentTone: AppTone { AppTone(rawValue: appTone) ?? .professional }
    var body: some View {
        VStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                ForEach(AppTone.allCases) { tone in
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) { appTone = tone.rawValue }
                    } label: {
                        VStack(spacing: Spacing.sm) {
                            Image(systemName: tone.systemImage).font(.system(size: 20))
                                .foregroundColor(currentTone == tone ? .tealLink : .textTertiary)
                            Text(tone.rawValue).font(.cnSubhead)
                                .fontWeight(currentTone == tone ? .semibold : .regular)
                                .foregroundColor(currentTone == tone ? .tealLink : .textSecondary)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, Spacing.md)
                        .background(RoundedRectangle(cornerRadius: CornerRadius.card)
                            .fill(currentTone == tone ? Color.tealLink.opacity(0.08) : Color.surfaceCard))
                        .overlay(RoundedRectangle(cornerRadius: CornerRadius.card)
                            .stroke(currentTone == tone ? Color.tealLink.opacity(0.3) : Color.clear, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            Text(currentTone == .professional ? "「案件已结案」「已设为重要」「确认删除？」" : "「结案了。辛苦了。」「记住了，ta 很重要。」「确定要删除吗？」")
                .font(.cnSubhead).foregroundColor(.textTertiary).multilineTextAlignment(.center).padding(.top, Spacing.sm)
        }
    }
}