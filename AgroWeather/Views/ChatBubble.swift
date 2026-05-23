import SwiftUI

struct ChatBubble: View {
    @State private var showBot = false

    var body: some View {
        Button {
            showBot = true
        } label: {
            HStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(Color.agroGreen)
                        .frame(width: 32, height: 32)
                    Image(systemName: "person.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .offset(y: -1)
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 6))
                        .foregroundColor(.green)
                        .offset(x: 6, y: 6)
                }

                Text("Κύριος Στάθης")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.agroGreen)

                Image(systemName: "chevron.right")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(.agroGreen.opacity(0.5))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.regularMaterial)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
        }
        .sheet(isPresented: $showBot) {
            NavigationStack {
                AgriBotView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Κλείσιμο") { showBot = false }
                        }
                    }
            }
        }
    }
}
