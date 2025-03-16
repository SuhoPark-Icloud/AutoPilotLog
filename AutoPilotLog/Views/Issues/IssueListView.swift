import SwiftData
import SwiftUI

struct IssueListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Issue.createdAt, order: .reverse) private var issues: [Issue]
    @State private var showingDeleteAlert = false
    @State private var issueToDelete: Issue?

    var body: some View {
        NavigationStack {
            List {
                ForEach(issues) { issue in
                    NavigationLink(destination: IssueDetailView(issue: issue)) {
                        HStack {
                            Circle()
                                .fill(getSeverityColor(issue.severity))
                                .frame(width: 12, height: 12)

                            VStack(alignment: .leading) {
                                Text(issue.title)
                                    .font(.headline)

                                Text(formatDate(issue.createdAt))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .onDelete(perform: prepareForDelete)
            }
            .navigationTitle("이슈 목록")
            .toolbar {
                EditButton()
            }
            .alert("이슈 삭제", isPresented: $showingDeleteAlert) {
                Button("취소", role: .cancel) {}
                Button("삭제", role: .destructive) {
                    if let issue = issueToDelete {
                        deleteIssue(issue)
                    }
                }
            } message: {
                Text("이 이슈를 정말 삭제하시겠습니까?")
            }
        }
    }

    private func getSeverityColor(_ severity: Severity) -> Color {
        switch severity {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func prepareForDelete(at offsets: IndexSet) {
        if let index = offsets.first {
            issueToDelete = issues[index]
            showingDeleteAlert = true
        }
    }

    private func deleteIssue(_ issue: Issue) {
        modelContext.delete(issue)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Issue.self, configurations: config)

    // 샘플 이슈 데이터 추가
    let sampleIssues = [
        Issue(
            title: "브레이크 응답 지연", issueDescription: "급제동 시 0.5초 딜레이 발생", severity: .high,
            latitude: 37.5665, longitude: 126.9780),
        Issue(
            title: "차선 인식 오류", issueDescription: "우회전 시 차선 인식 실패", severity: .medium,
            latitude: 37.5668, longitude: 126.9770),
        Issue(
            title: "신호등 오인식", issueDescription: "빨간불을 초록불로 잘못 인식", severity: .critical,
            latitude: 37.5660, longitude: 126.9775),
    ]

    for issue in sampleIssues {
        container.mainContext.insert(issue)
    }

    return IssueListView()
        .modelContainer(container)
}
