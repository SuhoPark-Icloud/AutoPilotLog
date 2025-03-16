import MapKit
import SwiftUI

struct IssueDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var issue: Issue
    @State private var showingEditSheet = false
    @State private var isResolved = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 이슈 위치 지도
                Map {
                    Marker(issue.title, coordinate: issue.coordinate)
                        .tint(getSeverityColor(issue.severity))
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // 이슈 정보
                VStack(alignment: .leading, spacing: 8) {
                    Text(issue.title)
                        .font(.title)
                        .fontWeight(.bold)

                    HStack {
                        HStack {
                            Text("심각도:")
                            Text(issue.severity.rawValue)
                                .foregroundColor(getSeverityColor(issue.severity))
                                .fontWeight(.bold)
                        }

                        Spacer()

                        Text(formatDate(issue.createdAt))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if !issue.issueDescription.isEmpty {
                        Text("설명")
                            .font(.headline)
                            .padding(.top, 8)

                        Text(issue.issueDescription)
                            .padding(12)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }

                    // 해결 상태
                    HStack {
                        Toggle("해결됨", isOn: $isResolved)
                            .onChange(of: isResolved) { _, newValue in
                                if newValue {
                                    issue.resolvedAt = Date()
                                } else {
                                    issue.resolvedAt = nil
                                }
                            }

                        if let resolvedDate = issue.resolvedAt {
                            Text("해결 날짜: \(formatDate(resolvedDate))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 8)

                    // 위치 정보
                    Text("위치 정보")
                        .font(.headline)
                        .padding(.top, 8)

                    HStack {
                        VStack(alignment: .leading) {
                            Text("위도: \(issue.latitude, specifier: "%.6f")")
                            Text("경도: \(issue.longitude, specifier: "%.6f")")
                        }

                        Spacer()

                        Button(action: {
                            // 위치 공유 기능 (나중에 구현)
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(12)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding()
            }
        }
        .onAppear {
            isResolved = issue.resolvedAt != nil
        }
        .navigationTitle("이슈 상세")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("편집") {
                showingEditSheet = true
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            IssueEditView(issue: issue)
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
}

// 이슈 편집 뷰
struct IssueEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var issue: Issue

    @State private var title: String
    @State private var issueDescription: String
    @State private var severity: Severity

    init(issue: Issue) {
        self.issue = issue
        _title = State(initialValue: issue.title)
        _issueDescription = State(initialValue: issue.issueDescription)
        _severity = State(initialValue: issue.severity)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("이슈 정보")) {
                    TextField("제목", text: $title)

                    ZStack(alignment: .topLeading) {
                        if issueDescription.isEmpty {
                            Text("설명")
                                .foregroundColor(.gray.opacity(0.5))
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }

                        TextEditor(text: $issueDescription)
                            .frame(minHeight: 100)
                    }
                }

                Section(header: Text("심각도")) {
                    Picker("심각도 선택", selection: $severity) {
                        ForEach(Severity.allCases, id: \.self) { severity in
                            Text(severity.rawValue)
                                .tag(severity)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("이슈 편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        saveChanges()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    private func saveChanges() {
        issue.title = title
        issue.issueDescription = issueDescription
        issue.severity = severity
        dismiss()
    }
}
