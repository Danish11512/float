import BackgroundTasks
import Foundation

enum BackgroundFetchScheduler {
    static let taskIdentifier = "com.pastry.floats.sync"

    static func register() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: taskIdentifier,
            using: nil
        ) { @Sendable task in
            handleSyncTask(task)
        }
    }

    static func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    private static func handleSyncTask(_ task: BGTask) {
        schedule()

        // TODO: Wire up SyncEngine.sync() with proper actor isolation
        // For now, mark task complete immediately
        task.setTaskCompleted(success: true)
    }
}
