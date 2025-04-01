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
    @State private var sheetCoordinate: CLLocationCoordinate2D? = nil
    @State private var selectedIssue: Issue?

    // 길게 누른 위치를 저장하기 위한 변수 추가
    @State private var longPressCoordinate: CLLocationCoordinate2D? = nil

    @Query private var issues: [Issue]

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

                    // 길게 눌렀을 때 임시 마커 표시
                    if let coordinate = longPressCoordinate {
                        Marker("새 이슈 위치", systemImage: "plus.circle.fill", coordinate: coordinate)
                            .tint(.blue)
                    }
                }
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapScaleView()
                }
                .mapStyle(.standard(elevation: .realistic))
                .onAppear {
                    // 앱 시작 시 위치 업데이트 시작
                    locationHandler.startLocationUpdates()
                }
                .onChange(of: locationHandler.lastLocation) { _, newValue in
                    // 위치가 업데이트될 때마다 실행
                    // 초기 위치를 아직 설정하지 않았다면 카메라 업데이트
                    if !hasSetInitialLocation {
                        cameraPosition = .region(
                            MKCoordinateRegion(
                                center: newValue.coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                            )
                        )
                        hasSetInitialLocation = true
                    }
                }
                .gesture(
                    LongPressGesture(minimumDuration: 0.5)
                        .sequenced(before: DragGesture(minimumDistance: 0))
                        .onEnded { value in
                            switch value {
                            case .second(true, let drag):
                                if let drag = drag {
                                    // 화면 상의 좌표를 지리적 좌표로 변환
                                    if let coordinate = proxy.convert(drag.location, from: .local) {
                                        longPressCoordinate = coordinate
                                        // 약간의 지연 후 시트 표시
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            sheetCoordinate = coordinate
                                        }
                                    }
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
                        // 위치 정보 확인 후 진행
                        checkLocationAndProceed()
                    }
                }
            }
        }
        .sheet(
            item: $sheetCoordinate,
            onDismiss: {
                sheetCoordinate = nil
                // 시트가 닫힐 때 임시 마커도 제거
                longPressCoordinate = nil
            }
        ) { coordinate in
            IssueFormView(coordinate: coordinate)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedIssue) { issue in
            IssueDetailView(issue: issue)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .alert("위치 정보 없음", isPresented: $showLocationAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("현재 위치 정보를 가져올 수 없습니다. 잠시 후 다시 시도하세요.")
        }
    }

    // 위치 정보 확인 및 처리 메서드
    private func checkLocationAndProceed() {
        // lastLocation이 기본값이 아니라면(좌표가 0.0이 아니라면) 사용
        if locationHandler.lastLocation.coordinate.latitude != 0.0
            && locationHandler.lastLocation.coordinate.longitude != 0.0
        {
            let coordinate = locationHandler.lastLocation.coordinate
            longPressCoordinate = coordinate // 현재 위치에 임시 마커 표시
            sheetCoordinate = coordinate
        } else {
            // 위치 정보가 없는 경우 알림만 표시
            showLocationAlert = true
        }
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
