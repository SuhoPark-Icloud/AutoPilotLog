import SwiftData
import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var locationHandler = LocationsHandler.shared

    // 사용자 기본 설정 저장
    @AppStorage("defaultSeverity") private var defaultSeverity: String = Severity.medium.rawValue

    // 앱 정보
    private let appVersion =
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    @State private var showingResetAlert = false
    @State private var showingExportAlert = false
    @State private var showingImportPicker = false
    @State private var isExporting = false
    @State private var exportedFileURL: URL?
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            List {
                // 앱 동작 설정 섹션
                Section(header: Text("앱 설정")) {
                    Toggle("위치 추적", isOn: $locationHandler.backgroundActivity)

                    Picker("기본 심각도", selection: $defaultSeverity) {
                        ForEach(Severity.allCases, id: \.self) { severity in
                            Text(severity.rawValue).tag(severity.rawValue)
                        }
                    }
                }

                // 데이터 관리 섹션
                Section(header: Text("데이터 관리")) {
                    Button("데이터 내보내기") {
                        exportData()
                    }
                    .foregroundColor(.blue)

                    Button("데이터 가져오기") {
                        showingImportPicker = true
                    }
                    .foregroundColor(.blue)

                    Button("설정 초기화") {
                        showingResetAlert = true
                    }
                    .foregroundColor(.red)
                }

                // 앱 정보 섹션
                Section(header: Text("앱 정보")) {
                    HStack {
                        Text("버전")
                        Spacer()
                        Text("\(appVersion) (\(buildNumber))")
                            .foregroundColor(.gray)
                    }

                    Link("개발자 정보", destination: URL(string: "https://example.com/developer")!)

                    Link("도움말 및 지원", destination: URL(string: "https://example.com/support")!)
                }

                // 법적 정보 섹션
                Section(header: Text("법적 정보")) {
                    NavigationLink("이용 약관") {
                        Text("여기에 이용 약관 내용이 표시됩니다.")
                            .padding()
                    }

                    NavigationLink("개인정보 처리방침") {
                        Text("여기에 개인정보 처리방침 내용이 표시됩니다.")
                            .padding()
                    }

                    NavigationLink("오픈소스 라이선스") {
                        Text("여기에 오픈소스 라이선스 내용이 표시됩니다.")
                            .padding()
                    }
                }
            }
            .navigationTitle("설정")
            .alert("설정 초기화", isPresented: $showingResetAlert) {
                Button("취소", role: .cancel) {}
                Button("초기화", role: .destructive) {
                    resetSettings()
                }
            } message: {
                Text("모든 설정을 기본값으로 초기화하시겠습니까?")
            }
            .alert("내보내기 완료", isPresented: $showingExportAlert) {
                Button("공유하기") {
                    shareExportedFile()
                }
                Button("확인", role: .cancel) {}
            } message: {
                Text("데이터가 성공적으로 내보내기 되었습니다.")
            }
            .alert("오류", isPresented: $showingErrorAlert) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showingImportPicker) {
                DocumentPicker(onDocumentPicked: importData)
            }
        }
    }

    // 설정 초기화 함수
    private func resetSettings() {
        defaultSeverity = Severity.medium.rawValue

        // 기타 저장된 설정들도 여기서 초기화
    }

    // 데이터 내보내기 함수
    private func exportData() {
        Task {
            do {
                let fileURL = try await DataBackupService.shared.exportIssues(from: modelContext)

                await MainActor.run {
                    exportedFileURL = fileURL
                    showingExportAlert = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = "데이터 내보내기에 실패했습니다: \(error.localizedDescription)"
                    showingErrorAlert = true
                }
            }
        }
    }

    // 내보낸 파일 공유
    private func shareExportedFile() {
        guard let fileURL = exportedFileURL else { return }

        // UIApplication을 통해 키 윈도우의 루트 뷰 컨트롤러 가져오기
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let rootViewController = windowScene.windows.first?.rootViewController
        {
            DataBackupService.shared.shareFile(url: fileURL, from: rootViewController)
        }
    }

    // 데이터 가져오기 함수
    private func importData(url: URL) {
        Task {
            do {
                try await DataBackupService.shared.importIssues(from: url, into: modelContext)

                await MainActor.run {
                    // 성공 메시지 표시
                    errorMessage = "데이터가 성공적으로 가져오기 되었습니다."
                    showingErrorAlert = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = "데이터 가져오기에 실패했습니다: \(error.localizedDescription)"
                    showingErrorAlert = true
                }
            }
        }
    }
}

// DocumentPicker를 위한 UIViewControllerRepresentable
struct DocumentPicker: UIViewControllerRepresentable {
    var onDocumentPicked: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.json])
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(
        _ uiViewController: UIDocumentPickerViewController, context: Context
    ) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker

        init(_ parent: DocumentPicker) {
            self.parent = parent
        }

        func documentPicker(
            _ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]
        ) {
            guard let url = urls.first else { return }

            // 보안 스코프 접근 권한 얻기
            guard url.startAccessingSecurityScopedResource() else { return }

            parent.onDocumentPicked(url)

            // 접근 권한 해제
            url.stopAccessingSecurityScopedResource()
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: Issue.self, inMemory: true)
}
