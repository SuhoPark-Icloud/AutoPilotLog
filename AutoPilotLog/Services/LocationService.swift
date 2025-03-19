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

        // 위치 업데이트 즉시 시작
        locationManager.startUpdatingLocation()

        // 이미 권한이 있는 경우 추가 설정
        if (authorizationStatus == .authorizedWhenInUse)
            || (authorizationStatus == .authorizedAlways)
        {
            // 더 빠른 위치 업데이트를 위한 설정
            locationManager.pausesLocationUpdatesAutomatically = false

            // iOS 14 이상에서는 정확도 요청 (Info.plist에 NSLocationTemporaryUsageDescriptionDictionary 키 필요)
            if #available(iOS 14.0, *) {
                if locationManager.accuracyAuthorization == .reducedAccuracy {
                    // 정확한 위치가 필요한 이유에 대한 키 (Info.plist에 정의해야 함)
                    locationManager.requestTemporaryFullAccuracyAuthorization(
                        withPurposeKey: "AutoPilotIssueTracking")
                }
            }

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
}

extension LocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        // 권한이 변경되면 위치 업데이트 다시 시작
        if (authorizationStatus == .authorizedWhenInUse)
            || (authorizationStatus == .authorizedAlways)
        {
            // 더 빠른 위치 업데이트를 위한 설정
            locationManager.pausesLocationUpdatesAutomatically = false

            // iOS 14 이상에서는 정확도 요청
            if #available(iOS 14.0, *) {
                if locationManager.accuracyAuthorization == .reducedAccuracy {
                    locationManager.requestTemporaryFullAccuracyAuthorization(
                        withPurposeKey: "AutoPilotIssueTracking")
                }
            }

            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.location = location
    }
}
