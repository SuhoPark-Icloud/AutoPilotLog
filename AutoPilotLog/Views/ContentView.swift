import SwiftData
import SwiftUI

struct ContentView: View {
    @State private var selectedTab: AppTab = .map

    var body: some View {
        TabView(selection: $selectedTab) {
            // 지도 탭
            Tab(AppTab.map.title, systemImage: AppTab.map.iconName, value: AppTab.map) {
                MapView()
            }

            // 이슈 목록 탭
            Tab(
                AppTab.issueList.title, systemImage: AppTab.issueList.iconName,
                value: AppTab.issueList
            ) {
                IssueListView()
            }

            // 설정 탭
            Tab(
                AppTab.settings.title, systemImage: AppTab.settings.iconName, value: AppTab.settings
            ) {
                SettingsView()
            }
        }
        .tabViewStyle(.sidebarAdaptable)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Issue.self, inMemory: true)
}
