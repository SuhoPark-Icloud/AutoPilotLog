import CoreLocation
import SwiftData
import SwiftUI

struct IssueFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title: String = ""
    @State private var issueDescription: String = ""
    @State private var severity: Severity = .medium

    let coordinate: CLLocationCoordinate2D

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

                Section(header: Text("위치 정보")) {
                    VStack(alignment: .leading) {
                        Text("위도: \(coordinate.latitude, specifier: "%.6f")")
                        Text("경도: \(coordinate.longitude, specifier: "%.6f")")
                    }
                }
            }
            .navigationTitle("새 이슈 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        saveIssue()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    private func saveIssue() {
        let newIssue = Issue(
            title: title,
            issueDescription: issueDescription,
            severity: severity,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )

        modelContext.insert(newIssue)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving issue: \(error)")
        }
    }
}

#Preview {
    IssueFormView(coordinate: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780))
        .modelContainer(for: Issue.self, inMemory: true)
}
