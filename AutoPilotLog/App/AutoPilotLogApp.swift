import SwiftData
import SwiftUI

@main
struct AutoPilotLogApp: App {
    @StateObject private var themeManager = ThemeManager.shared
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .withTheme()
        }
        .modelContainer(for: Issue.self)
    }
}
