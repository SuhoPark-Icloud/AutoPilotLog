import CoreLocation
import MapKit
import SwiftData
import SwiftUI

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
    @State private var mapSelection: MKMapItem?
    @State private var showIssueForm = false
    @State private var selectedCoordinate: CLLocationCoordinate2D?

    @Query private var issues: [Issue]

    var body: some View {
        ZStack {
            Map(initialPosition: cameraPosition) {
                // 사용자 위치 표시
                UserAnnotation()

                // 저장된 이슈 마커 표시
                ForEach(issues) { issue in
                    Marker(issue.title, coordinate: issue.coordinate)
                        .tint(getMarkerColor(for: issue.severity))
                }
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            .mapStyle(.standard(elevation: .realistic))
            .onAppear {
                // 앱 시작 시 사용자 위치로 카메라 위치 설정
                locationService.requestPermission()
                if let location = locationService.location {
                    cameraPosition = .region(
                        MKCoordinateRegion(
                            center: location.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)))
                }
            }
            .onLongPressGesture {
                // 지도를 길게 눌러 새 이슈 생성 위치 선택
                if let location = locationService.location {
                    selectedCoordinate = location.coordinate
                    showIssueForm = true
                } else {
                    // 기본 위치 사용 (서울 중심)
                    selectedCoordinate = CLLocationCoordinate2D(
                        latitude: 37.5665, longitude: 126.9780)
                    showIssueForm = true
                }
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

                        if let location = locationService.location {
                            selectedCoordinate = location.coordinate
                            showIssueForm = true
                        } else {
                            // 위치를 가져올 수 없는 경우 기본 위치 사용
                            selectedCoordinate = CLLocationCoordinate2D(
                                latitude: 37.5665, longitude: 126.9780)
                            showIssueForm = true
                        }
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
                    .buttonStyle(ScaleButtonStyle())  // 아래에 정의한 버튼 스타일 적용
                    .padding(.trailing, 20)
                    .padding(.bottom, 30)
                }
            }
        }
        .sheet(
            isPresented: $showIssueForm,
            onDismiss: {
                // 시트가 닫힐 때 selectedCoordinate 초기화
                selectedCoordinate = nil
            }
        ) {
            if let coordinate = selectedCoordinate {
                IssueFormView(coordinate: coordinate)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            } else {
                // 좌표가 없는 경우 기본 좌표 사용
                let defaultCoordinate = CLLocationCoordinate2D(
                    latitude: 37.5665, longitude: 126.9780)
                IssueFormView(coordinate: defaultCoordinate)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
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

#Preview {
    MapView()
        .modelContainer(for: Issue.self, inMemory: true)
}
