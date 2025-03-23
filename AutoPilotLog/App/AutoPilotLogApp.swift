import SwiftData
import SwiftUI

@main
struct AutoPilotLogApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate

    // 현재 스키마 버전 - 스키마 변경 시 이 값을 수정하세요
    private let currentSchemaVersion = "1.0.0"

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(createModelContainer())
    }

    /// ModelContainer를 생성하고 필요시 데이터베이스를 초기화합니다.
    /// - 주의: 이 코드는 개발용으로만 사용하고 출시 전에 반드시 제거해야 합니다.
    /// - 프로덕션 환경에서는 적절한 스키마 마이그레이션 계획을 구현해야 합니다.
    private func createModelContainer() -> ModelContainer {
        // 저장된 스키마 버전을 확인
        let defaults = UserDefaults.standard
        let savedSchemaVersion = defaults.string(forKey: "schemaVersion") ?? ""

        do {
            // 스키마 버전이 변경되었는지 확인
            if savedSchemaVersion != currentSchemaVersion {
                // 개발 중 스키마 변경 시 기존 데이터베이스 삭제
                #if DEBUG
                    try deleteSwiftDataStore()

                    // 새 스키마 버전 저장
                    defaults.set(currentSchemaVersion, forKey: "schemaVersion")
                    print("⚠️ 스키마 버전 변경 감지: 데이터베이스 초기화 완료 (개발용)")
                #endif
            }

            return try ModelContainer(for: Issue.self)
        } catch {
            // 컨테이너 생성 실패 시 데이터베이스 삭제 후 재시도
            print("ModelContainer 생성 실패: \(error.localizedDescription)")

            #if DEBUG
                try? deleteSwiftDataStore()
            #endif

            do {
                return try ModelContainer(for: Issue.self)
            } catch {
                fatalError("ModelContainer 생성 재시도 실패: \(error.localizedDescription)")
            }
        }
    }

    /// SwiftData 데이터베이스 파일을 삭제합니다.
    /// - 주의: 개발용으로만 사용하세요.
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
}
