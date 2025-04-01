import CoreLocation
import MapKit

// 좌표를 Identifiable로 만들기 위한 확장
extension CLLocationCoordinate2D: @retroactive Identifiable {
    public var id: String {
        "\(latitude),\(longitude)"
    }
}
