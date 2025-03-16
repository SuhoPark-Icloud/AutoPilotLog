import CoreLocation
import MapKit
import SwiftUI

struct MapView: View {
    @StateObject private var locationService = LocationService()
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var mapSelection: MKMapItem?
    @State private var showIssueForm = false
    @State private var selectedCoordinate: CLLocationCoordinate2D?

    var body: some View {
        Map(initialPosition: cameraPosition) {
            // 사용자 위치 표시
            if let location = locationService.location {
                UserAnnotation()
            }

            // 여기에 나중에 이슈 마커를 추가할 예정
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .mapStyle(.standard(elevation: .realistic))
        .onAppear {
            // 앱 시작 시 사용자 위치로 카메라 위치 설정
            if let location = locationService.location {
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    ))
            }
        }
        .onLongPressGesture {
            // 지도를 길게 눌러 새 이슈 생성 위치 선택
            // 현재 지도 중심 위치를 사용
            if let location = locationService.location {
                selectedCoordinate = location.coordinate
            } else {
                // 기본 위치 사용 (서울 중심)
                selectedCoordinate = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)
            }
            showIssueForm = true
        }
        .sheet(isPresented: $showIssueForm) {
            // 여기에 이슈 생성 폼을 추가할 예정
            Text("이슈 추가 폼이 여기에 표시됩니다")
                .padding()
        }
    }
    // 지도에서 특정 위치를 탭하여 이슈를 추가하는 기능은
    // 나중에 MKMapView와 UIViewRepresentable을 사용하여 구현할 수 있습니다.
}

#Preview {
    MapView()
}
