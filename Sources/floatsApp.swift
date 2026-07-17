import SwiftUI
import BackgroundTasks

@main
struct floatsApp: App {
    @State private var factory: AppFactory

    init() {
        BackgroundFetchScheduler.register()
        let factory = AppFactory()
        _factory = State(initialValue: factory)
        BackgroundFetchScheduler.schedule()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
