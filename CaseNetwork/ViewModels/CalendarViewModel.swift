import Foundation
import SwiftUI
import SwiftData

/// 日历数据逻辑：月视图网格 / 周视图 / 事件聚合 / 日期着色
@MainActor
@Observable
final class CalendarViewModel {

    // MARK: - 状态

    /// 当前显示的月份
    var currentMonth: Date

    /// 视图模式
    var viewMode: ViewMode = .month

    /// 选中的日期（点击日期 → 弹出当日事件）
    var selectedDate: Date?

    /// 所有案件的 KeyEvent
    private var allEvents: [KeyEvent] = []

    // MARK: - 初始化

    init(currentMonth: Date = Date()) {
        self.currentMonth = currentMonth.startOfMonth
    }

    // MARK: - 月视图数据

    /// 月视图网格：6行 × 7列，包含前后月份的填充日期
    var monthGrid: [[Date?]] {
        let calendar = Calendar.current
        let start = currentMonth.startOfMonth
        let daysInMonth = calendar.range(of: .day, in: .month, for: start)!.count

        // 当月第一天是周几（1=周日，调整为 0=周一）
        var weekday = calendar.component(.weekday, from: start) - 1
        if weekday == 0 { weekday = 7 } // Sunday → 7
        weekday -= 1 // Now 0=Monday

        let totalCells = weekday + daysInMonth
        let rows = Int(ceil(Double(totalCells) / 7.0))

        var grid: [[Date?]] = []
        var day = 0

        for row in 0..<rows {
            var week: [Date?] = []
            for col in 0..<7 {
                let index = row * 7 + col
                if index < weekday || day >= daysInMonth {
                    week.append(nil)
                } else {
                    week.append(calendar.date(byAdding: .day, value: day, to: start))
                    day += 1
                }
            }
            grid.append(week)
        }
        return grid
    }

    /// 周视图：选中日期所在周
    var weekDays: [Date] {
        let calendar = Calendar.current
        let base = selectedDate ?? Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: base))!
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }

    // MARK: - 事件查询

    /// 某天的事件列表
    func events(for date: Date) -> [KeyEvent] {
        let calendar = Calendar.current
        return allEvents.filter {
            calendar.isDate($0.date, inSameDayAs: date)
        }.sorted { $0.date < $1.date }
    }

    /// 某天是否有事件
    func hasEvents(on date: Date) -> Bool {
        !events(for: date).isEmpty
    }

    /// 某天的事件类型（用于着色标记，取第一个类型）
    func eventTypes(for date: Date) -> [KeyEventType] {
        let dayEvents = events(for: date)
        return Array(Set(dayEvents.map(\.eventType))).sorted(by: { $0.rawValue < $1.rawValue })
    }

    /// 颜色点（日历格下方最多显示3个颜色点）
    func dotColors(for date: Date) -> [Color] {
        eventTypes(for: date).prefix(3).map { Color(hex: eventColor($0)) }
    }

    // MARK: - 导航

    func goToPreviousMonth() {
        currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth)!
    }

    func goToNextMonth() {
        currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth)!
    }

    func goToToday() {
        currentMonth = Date().startOfMonth
    }

    var monthTitle: String {
        currentMonth.formatted(.dateTime.year().month(.wide).locale(Locale(identifier: "zh_CN")))
    }

    // MARK: - 数据加载

    func loadEvents(_ events: [KeyEvent]) {
        allEvents = events
    }

    // MARK: - 事件着色

    static func colorHex(for type: KeyEventType) -> String {
        switch type {
        case .filing:              "#1976D2"
        case .courtHearing:        "#D32F2F"
        case .evidenceDeadline:    "#F57C00"
        case .mediation:           "#7B1FA2"
        case .sentencing:          "#D32F2F"
        case .appeal:              "#F57C00"
        case .closing:             "#388E3C"
        case .clientMeeting:       "#00796B"
        case .evidenceSubmission:  "#455A64"
        case .ruling:              "#512DA8"
        case .other:               "#616161"
        }
    }

    private func eventColor(_ type: KeyEventType) -> String {
        Self.colorHex(for: type)
    }

    // MARK: - 统计

    /// 当月事件数
    var eventsThisMonth: Int {
        let calendar = Calendar.current
        return allEvents.filter {
            calendar.isDate($0.date, equalTo: currentMonth, toGranularity: .month)
        }.count
    }

    /// 本月开庭数
    var hearingsThisMonth: Int {
        let calendar = Calendar.current
        return allEvents.filter {
            calendar.isDate($0.date, equalTo: currentMonth, toGranularity: .month)
            && $0.eventType == .courtHearing
        }.count
    }

    enum ViewMode: String, CaseIterable {
        case month = "Month"
        case week = "Week"
    }
}

// MARK: - Date 工具

extension Date {
    var startOfMonth: Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: self))!
    }

    var startOfWeek: Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self))!
    }
}
