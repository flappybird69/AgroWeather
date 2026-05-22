import SwiftUI

struct SplashScreen: View {
    @State private var showPowered = false
    @State private var isActive = false
    @AppStorage("has_seen_onboarding") private var hasSeenOnboarding = false

    var body: some View {
        if isActive {
            Group {
                if hasSeenOnboarding {
                    ContentView()
                } else {
                    OnboardingView()
                }
            }
            .transition(.opacity.animation(.easeInOut(duration: 0.4)))
        } else {
            VStack(spacing: 0) {
                Spacer()

                Image(systemName: "tree.fill")
                    .font(.system(size: 76))
                    .foregroundColor(.agroGreen)
                    .symbolRenderingMode(.hierarchical)

                Text("AgroWeather")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .padding(.top, 16)

                Text("Αγρομετεωρολογικά Δεδομένα")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)

                Spacer()

                Text("Powered by Sephiance Inc")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .opacity(showPowered ? 1 : 0)
                    .padding(.bottom, 50)
            }
            .padding()
            .background(Color(.systemBackground))
            .onAppear {
                withAnimation(.easeOut.delay(1.0)) {
                    showPowered = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        isActive = true
                    }
                }
            }
        }
    }
}
