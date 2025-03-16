import SwiftUI

// 앱 테마 관리 클래스
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @AppStorage("darkModeEnabled") private(set) var isDarkModeEnabled: Bool = false
    @AppStorage("accentColorHex") private var accentColorHex: String = "#0000FF"  // 기본값 파란색

    @Published var accentColor: Color = .blue

    private init() {
        // 저장된 액센트 색상 로드
        accentColor = colorFromHex(accentColorHex)
    }

    // 다크 모드 설정 변경
    func toggleDarkMode() {
        isDarkModeEnabled.toggle()
    }

    // 다크 모드 설정
    func setDarkMode(_ enabled: Bool) {
        isDarkModeEnabled = enabled
    }

    // 액센트 색상 설정
    func setAccentColor(_ color: Color) {
        accentColor = color
        accentColorHex = hexStringFromColor(color)
    }

    // 16진수 문자열에서 Color 변환
    private func colorFromHex(_ hex: String) -> Color {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0

        return Color(red: red, green: green, blue: blue)
    }

    // Color에서 16진수 문자열로 변환 (근사값)
    private func hexStringFromColor(_ color: Color) -> String {
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return String(format: "#%02X%02X%02X", Int(red * 255), Int(green * 255), Int(blue * 255))
    }

    // 앱 테마에 따른 동적 텍스트 색상
    func dynamicText(darkColor: Color = .white, lightColor: Color = .black) -> Color {
        return isDarkModeEnabled ? darkColor : lightColor
    }

    // 앱 테마에 따른 동적 배경 색상
    func dynamicBackground(darkColor: Color = Color(.systemBackground), lightColor: Color = .white)
        -> Color
    {
        return isDarkModeEnabled ? darkColor : lightColor
    }
}

// 뷰 확장으로 쉽게 테마 적용
extension View {
    func withTheme() -> some View {
        preferredColorScheme(ThemeManager.shared.isDarkModeEnabled ? .dark : .light)
            .accentColor(ThemeManager.shared.accentColor)
    }
}
