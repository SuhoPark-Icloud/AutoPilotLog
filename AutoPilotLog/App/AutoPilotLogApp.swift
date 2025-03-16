import SwiftData
import SwiftUI

@main
struct AutoPilotLogApp: App {
    @StateObject private var themeManager = ThemeManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .withTheme()
        }
        .modelContainer(for: Issue.self)
    }
}
