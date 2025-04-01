import SwiftUI

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .opacity(configuration.isPressed ? 0.9 : 1) // 투명도 변화 추가
            .rotationEffect(Angle(degrees: configuration.isPressed ? 3 : 0)) // 약간의 회전 추가
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}
