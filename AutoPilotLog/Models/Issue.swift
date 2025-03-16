import CoreLocation
import Foundation
import SwiftData

@Model
final class Issue {
    var title: String
    var issueDescription: String
    var severity: Severity
    var latitude: Double
    var longitude: Double
    var createdAt: Date
    var resolvedAt: Date?

    init(
        title: String, issueDescription: String, severity: Severity, latitude: Double,
        longitude: Double
    ) {
        self.title = title
        self.issueDescription = issueDescription
        self.severity = severity
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = Date()
        self.resolvedAt = nil
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

enum Severity: String, Codable, CaseIterable {
    case low = "낮음"
    case medium = "중간"
    case high = "높음"
    case critical = "심각"

    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "orange"
        case .critical: return "red"
        }
    }
}
