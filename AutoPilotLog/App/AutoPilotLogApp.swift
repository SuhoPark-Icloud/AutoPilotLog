import SwiftData
import SwiftUI

@main
struct AutoPilotLogApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Issue.self)
    }
}
