import SwiftData
import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var locationHandler = LocationsHandler.shared

    // 사용자 기본 설정 저장
    @AppStorage("defaultSeverity") private var defaultSeverity: String = Severity.medium.rawValue
    // 개발자 모드 설정
    @AppStorage("developerMode") private var developerMode: Bool = false

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
    @State private var showingDbResetAlert = false

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

                    // 개발자 모드 활성화
                    #if DEBUG
                        Toggle("개발자 모드", isOn: $developerMode)
                    #endif
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

                // 개발자 옵션 섹션 (디버그 모드와 개발자 모드가 활성화된 경우에만 표시)
                #if DEBUG
                    if developerMode {
                        Section(header: Text("개발자 옵션").foregroundColor(.orange)) {
                            // 현재 스키마 버전 표시
                            HStack {
                                Text("현재 스키마 버전")
                                Spacer()
                                Text(UserDefaults.standard.string(forKey: "schemaVersion") ?? "없음")
                                    .foregroundColor(.gray)
                            }

                            // 데이터베이스 초기화 버튼
                            Button("데이터베이스 초기화") {
                                showingDbResetAlert = true
                            }
                            .foregroundColor(.red)

                            // 주의 메시지
                            Text("⚠️ 주의: 이 옵션은 모든 데이터를 삭제합니다")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                #endif

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
            .alert("데이터베이스 초기화", isPresented: $showingDbResetAlert) {
                Button("취소", role: .cancel) {}
                Button("초기화", role: .destructive) {
                    resetDatabase()
                }
            } message: {
                Text("모든 데이터가 영구적으로 삭제됩니다. 계속하시겠습니까?")
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

    // 데이터베이스 초기화 함수
    /// - 주의: 이 기능은 개발용으로만 사용하고 출시 전에 반드시 제거해야 합니다.
    private func resetDatabase() {
        #if DEBUG
            // SwiftData 데이터베이스 파일 삭제
            do {
                try deleteSwiftDataStore()

                // 스키마 버전 정보 삭제
                UserDefaults.standard.removeObject(forKey: "schemaVersion")

                // 성공 메시지 표시
                errorMessage = "데이터베이스가 초기화되었습니다. 앱을 다시 시작하세요."
                showingErrorAlert = true
            } catch {
                errorMessage = "데이터베이스 초기화 실패: \(error.localizedDescription)"
                showingErrorAlert = true
            }
        #endif
    }

    /// SwiftData 데이터베이스 파일을 삭제합니다.
    /// - 주의: 개발용으로만 사용하세요. 출시 전에 반드시 제거해야 합니다.
    private func deleteSwiftDataStore() throws {
        // 앱의 Application Support 디렉토리 내에 있는 SwiftData 데이터베이스 찾기
        let applicationSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        let storesURL = applicationSupportURL.appendingPathComponent("default.store")

        // 존재하는 경우 삭제
        if FileManager.default.fileExists(atPath: storesURL.path) {
            try FileManager.default.removeItem(at: storesURL)
            print("⚠️ SwiftData 데이터베이스 삭제됨: \(storesURL.path)")
        }
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
