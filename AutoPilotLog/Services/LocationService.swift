import Combine
import CoreLocation
import Foundation

class LocationService: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()

    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus

    override init() {
        authorizationStatus = locationManager.authorizationStatus

        super.init()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10

        // 위치 업데이트를 더 빠르게 시작
        locationManager.startUpdatingLocation()

        // 이미 권한이 있는 경우 즉시 위치 요청
        if (authorizationStatus == .authorizedWhenInUse)
            || (authorizationStatus == .authorizedAlways)
        {
            locationManager.startUpdatingLocation()
        } else if authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    func requestPermission() {
        if authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    func hasValidLocation() -> Bool {
        // 위치 정보가 존재하고 최근 60초 이내에 업데이트되었는지 확인
        if let location = location {
            let now = Date()
            let locationTimestamp = location.timestamp
            let timeDifference = now.timeIntervalSince(locationTimestamp)

            // 60초 이내에 업데이트된 위치 정보만 유효하다고 판단
            return timeDifference <= 60
        }
        return false
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        // 권한이 변경되면 위치 업데이트 다시 시작
        if (authorizationStatus == .authorizedWhenInUse)
            || (authorizationStatus == .authorizedAlways)
        {
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.location = location
    }
}
