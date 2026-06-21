import EventKit
import SwiftUI

/// 系统日历读取管理器
/// 从系统日历中拉取事件，与 App 内部 Event/CaseEvent 融合展示
@MainActor
final class CalendarReaderManager: ObservableObject {
    static let shared = CalendarReaderManager()

    private let eventStore = EKEventStore()

    @Published var systemEvents: [EKEvent] = []
    @Published var isAuthorized: Bool = false
    @Published var selectedCalendars: Set<string> = []
    @Published var availableCalendars: [EKCalendar] = []

    // MARK: - 权限

    func requestAccess() async -> Bool {
        let granted: Bool
        if #available(iOS 17.0, *) {
            granted = await withCheckedContinuation { cont in
                eventStore.requestFullAccessToEvents { g, _ in cont.resume(returning: g) }
            }
        } else {
            granted = await withCheckedContinuation { cont in
                eventStore.requestAccess(to: .event) { g, _ in cont.resume(returning: g) }
            }
        }
        isAuthorized = granted
        if granted {
            availableCalendars = eventStore.calendars(for: .event)
            selectedCalendars = Set(availableCalendars.map(\.calendarIdentifier))
        }
        return granted
    }

    // MARK: - 读取

    func fetchEvents(from start: Date, to end: Date) {
        guard isAuthorized else { return }

        let calendars = availableCalendars.filter {
            selectedCalendars.contains($0.calendarIdentifier)
        }

        let predicate = eventStore.predicateForEvents(
            withStart: start, end: end, calendars: calendars
        )
        systemEvents = eventStore.events(matching: predicate)
            .filter { event in
                !(event.notes?.contains("[通过「屿连」App 创建]") ?? false)
            }
    }

    // MARK: - 日历管理

    func toggleCalendar(_ calendar: EKCalendar) {
        if selectedCalendars.contains(calendar.calendarIdentifier) {
            selectedCalendars.remove(calendar.calendarIdentifier)
        } else {
            selectedCalendars.insert(calendar.calendarIdentifier)
        }
    }

    func calendarInfo(for identifier: String) -> (name: String, color: Color)? {
        guard let cal = availableCalendars.first(where: { $0.calendarIdentifier == identifier }) else {
            return nil
        }
        return (cal.title, Color(cgColor: cal.cgColor))
    }
}

// MARK: - 融合展示数据结构

struct UnifiedCalendarEntry: Identifiable {
    let id: String
    let date: Date
    let title: String
    let source: Source
    let color: Color
    let icon: String

    enum Source {
        case systemCalendar(EKEvent)
        case appEvent(Event)
        case caseEvent(CaseEvent)
    }

    var sourceLabel: String {
        switch source {
        case .systemCalendar: return "系统日历"
        case .appEvent: return "屿连"
        case .caseEvent: return "屿连"
        }
    }

    var isSystemCalendar: Bool {
        if case .systemCalendar = source { return true }
        return false
    }
}

// MARK: - 日历源筛选

enum CalendarSourceFilter: String, CaseIterable {
    case all = "全部"
    case islandLink = "屿连"
    case system = "系统日历"
}
</string>