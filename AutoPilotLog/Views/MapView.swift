import CoreLocation
import MapKit
import SwiftData
import SwiftUI

struct MapView: View {
    // LocationsHandler 싱글톤 사용
    @StateObject private var locationHandler = LocationsHandler.shared
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var hasSetInitialLocation = false
    @State private var showLocationAlert = false
    @State private var selectedIssue: Issue?

    // 검색 관련 상태
    @State private var searchText = ""

    // 길게 누른 위치와 관련된 상태
    @State private var longPressLocation: CLLocationCoordinate2D? = nil
    @State private var isShowingLocationSheet = false
    @State private var locationName: String = "위치 정보 로딩 중..."
    @State private var locationAddress: String = ""
    @State private var isLoadingLocationInfo = false

    // 이슈 생성 관련 상태
    @State private var isShowingIssueForm = false

    @Query private var issues: [Issue]

    // 지오코더
    private let geocoder = CLGeocoder()

    var body: some View {
        ZStack {
            MapReader { proxy in
                Map(position: $cameraPosition, selection: $selectedIssue) {
                    // 사용자 위치 표시
                    UserAnnotation()

                    // 저장된 이슈 마커 표시
                    ForEach(issues) { issue in
                        Marker(issue.title, coordinate: issue.coordinate)
                            .tint(getMarkerColor(for: issue.severity))
                            .tag(issue)
                    }

                    // 길게 누르면 표시되는 마커
                    if let coordinate = longPressLocation {
                        Marker("", coordinate: coordinate)
                            .tint(.red)
                    }
                }
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapScaleView()
                }
                .mapStyle(.standard(elevation: .realistic))
                .onAppear {
                    locationHandler.startLocationUpdates()
                }
                .onChange(of: locationHandler.lastLocation) { _, newValue in
                    if !hasSetInitialLocation && newValue.coordinate.latitude != 0 {
                        cameraPosition = .region(
                            MKCoordinateRegion(
                                center: newValue.coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                            )
                        )
                        hasSetInitialLocation = true
                    }
                }
                // 실제 터치 위치에 핀을 생성하는 제스처
                .gesture(
                    LongPressGesture(minimumDuration: 0.5)
                        .sequenced(before: DragGesture(minimumDistance: 0))
                        .onEnded { value in
                            switch value {
                            case .second(true, let drag):
                                if let drag = drag,
                                    let coordinate = proxy.convert(drag.location, from: .local)
                                {
                                    // 실제 터치한 위치의 좌표 사용
                                    longPressLocation = coordinate
                                    getLocationInfo(for: coordinate)
                                    isShowingLocationSheet = true
                                }
                            default:
                                break
                            }
                        }
                )
            }

            // 이슈 추가 플로팅 버튼
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FloatingAddButton {
                        checkLocationAndProceed()
                    }
                }
            }
        }
        // 위치 정보 시트
        .sheet(
            isPresented: $isShowingLocationSheet,
            onDismiss: {
                // 이슈 생성 폼이 표시되는 경우가 아니라면 핀 제거
                if !isShowingIssueForm {
                    longPressLocation = nil
                }
            }
        ) {
            LocationInfoView(
                coordinate: longPressLocation ?? CLLocationCoordinate2D(),
                locationName: locationName,
                locationAddress: locationAddress,
                isLoading: isLoadingLocationInfo,
                onCreateIssue: {
                    isShowingLocationSheet = false
                    if let coordinate = longPressLocation {
                        showIssueForm(at: coordinate)
                    }
                }
            )
            .presentationDetents([.height(240), .medium])
            .presentationDragIndicator(.visible)
        }

        // 이슈 생성 시트
        .sheet(
            isPresented: $isShowingIssueForm,
            onDismiss: {
                // 이슈 폼이 닫힐 때 핀 제거
                longPressLocation = nil
            }
        ) {
            if let coordinate = longPressLocation {
                IssueFormView(coordinate: coordinate)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
        // 이슈 상세 시트
        .sheet(item: $selectedIssue) { issue in
            IssueDetailView(issue: issue)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .alert("위치 정보 없음", isPresented: $showLocationAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("현재 위치 정보를 가져올 수 없습니다. 잠시 후 다시 시도하세요.")
        }
    }

    // 위치 정보 조회
    private func getLocationInfo(for coordinate: CLLocationCoordinate2D) {
        isLoadingLocationInfo = true

        // 기본 좌표 정보 설정
        let latitude = coordinate.latitude
        let longitude = coordinate.longitude
        locationAddress =
            "위도: \(String(format: "%.6f", latitude)), 경도: \(String(format: "%.6f", longitude))"

        // 지오코딩으로 주소 정보 가져오기
        let location = CLLocation(latitude: latitude, longitude: longitude)
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                isLoadingLocationInfo = false

                if let error = error {
                    print("지오코딩 오류: \(error.localizedDescription)")
                    return
                }

                if let placemark = placemarks?.first {
                    // 주소 정보 구성
                    let name = placemark.name ?? ""
                    let thoroughfare = placemark.thoroughfare ?? ""
                    let subThoroughfare = placemark.subThoroughfare ?? ""
                    let locality = placemark.locality ?? ""
                    let subLocality = placemark.subLocality ?? ""
                    let administrativeArea = placemark.administrativeArea ?? ""

                    // 타이틀 설정
                    if !thoroughfare.isEmpty {
                        locationName = thoroughfare
                        if !subThoroughfare.isEmpty {
                            locationName = "\(thoroughfare) \(subThoroughfare)"
                        }
                    } else if !name.isEmpty {
                        locationName = name
                    } else if !locality.isEmpty {
                        locationName = locality
                    } else {
                        locationName = "지정된 위치"
                    }

                    // 상세 주소 설정
                    var addressComponents: [String] = []

                    if !administrativeArea.isEmpty {
                        addressComponents.append(administrativeArea)
                    }

                    if !locality.isEmpty && locality != administrativeArea {
                        addressComponents.append(locality)
                    }

                    if !subLocality.isEmpty && subLocality != locality {
                        addressComponents.append(subLocality)
                    }

                    if !thoroughfare.isEmpty {
                        if !subThoroughfare.isEmpty {
                            addressComponents.append("\(thoroughfare) \(subThoroughfare)")
                        } else {
                            addressComponents.append(thoroughfare)
                        }
                    }

                    if !addressComponents.isEmpty {
                        locationAddress = addressComponents.joined(separator: " ")
                    }
                }
            }
        }
    }

    // 위치 정보 확인 및 처리 메서드
    private func checkLocationAndProceed() {
        if locationHandler.lastLocation.coordinate.latitude != 0.0
            && locationHandler.lastLocation.coordinate.longitude != 0.0
        {
            let coordinate = locationHandler.lastLocation.coordinate
            longPressLocation = coordinate
            getLocationInfo(for: coordinate)
            isShowingLocationSheet = true
        } else {
            showLocationAlert = true
        }
    }

    // 이슈 생성 폼 표시
    private func showIssueForm(at coordinate: CLLocationCoordinate2D) {
        longPressLocation = coordinate
        isShowingIssueForm = true
    }

    private func getMarkerColor(for severity: Severity) -> Color {
        switch severity {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

// 위치 정보 표시 시트
struct LocationInfoView: View {
    let coordinate: CLLocationCoordinate2D
    let locationName: String
    let locationAddress: String
    let isLoading: Bool
    let onCreateIssue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 위치 이름
            Text(locationName)
                .font(.title2)
                .fontWeight(.bold)
                .lineLimit(1)

            // 주소
            Text(locationAddress)
                .foregroundColor(.secondary)
                .lineLimit(2)

            // 좌표 정보
            HStack {
                Text("위도: \(coordinate.latitude, specifier: "%.6f")")
                    .font(.footnote)
                Text("·")
                    .font(.footnote)
                Text("경도: \(coordinate.longitude, specifier: "%.6f")")
                    .font(.footnote)
            }
            .foregroundColor(.secondary)

            Divider()

            // 액션 버튼들
            HStack(spacing: 24) {
                // 이동 버튼
                Button(action: {
                    // 길찾기 기능 구현
                }) {
                    VStack {
                        Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                            .font(.title2)
                        Text("이동")
                            .font(.caption)
                    }
                }

                // 이슈 생성 버튼
                Button(action: onCreateIssue) {
                    VStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title2)
                        Text("이슈 생성")
                            .font(.caption)
                    }
                }

                // 공유 버튼
                Button(action: {
                    // 위치 공유 기능 구현
                }) {
                    VStack {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title2)
                        Text("공유")
                            .font(.caption)
                    }
                }

                // 더보기 버튼
                Button(action: {
                    // 추가 옵션 기능 구현
                }) {
                    VStack {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.title2)
                        Text("더 보기")
                            .font(.caption)
                    }
                }
            }
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            Group {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemBackground).opacity(0.7))
                }
            }
        )
    }
}
