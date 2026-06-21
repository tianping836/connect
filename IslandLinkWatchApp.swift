import SwiftUI
import SwiftData
@main
struct IslandLinkWatchApp: App {
    @WKApplicationDelegateAdaptor(WatchAppDelegate.self) var delegate
    @StateObject private var dataManager = WatchDataManager.shared
    var body: some Scene { WindowGroup { WatchContentView().modelContainer(dataManager.container).environmentObject(dataManager) } }
}
final class WatchAppDelegate: NSObject, WKApplicationDelegate {
    func applicationDidFinishLaunching() { _ = WatchDataManager.shared }
    func handle(_ backgroundTasks: Set<wkrefreshbackgroundtask>) {
        for task in backgroundTasks { switch task {
            case let complicationTask as WKWatchConnectivityRefreshBackgroundTask: ComplicationController.shared.reloadActiveComplications(); complicationTask.setTaskCompletedWithSnapshot(false)
            case let refreshTask as WKApplicationRefreshBackgroundTask: refreshTask.setTaskCompletedWithSnapshot(false)
            default: task.setTaskCompletedWithSnapshot(false)
        }}
    }
}