import CoreLocation
import MapKit
import SwiftData
import SwiftUI

// 좌표를 Identifiable로 만들기 위한 확장
extension CLLocationCoordinate2D: @retroactive Identifiable {
    public var id: String {
        "\(latitude),\(longitude)"
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .opacity(configuration.isPressed ? 0.9 : 1)  // 투명도 변화 추가
            .rotationEffect(Angle(degrees: configuration.isPressed ? 3 : 0))  // 약간의 회전 추가
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct MapView: View {
    @StateObject private var locationService = LocationService()
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var hasSetInitialLocation = false
    @State private var showLocationAlert = false
    @State private var sheetCoordinate: CLLocationCoordinate2D? = nil
    @State private var selectedIssue: Issue?

    @Query private var issues: [Issue]

    var body: some View {
        ZStack {
            Map(position: $cameraPosition, selection: $selectedIssue) {
                // 사용자 위치 표시
                UserAnnotation()

                // 저장된 이슈 마커 표시 - IssueDetailView 스타일 적용
                ForEach(issues) { issue in
                    Marker(issue.title, coordinate: issue.coordinate)
                        .tint(getMarkerColor(for: issue.severity))
                        .tag(issue)
                }
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            .mapStyle(.standard(elevation: .realistic))
            .onAppear {
                // 앱 시작 시 사용자 위치 권한 요청
                locationService.requestPermission()
            }
            .onChange(of: locationService.location) { _, newValue in
                // 위치가 업데이트될 때마다 실행
                guard let newLocation = newValue else { return }

                // 초기 위치를 아직 설정하지 않았다면 카메라 업데이트
                if !hasSetInitialLocation {
                    cameraPosition = .region(
                        MKCoordinateRegion(
                            center: newLocation.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )
                    )
                    hasSetInitialLocation = true
                }
            }
            .onLongPressGesture {
                // 지도 길게 누르기 시 위치 확인
                checkLocationAndProceed()
            }

            // 이슈 추가 플로팅 버튼
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            // 버튼 누를 때 작은 애니메이션 효과
                        }

                        // 위치 정보 확인 후 진행
                        checkLocationAndProceed()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 56, height: 56)
                                .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 2)

                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.blue)
                        }
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.trailing, 20)
                    .padding(.bottom, 30)
                }
            }
        }
        .sheet(item: $sheetCoordinate, onDismiss: { sheetCoordinate = nil }) { coordinate in
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
        if let location = locationService.location {
            sheetCoordinate = location.coordinate
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
