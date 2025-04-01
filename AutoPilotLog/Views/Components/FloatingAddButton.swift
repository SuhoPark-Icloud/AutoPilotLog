import SwiftUI

struct FloatingAddButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                // 버튼 누를 때 작은 애니메이션 효과
            }
            action()
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

#Preview {
    VStack {
        Spacer()
        HStack {
            Spacer()
            FloatingAddButton {
                print("버튼이 눌렸습니다")
            }
        }
    }
    .background(Color.gray.opacity(0.2))
}
