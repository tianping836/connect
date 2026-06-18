import Foundation
import EventKit
import SwiftData

/// 苹果系统日历同步服务
@MainActor
final class CalendarSyncService {
    static let shared = CalendarSyncService()

    private let eventStore = EKEventStore()
    private var isWatching = false

    private init() {}

    // MARK: - 实时监听

    /// 开始监听系统日历变更（新增/修改/删除事件时自动同步）
    func startWatching() {
        guard !isWatching else { return }
        isWatching = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(calendarChanged),
            name: .EKEventStoreChanged,
            object: eventStore
        )
    }

    /// 日历变更回调（限流：5 秒内多次变更只触发一次）
    private var pendingSync: Task<Void, Never>?
    @objc private func calendarChanged(_ notification: Notification) {
        pendingSync?.cancel()
        pendingSync = Task { @MainActor in
            try? await Task.sleep(for: .seconds(5))
            NotificationCenter.default.post(name: .calendarSyncRequested, object: nil)
        }
    }

    // MARK: - 权限

    var authorizationStatus: EKAuthorizationStatus {
        EKEventStore.authorizationStatus(for: .event)
    }

    func requestAccess() async -> Bool {
        do {
            return try await eventStore.requestFullAccessToEvents()
        } catch {
            return false
        }
    }

    // MARK: - 获取日历事件

    /// 获取指定日期范围内的系统日历事件
    func fetchEvents(from start: Date, to end: Date) -> [EKEvent] {
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
        return eventStore.events(matching: predicate)
    }

    /// 获取当月全部事件
    func fetchCurrentMonthEvents() -> [EKEvent] {
        let now = Date()
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        return fetchEvents(from: startOfMonth, to: endOfMonth)
    }

    // MARK: - 导入到 App

    /// 将系统日历事件导入为 KeyEvent，关联到对应案件
    /// - Returns: 导入的事件数量
    func importEvents(
        from start: Date,
        to end: Date,
        modelContext: ModelContext
    ) async throws -> Int {
        let status = authorizationStatus
        guard status == .fullAccess else { return 0 }

        let ekEvents = fetchEvents(from: start, to: end)
        var importedCount = 0

        // 获取已有事件（用于去重：同标题+同日期跳过）
        let allKeyEvents = (try? modelContext.fetch(FetchDescriptor<KeyEvent>())) ?? []
        let allCases = (try? modelContext.fetch(FetchDescriptor<CaseRecord>())) ?? []

        for ekEvent in ekEvents {
            // 去重：同标题 + 同日期
            let exists = allKeyEvents.contains {
                $0.title == ekEvent.title &&
                Calendar.current.isDate($0.date, inSameDayAs: ekEvent.startDate)
            }
            guard !exists else { continue }

            // 尝试匹配关联案件（标题中包含案件名）
            var matchedCase: CaseRecord?
            for c in allCases {
                if ekEvent.title.contains(c.caseName) || c.caseName.contains(ekEvent.title) {
                    matchedCase = c
                    break
                }
            }

            // 映射事件类型
            let eventType = inferEventType(from: ekEvent)

            let keyEvent = KeyEvent(
                caseRecord: matchedCase,
                eventType: eventType,
                date: ekEvent.startDate,
                title: ekEvent.title,
                detail: ekEvent.notes,
                reminderEnabled: ekEvent.hasAlarms,
                reminderDays: ekEvent.hasAlarms ? [1] : []
            )
            modelContext.insert(keyEvent)
            matchedCase?.keyEvents?.append(keyEvent)
            importedCount += 1
        }

        if importedCount > 0 {
            try modelContext.save()
        }
        return importedCount
    }

    /// 根据日历事件信息推测事件类型
    private func inferEventType(from ekEvent: EKEvent) -> KeyEventType {
        let title = ekEvent.title.lowercased()

        if title.contains("开庭") || title.contains("庭审") { return .courtHearing }
        if title.contains("立案") { return .filing }
        if title.contains("举证") || title.contains("证据") { return .evidenceDeadline }
        if title.contains("调解") { return .mediation }
        if title.contains("宣判") || title.contains("判决") { return .sentencing }
        if title.contains("上诉") { return .appeal }
        if title.contains("结案") { return .closing }
        if title.contains("会见") || title.contains("当事人") { return .clientMeeting }
        if title.contains("提交") && title.contains("证据") { return .evidenceSubmission }
        if title.contains("裁定") { return .ruling }

        return .other
    }
}
