import Foundation
import SwiftData

extension ModelContainer {

    /// 应用级 ModelContainer 单例
    /// - `isStoredInMemoryOnly: true` 用于 Preview 和测试
    /// - `isStoredInMemoryOnly: false` 用于生产（本地存储，Phase 6 再接入 CloudKit）
    static var appContainer: ModelContainer {
        let schema = Schema([
            Contact.self,
            Interaction.self,
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
        let config = ModelConfiguration(
            groupContainer: .identifier("group.com.casenetwork.data")
        )
        #endif

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error.localizedDescription)")
        }
    }
}
