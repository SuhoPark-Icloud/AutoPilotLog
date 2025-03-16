import SwiftUI

struct ThemeColorPicker: View {
    @StateObject private var themeManager = ThemeManager.shared
    @State private var selectedColor: Color = ThemeManager.shared.accentColor

    // 미리 정의된 색상 옵션
    private let colorOptions: [ColorOption] = [
        ColorOption(name: "파란색", color: .blue),
        ColorOption(name: "빨간색", color: .red),
        ColorOption(name: "초록색", color: .green),
        ColorOption(name: "보라색", color: .purple),
        ColorOption(name: "주황색", color: .orange),
        ColorOption(name: "분홍색", color: .pink),
        ColorOption(name: "청록색", color: .teal),
    ]

    var body: some View {
        List {
            Section(header: Text("색상 선택")) {
                ForEach(colorOptions) { option in
                    Button(action: {
                        selectedColor = option.color
                        themeManager.setAccentColor(option.color)
                    }) {
                        HStack {
                            Circle()
                                .fill(option.color)
                                .frame(width: 24, height: 24)

                            Text(option.name)
                                .padding(.leading, 8)

                            Spacer()

                            if themeManager.accentColor.description == option.color.description {
                                Image(systemName: "checkmark")
                                    .foregroundColor(option.color)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Section(header: Text("현재 테마 미리보기")) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("제목 텍스트")
                        .font(.headline)
                        .foregroundColor(themeManager.accentColor)

                    Text("일반 텍스트는 이렇게 표시됩니다.")
                        .font(.body)

                    Button("버튼 스타일") {
                        // 미리보기용 빈 액션
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(themeManager.accentColor)
                    .cornerRadius(8)

                    Toggle("토글 스위치", isOn: .constant(true))
                        .toggleStyle(SwitchToggleStyle(tint: themeManager.accentColor))

                    Slider(value: .constant(0.7))
                        .accentColor(themeManager.accentColor)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
        .navigationTitle("테마 색상")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// 색상 옵션 모델
struct ColorOption: Identifiable {
    let id = UUID()
    let name: String
    let color: Color
}

#Preview {
    NavigationStack {
        ThemeColorPicker()
    }
}
