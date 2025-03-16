import SwiftData
import SwiftUI

struct IssueListView: View {
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
        @Environment(\.modelContext) var modelContext
        modelContext.delete(issue)
    }
}

#Preview {
    IssueListView()
        .modelContainer(for: Issue.self, inMemory: true)
}
