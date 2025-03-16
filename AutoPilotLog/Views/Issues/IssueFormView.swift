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

                    VStack(alignment: .leading) {
                        Text("설명")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.leading, 4)

                        TextField("이슈에 대한 상세 설명을 입력하세요", text: $issueDescription, axis: .vertical)
                            .lineLimit(5...10)
                            .textFieldStyle(.roundedBorder)
                            .padding(.top, 2)
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
        let modelContext = modelContext

        let newIssue = Issue(
            title: title,
            issueDescription: issueDescription,
            severity: severity,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )

        modelContext.insert(newIssue)

        dismiss()
    }
}

#Preview {
    IssueFormView(coordinate: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780))
        .modelContainer(for: Issue.self, inMemory: true)
}
