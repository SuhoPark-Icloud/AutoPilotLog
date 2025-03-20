import CoreLocation
import SwiftData
import SwiftUI

struct IssueFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // 초기 상태값을 viewDidLoad 시점으로 미루기 위한 @State.
    // 이렇게 하면 뷰가 로드될 때마다 값을 다시 초기화하지 않음
    @State private var title: String = ""
    @State private var issueDescription: String = ""
    @State private var severity: Severity

    // TextField 포커스 상태 관리
    @FocusState private var isTitleFocused: Bool

    let coordinate: CLLocationCoordinate2D

    // @AppStorage에서 기본 심각도를 가져옴
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        let defaultSeverityString =
            UserDefaults.standard.string(forKey: "defaultSeverity") ?? Severity.medium.rawValue
        _severity = State(initialValue: Severity(rawValue: defaultSeverityString) ?? .medium)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("이슈 정보")) {
                    TextField("제목", text: $title)
                        .focused($isTitleFocused)
                        // 입력 지연을 방지하기 위한 최적화
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                        .onAppear {
                            // 뷰가 나타나면 딜레이 후 텍스트 필드에 포커스
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                isTitleFocused = true
                            }
                        }

                    TextField("이슈에 대한 상세 설명을 입력하세요", text: $issueDescription, axis: .vertical)
                        .lineLimit(5...10)
                        // 입력 최적화
                        .disableAutocorrection(true)
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
        guard !title.isEmpty else { return }

        // Task를 사용하여 백그라운드에서 처리
        Task {
            let newIssue = Issue(
                title: title,
                issueDescription: issueDescription,
                severity: severity,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )

            // UI 업데이트는 메인 스레드에서 처리
            await MainActor.run {
                modelContext.insert(newIssue)

                // 변경 사항 저장 시 try? 사용하여 에러 처리 간소화
                try? modelContext.save()

                // 폼 닫기
                dismiss()
            }
        }
    }
}

#Preview {
    IssueFormView(coordinate: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780))
        .modelContainer(for: Issue.self, inMemory: true)
}
