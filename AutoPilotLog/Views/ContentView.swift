import SwiftData
import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

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

            Text("설정")
                .tabItem {
                    Label("설정", systemImage: "gear")
                }
                .tag(2)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Issue.self, inMemory: true)
}
