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

    // 길게 누른 위치와 관련된 상태
    @State private var longPressCompletedCoordinate: CLLocationCoordinate2D? = nil
    @GestureState private var longPressLocation: CGPoint? = nil

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

                    // 길게 누르는 중일 때 표시되는 임시 마커
                    if let longPressLocation = longPressLocation,
                        let coordinate = proxy.convert(longPressLocation, from: .local)
                    {
                        Marker("새 이슈 위치", systemImage: "plus.circle.fill", coordinate: coordinate)
                            .tint(.blue)
                    }

                    // 길게 누르기 완료 후 표시되는 마커 (시트가 표시될 때)
                    if let coordinate = longPressCompletedCoordinate {
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
                    locationHandler.startLocationUpdates()
                }
                .onChange(of: locationHandler.lastLocation) { _, newValue in
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
                        .updating($longPressLocation) { value, state, _ in
                            switch value {
                            case .first(true):
                                // 길게 누르기 시작 - 현재 위치를 화면 중앙으로 간주
                                state = CGPoint(
                                    x: UIScreen.main.bounds.width / 2,
                                    y: UIScreen.main.bounds.height / 2
                                )
                            case .second(true, let drag):
                                // 드래그 위치 업데이트
                                if let drag = drag {
                                    state = drag.location
                                }
                            default:
                                break
                            }
                        }
                        .onEnded { value in
                            switch value {
                            case .second(true, let drag):
                                if let drag = drag,
                                    let coordinate = proxy.convert(drag.location, from: .local)
                                {
                                    // 길게 누르기 완료 - 좌표 저장 및 시트 표시
                                    longPressCompletedCoordinate = coordinate
                                    sheetCoordinate = coordinate
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
        .sheet(
            item: $sheetCoordinate,
            onDismiss: {
                sheetCoordinate = nil
                longPressCompletedCoordinate = nil
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
        if locationHandler.lastLocation.coordinate.latitude != 0.0
            && locationHandler.lastLocation.coordinate.longitude != 0.0
        {
            let coordinate = locationHandler.lastLocation.coordinate
            longPressCompletedCoordinate = coordinate
            sheetCoordinate = coordinate
        } else {
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
