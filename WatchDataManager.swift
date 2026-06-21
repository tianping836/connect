import SwiftData
import Foundation
import OSLog
@MainActor
final class WatchDataManager: ObservableObject {
    static let shared = WatchDataManager()
    let container: ModelContainer
    private let logger = Logger(subsystem: "com.islandlink.watch", category: "DataManager")
    private init() {
        do {
            guard let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.islandlink.shared")?.appendingPathComponent("IslandLink.sqlite") else { fatalError("❌ 无法获取 App Group 容器 URL") }
            let config = ModelConfiguration(url: appGroupURL, allowsSave: true)
            self.container = try ModelContainer(for: Event.self, EventPerson.self, EventCase.self, Case.self, CaseEvent.self, CasePerson.self, CaseDocument.self, Person.self, Tag.self, configurations: config)
            logger.info("✅ WatchDataManager 初始化成功 — store: \(appGroupURL.path())")
        } catch { logger.fault("❌ WatchDataManager 初始化失败: \(error.localizedDescription)"); fatalError("无法初始化 Watch 端数据容器: \(error)") }
    }
    func todayEvents(context: ModelContext? = nil) -> [Event] {
        let ctx = context ?? container.mainContext; let today = Calendar.current.startOfDay(for: Date()); let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        var descriptor = FetchDescriptor<event>(predicate: #Predicate { event in event.date != nil && event.date! >= today && event.date! < tomorrow && event._statusRaw != EventStatus.cancelled.rawValue && event._statusRaw != EventStatus.completed.rawValue }, sortBy: [SortDescriptor(\.date, order: .forward)])
        descriptor.includePendingChanges = true
        do { return try ctx.fetch(descriptor) } catch { logger.error("获取今日事件失败: \(error.localizedDescription)"); return [] }
    }
    func nextCourtHearing(context: ModelContext? = nil) -> Date? {
        let ctx = context ?? container.mainContext; let now = Date(); let thirtyDaysLater = Calendar.current.date(byAdding: .day, value: 30, to: now) ?? now
        var eventDescriptor = FetchDescriptor<event>(predicate: #Predicate { event in event._eventTypeRaw == EventType.hearing.rawValue && event.date != nil && event.date! > now && event.date! < thirtyDaysLater && event._statusRaw != EventStatus.cancelled.rawValue }, sortBy: [SortDescriptor(\.date, order: .forward)])
        eventDescriptor.fetchLimit = 1; eventDescriptor.includePendingChanges = true
        var caseEventDescriptor = FetchDescriptor<caseevent>(predicate: #Predicate { caseEvent in caseEvent._eventTypeRaw == CaseEventType.trial.rawValue && caseEvent.date > now && caseEvent.date < thirtyDaysLater && caseEvent.isCompleted == false }, sortBy: [SortDescriptor(\.date, order: .forward)])
        caseEventDescriptor.fetchLimit = 1; caseEventDescriptor.includePendingChanges = true
        let eventHearing: Date? = (try? ctx.fetch(eventDescriptor))?.first?.date; let caseTrial: Date? = (try? ctx.fetch(caseEventDescriptor))?.first?.date
        switch (eventHearing, caseTrial) { case let (e?, c?): return e < c ? e : c; case let (e?, nil): return e; case let (nil, c?): return c; case (nil, nil): return nil }
    }
}