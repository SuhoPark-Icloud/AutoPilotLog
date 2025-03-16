import SwiftData
import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        TabView(selection: $selectedTab) {
            MapView()
                .tabItem {
                    Label("지도", systemImage: "map")
                }
                .tag(0)

            IssueListView()
                .tabItem {
                    Label("이슈 목록", systemImage: "list.bullet")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("설정", systemImage: "gear")
                }
                .tag(2)
        }
        .withTheme()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Issue.self, inMemory: true)
}
