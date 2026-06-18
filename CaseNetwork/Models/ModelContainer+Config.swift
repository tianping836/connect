import Foundation
import SwiftData

extension ModelContainer {

    /// 应用级 ModelContainer 单例
    /// - Debug: 内存存储（Preview / 单元测试）
    /// - Release: 本地存储 + 可选 CloudKit 同步
    ///
    /// CloudKit 同步由用户通过 Settings → iCloud 同步开关控制。
    /// 切换后需重启 App 生效。
    static var appContainer: ModelContainer {
        let schema = Schema([
            Contact.self,
            Interaction.self,
            ContactRelation.self,
            Organization.self,
            CaseRecord.self,
            CaseParticipant.self,
            KeyEvent.self,
        ])

        #if DEBUG
        let isPreviewOrTest = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
            || ProcessInfo.processInfo.environment["IS_UNIT_TEST"] == "1"
        let config = ModelConfiguration(
            isStoredInMemoryOnly: isPreviewOrTest
        )
        #else
        let cloudSyncEnabled = UserDefaults.standard.bool(forKey: "cloudkit_sync_enabled")
        let config = ModelConfiguration(
            groupContainer: .identifier("group.com.casenetwork.data"),
            cloudKitDatabase: cloudSyncEnabled ? .automatic : .none
        )
        #endif

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error.localizedDescription)")
        }
    }
}

// MARK: - CloudKit 同步历史追踪

import CoreData

/// 监听 NSPersistentCloudKitContainer 同步事件，用于 UI 状态指示
/// 通过 NotificationCenter 转发给 UI 层
@MainActor
@Observable
final class CloudSyncObserver {
    static let shared = CloudSyncObserver()

    /// 同步状态（供 UI 绑定）
    enum Status: Equatable {
        case notConfigured
        case idle
        case importing
        case exporting
        case failed(String)

        var systemImage: String {
            switch self {
            case .notConfigured: "icloud.slash"
            case .idle:         "icloud.fill"
            case .importing:    "icloud.and.arrow.down"
            case .exporting:    "icloud.and.arrow.up"
            case .failed:       "icloud.slash"
            }
        }

        var displayName: String {
            switch self {
            case .notConfigured: "未启用"
            case .idle:         "已同步"
            case .importing:    "同步中…"
            case .exporting:    "上传中…"
            case .failed(let m): "同步失败: \(m)"
            }
        }
    }

    var status: Status = .notConfigured

    private var started = false

    func startIfNeeded() {
        guard !started else { return }
        started = true
        guard UserDefaults.standard.bool(forKey: "cloudkit_sync_enabled") else {
            status = .notConfigured
            return
        }
        status = .idle

        // 监听 CoreData 远程变更通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRemoteChange(_:)),
            name: .NSPersistentStoreRemoteChange,
            object: nil
        )
    }

    @objc private func handleRemoteChange(_ notification: Notification) {
        // NSPersistentHistoryChangeKey 包含变更详情
        status = .importing
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            if status == .importing { status = .idle }
        }
    }
}
