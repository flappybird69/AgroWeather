import SwiftUI

struct SplashScreen: View {
    @State private var animationPhase = 0.0
    @State private var logoScale = 0.3
    @State private var logoGlow = 0.0
    @State private var titleOffset: CGFloat = 30
    @State private var titleOpacity = 0.0
    @State private var subtitleOpacity = 0.0
    @State private var poweredOpacity = 0.0
    @State private var isActive = false
    @AppStorage("has_seen_onboarding") private var hasSeenOnboarding = false

    var body: some View {
        if isActive {
            Group {
                if hasSeenOnboarding { ContentView() }
                else { OnboardingView() }
            }
            .transition(.opacity.animation(.easeInOut(duration: 0.5)))
        } else {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    ZStack {
                        // Glow behind logo
                        Circle()
                            .fill(Color.agroGreen.opacity(0.08))
                            .frame(width: 120, height: 120)
                            .scaleEffect(1 + logoGlow * 0.3)
                            .opacity(0.8 - logoGlow * 0.3)

                        // Main leaf icon
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.agroGreen)
                            .rotationEffect(.degrees(animationPhase * 8))
                            .offset(x: 4, y: -6)

                        // Person icon layered
                        Image(systemName: "person.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.agroGreen.opacity(0.7))
                            .offset(y: 6)
                    }
                    .scaleEffect(logoScale)
                    .onAppear {
                        withAnimation(.spring(response: 0.9, dampingFraction: 0.6, blendDuration: 0)) {
                            logoScale = 1.0
                        }
                        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                            logoGlow = 1.0
                            animationPhase = 1.0
                        }
                    }

                    Text("Χωράφι & Μετεωρολογία")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .padding(.top, 24)
                        .offset(y: titleOffset)
                        .opacity(titleOpacity)
                        .onAppear {
                            withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.3)) {
                                titleOffset = 0
                                titleOpacity = 1.0
                            }
                        }

                    Text("Αγρομετεωρολογικά Δεδομένα")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                        .opacity(subtitleOpacity)
                        .onAppear {
                            withAnimation(.easeOut.delay(0.8)) {
                                subtitleOpacity = 1.0
                            }
                        }

                    Spacer()

                    // Loading indicator
                    HStack(spacing: 6) {
                        ForEach(0..<3) { i in
                            Capsule()
                                .fill(Color.agroGreen)
                                .frame(width: 6, height: 6)
                                .scaleEffect(animationPhase == 1.0 ? 1.0 : 0.5)
                                .opacity(animationPhase == 1.0 ? 0.6 : 0.2)
                                .animation(
                                    .easeInOut(duration: 0.6).repeatForever().delay(0.15 * Double(i)),
                                    value: animationPhase
                                )
                        }
                    }
                    .padding(.bottom, 16)

                    Text("Powered by Sephiance Inc")
                        .font(.subheadline)
                        .foregroundColor(.secondary.opacity(0.7))
                        .opacity(poweredOpacity)
                        .padding(.bottom, 50)
                        .onAppear {
                            withAnimation(.easeOut.delay(2.0)) {
                                poweredOpacity = 1.0
                            }
                        }
                }
                .padding()
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        isActive = true
                    }
                }
            }
        }
    }
}
