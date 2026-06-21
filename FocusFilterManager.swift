import SwiftUI
import AppIntents

// MARK: - Focus Filters：专注模式下切换数据视图

struct IslandLinkFocusFilter: FocusFilterAppIntent {
    static var title: LocalizedStringResource = "屿连 · 数据视图"
    static var description: LocalizedStringResource? = """
        在不同专注模式下切换案件和事件的显示范围。\
        工作模式显示全部，个人时间隐藏案件。
        """
    @Parameter(title: "显示模式")
    var showMode: FocusMode
    @AppStorage("focusFilterMode", store: UserDefaults(suiteName: "group.com.islandlink"))
    private var focusFilterModeData: String = FocusMode.all.rawValue
    func perform() async throws -> some IntentResult {
        focusFilterModeData = showMode.rawValue
        return .result()
    }
}

enum FocusMode: String, Codable, CaseIterable, AppEnum {
    case all = "全部"
    case currentCase = "当前案件"
    case personal = "个人时间"
    case courtDay = "出庭日"
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "显示模式"
    static var caseDisplayRepresentations: [FocusMode: DisplayRepresentation] = [
        .all: "全部", .currentCase: "当前案件",
        .personal: "个人时间", .courtDay: "出庭日",
    ]
    var systemImage: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .currentCase: return "doc.text.magnifyingglass"
        case .personal: return "person.fill"
        case .courtDay: return "hammer.fill"
        }
    }
    var description: String {
        switch self {
        case .all: return "显示全部案件和事件"
        case .currentCase: return "只显示当前正在处理的案件"
        case .personal: return "隐藏所有案件，只显示普通事件"
        case .courtDay: return "锁定在「今日开庭」视图"
        }
    }
}

final class FocusFilterObserver: ObservableObject {
    @AppStorage("focusFilterMode", store: UserDefaults(suiteName: "group.com.islandlink"))
    var focusFilterMode: String = FocusMode.all.rawValue
    var currentMode: FocusMode { FocusMode(rawValue: focusFilterMode) ?? .all }
    var hideCases: Bool { currentMode == .personal }
    var showOnlyHearings: Bool { currentMode == .courtDay }
    func filterCases(_ cases: [Case]) -> [Case] {
        switch currentMode {
        case .all: return cases
        case .currentCase: return cases.filter { $0.caseStatus.isActive }
        case .personal: return []
        case .courtDay:
            let today = Calendar.current.startOfDay(for: Date())
            return cases.filter { c in
                c.events.contains { ce in
                    ce.eventType == .trial && Calendar.current.isDate(ce.date, inSameDayAs: today)
                }
            }
        }
    }
    func filterEvents(_ events: [Event]) -> [Event] {
        switch currentMode {
        case .all, .currentCase: return events
        case .personal: return events.filter { $0.eventType != .hearing && $0.linkedCases.isEmpty }
        case .courtDay:
            let today = Calendar.current.startOfDay(for: Date())
            return events.filter { e in
                guard let date = e.date else { return false }
                return e.eventType == .hearing && Calendar.current.isDate(date, inSameDayAs: today)
            }
        }
    }
}

struct FocusFilterIndicator: View {
    @ObservedObject var filterObserver: FocusFilterObserver
    var body: some View {
        let mode = filterObserver.currentMode
        if mode != .all {
            HStack(spacing: 4) {
                Image(systemName: mode.systemImage).font(.system(size: 11))
                Text(mode.rawValue).font(.cnCaption2)
            }
            .foregroundColor(.tealLink)
            .padding(.horizontal, Spacing.sm).padding(.vertical, 3)
            .background(Color.tealLink.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.tag))
        }
    }
}