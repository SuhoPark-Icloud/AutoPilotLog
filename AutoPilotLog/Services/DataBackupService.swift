import Foundation
import SwiftData
import UIKit

class DataBackupService {
    enum BackupError: Error {
        case exportFailed
        case importFailed
        case invalidData
    }

    static let shared = DataBackupService()

    private init() {}

    // JSON 데이터로 이슈 내보내기
    @MainActor
    func exportIssues(from modelContext: ModelContext) async throws -> URL {
        let descriptor = FetchDescriptor<Issue>()

        do {
            let issues = try modelContext.fetch(descriptor)

            // 이슈 데이터를 JSON 형식으로 변환하기 위한 인코딩 가능한 구조체
            struct IssueData: Codable {
                let title: String
                let issueDescription: String
                let severity: String
                let latitude: Double
                let longitude: Double
                let createdAt: Date
                let resolvedAt: Date?

                init(from issue: Issue) {
                    self.title = issue.title
                    self.issueDescription = issue.issueDescription
                    self.severity = issue.severity.rawValue
                    self.latitude = issue.latitude
                    self.longitude = issue.longitude
                    self.createdAt = issue.createdAt
                    self.resolvedAt = issue.resolvedAt
                }
            }

            // 모든 이슈를 IssueData 배열로 변환
            let issueDataArray = issues.map { IssueData(from: $0) }

            // JSON 인코딩
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(issueDataArray)

            // 임시 파일 URL 생성
            let temporaryDirectory = FileManager.default.temporaryDirectory
            let fileName = "autopilot_issues_\(Date().timeIntervalSince1970).json"
            let fileURL = temporaryDirectory.appendingPathComponent(fileName)

            // 파일에 JSON 데이터 쓰기
            try jsonData.write(to: fileURL)

            return fileURL
        } catch {
            print("내보내기 실패: \(error)")
            throw BackupError.exportFailed
        }
    }

    // JSON 데이터에서 이슈 가져오기
    @MainActor
    func importIssues(from url: URL, into modelContext: ModelContext) async throws {
        do {
            let jsonData = try Data(contentsOf: url)

            // JSON 디코딩을 위한 구조체
            struct IssueData: Codable {
                let title: String
                let issueDescription: String
                let severity: String
                let latitude: Double
                let longitude: Double
                let createdAt: Date
                let resolvedAt: Date?
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let issueDataArray = try decoder.decode([IssueData].self, from: jsonData)

            // 각 IssueData를 Issue 모델로 변환하여 추가
            for issueData in issueDataArray {
                guard let severity = Severity(rawValue: issueData.severity) else {
                    continue  // 유효하지 않은 심각도는 건너뜀
                }

                let issue = Issue(
                    title: issueData.title,
                    issueDescription: issueData.issueDescription,
                    severity: severity,
                    latitude: issueData.latitude,
                    longitude: issueData.longitude
                )

                // createdAt과 resolvedAt 설정
                issue.createdAt = issueData.createdAt
                issue.resolvedAt = issueData.resolvedAt

                modelContext.insert(issue)
            }
        } catch {
            print("가져오기 실패: \(error)")
            throw BackupError.importFailed
        }
    }

    // 시스템 공유 시트를 통해 파일 공유
    func shareFile(url: URL, from viewController: UIViewController) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        viewController.present(activityVC, animated: true)
    }
}
