import Foundation
import UserNotifications

/// 本地推送通知服务——开庭/举证/调解等关键节点的提前提醒
///
/// 通知 ID 规则：`keyevent-{UUID}-{daysBefore}`，每条提醒独立管理
/// 提醒时间：事件日期前 N 天上午 9:00
@MainActor
final class NotificationService {

    static let shared = NotificationService()
    private let center = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - 授权

    /// 请求通知权限（App 首次启动调用）
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            return false
        }
    }

    /// 检查当前通知权限状态
    func currentAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - 调度

    /// 为某个 KeyEvent 调度全部提醒（先清除旧通知，再按 reminderDays 逐个注册）
    func schedule(for event: KeyEvent) {
        guard event.reminderEnabled, !event.reminderDays.isEmpty else {
            cancelAll(for: event)
            return
        }

        // 先清除旧的
        cancelAll(for: event)

        let calendar = Calendar.current

        for daysBefore in event.reminderDays {
            guard let triggerDate = calendar.date(byAdding: .day, value: -daysBefore, to: event.date) else {
                continue
            }

            // 如果提醒日期已过，跳过
            if triggerDate < Date() { continue }

            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute],
                                                     from: triggerDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

            let id = notificationID(for: event, daysBefore: daysBefore)
            let content = buildContent(for: event, daysBefore: daysBefore)

            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            center.add(request) { error in
                if let error = error {
                    print("[NotificationService] Failed to schedule \(id): \(error.localizedDescription)")
                }
            }
        }
    }

    /// 清除某个 KeyEvent 的全部待推送通知
    func cancelAll(for event: KeyEvent) {
        let prefix = "keyevent-\(event.id.uuidString)-"
        // 收集所有可能的 reminderDays 值对应的 ID
        let allPossibleIDs = [1, 3, 7, 14, 30].map { "\(prefix)\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: allPossibleIDs)
        center.removeDeliveredNotifications(withIdentifiers: allPossibleIDs)
    }

    /// 清除指定 KeyEvent 的所有通知（通过 event ID）
    func cancelAll(forEventID eventID: UUID) {
        let prefix = "keyevent-\(eventID.uuidString)-"
        let allPossibleIDs = [1, 3, 7, 14, 30].map { "\(prefix)\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: allPossibleIDs)
        center.removeDeliveredNotifications(withIdentifiers: allPossibleIDs)
    }

    // MARK: - 内部工具

    private func notificationID(for event: KeyEvent, daysBefore: Int) -> String {
        "keyevent-\(event.id.uuidString)-\(daysBefore)"
    }

    private func buildContent(for event: KeyEvent, daysBefore: Int) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "\(event.eventType.rawValue)：\(event.title)"

        var parts: [String] = ["\(daysBefore) 天后到期"]
        if let caseName = event.caseRecord?.caseName {
            parts.append("关联案件：\(caseName)")
        }
        if let detail = event.detail, !detail.isEmpty {
            parts.append(detail)
        }
        content.body = parts.joined(separator: "\n")
        content.sound = .default
        content.badge = NSNumber(value: 1)
        content.categoryIdentifier = "KEY_EVENT"
        return content
    }
}
