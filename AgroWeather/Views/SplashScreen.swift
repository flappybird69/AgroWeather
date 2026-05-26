import SwiftUI

struct SplashScreen: View {
    @State private var rotation = 0.0
    @State private var logoScale: CGFloat = 0.2
    @State private var glowScale: CGFloat = 0.5
    @State private var titleOffset: CGFloat = 40
    @State private var titleOpacity = 0.0
    @State private var subtitleOpacity = 0.0
    @State private var loadingProgress = 0.0
    @State private var poweredOpacity = 0.0
    @State private var quoteIndex = 0
    @State private var quoteOpacity = 0.0
    @State private var isActive = false
    @AppStorage("has_seen_onboarding") private var hasSeenOnboarding = false

    private let quotes: [(String, String)] = [
        ("Η γη δεν κληρονομείται από τους γονείς μας, δανείζεται από τα παιδιά μας.", "— Αρχαία Παροιμία"),
        ("Ὅστις γῆν ἐργάζεται, πρὸς πάσας ἀρετὰς εὖ πέφυκεν.", "— Σωκράτης"),
        ("Το λάδι βγαίνει από τον ιδρώτα του ελαιοπαραγωγού.", "— Κρητική Παροιμία"),
        ("Ο καλός αγρότης διαβάζει τον καιρό πριν τον μετεωρολόγο.", "— Λαϊκή Σοφία"),
        ("Δίχως νερό και ήλιο, ούτε η ελιά καρπίζει.", "— Παροιμία"),
        ("Το χωράφι θέλει αγάπη, όχι μόνο ιδρώτα.", "— Γεωργική Παροιμία"),
        ("Ούτε η πιο καλή βροχή δεν ωφελεί αν το χώμα δεν είναι έτοιμο.", "— Λαϊκό"),
        ("Το ραντισμένο δέντρο δεν φοβάται το σκουλήκι.", "— Παροιμία"),
        ("Αγρότης χωρίς ημερολόγιο είναι καπετάνιος χωρίς πυξίδα.", "— Σύγχρονο"),
        ("Το καλό κρασί ξεκινά από το σωστό κλάδεμα.", "— Αμπελουργική"),
    ]

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

                    // Animated Logo
                    ZStack {
                        // Outer glow rings
                        ForEach(0..<3) { i in
                            Circle()
                                .stroke(Color.agroGreen.opacity(0.08 - Double(i) * 0.02), lineWidth: 1)
                                .frame(width: 180 + CGFloat(i * 60))
                                .scaleEffect(glowScale + CGFloat(i) * 0.1)
                                .opacity(glowScale * 0.5)
                        }

                        // Pulsing glow
                        Circle()
                            .fill(Color.agroGreen)
                            .frame(width: 160)
                            .opacity(0.06 * glowScale)
                            .blur(radius: 30)

                        // Large leaf with hole — draw leaf, then punch a circle
                        // Using compositingGroup + blendMode for the cutout
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 120))
                            .foregroundColor(.agroGreen)
                            .rotationEffect(.degrees(rotation))
                            .overlay(
                                Circle()
                                    .fill(.white)
                                    .frame(width: 38, height: 38)
                                    .offset(y: 4)
                                    .blendMode(.destinationOut)
                            )
                            .compositingGroup()

                        // Person visible inside the hole
                        Image(systemName: "person.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.agroGreen)
                            .offset(y: 4)

                        // Small accent dots orbiting
                        ForEach(0..<4) { i in
                            Circle()
                                .fill(Color.agroGreen.opacity(0.25))
                                .frame(width: 4, height: 4)
                                .offset(x: 105 * cos(CGFloat(i) * .pi / 2 + rotation * .pi / 180))
                                .offset(y: 105 * sin(CGFloat(i) * .pi / 2 + rotation * .pi / 180))
                        }
                    }
                    .scaleEffect(logoScale)

                    Text("Χωράφι & Μετεωρολογία")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .padding(.top, 24)
                        .offset(y: titleOffset)
                        .opacity(titleOpacity)

                    Text("Αγρομετεωρολογικά Δεδομένα")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                        .opacity(subtitleOpacity)

                    // Rotating inspirational quotes
                    VStack(spacing: 4) {
                        Text(quotes[quoteIndex].0)
                            .font(.system(size: 12, weight: .medium, design: .serif))
                            .foregroundColor(.secondary.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .lineSpacing(2)
                        Text(quotes[quoteIndex].1)
                            .font(.system(size: 10, weight: .regular, design: .serif))
                            .foregroundColor(.secondary.opacity(0.4))
                    }
                    .frame(height: 60)
                    .padding(.top, 16)
                    .opacity(quoteOpacity)

                    Spacer()

                    // Smooth loading bar
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.agroGreen.opacity(0.15))
                            .frame(width: 120, height: 4)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.agroGreen)
                            .frame(width: 120 * loadingProgress, height: 4)
                            .animation(.easeInOut(duration: 0.5), value: loadingProgress)
                    }
                    .padding(.bottom, 8)

                    Text("Powered by Sephiance Inc")
                        .font(.subheadline)
                        .foregroundColor(.secondary.opacity(0.7))
                        .opacity(poweredOpacity)
                        .padding(.bottom, 50)
                }
                .padding()
            }
            .onAppear {
                // Phase 1: Logo spring in
                withAnimation(.spring(response: 0.8, dampingFraction: 0.55, blendDuration: 0.4)) {
                    logoScale = 1.0
                    glowScale = 1.0
                }

                // Phase 2: Continuous leaf rotation
                withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                    rotation = 360
                }

                // Phase 3: Title slides up
                withAnimation(.spring(response: 0.6, dampingFraction: 0.65).delay(0.3)) {
                    titleOffset = 0
                    titleOpacity = 1.0
                }

                // Phase 4: Subtitle fades in
                withAnimation(.easeOut.delay(0.8)) { subtitleOpacity = 1.0 }

                // Phase 5: Loading bar fills over 3s
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeOut(duration: 2.5)) { loadingProgress = 1.0 }
                }

                // Phase 6: Powered by fades
                withAnimation(.easeOut.delay(2.0)) { poweredOpacity = 1.0 }

                // Phase 6b: Start rotating quotes (cycle every 1.2s)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeOut(duration: 0.6)) { quoteOpacity = 1.0 }
                    Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { t in
                        withAnimation(.easeInOut(duration: 0.3)) { quoteOpacity = 0 }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            quoteIndex = (quoteIndex + 1) % quotes.count
                            withAnimation(.easeInOut(duration: 0.3)) { quoteOpacity = 1.0 }
                        }
                    }
                }

                // Phase 7: Transition after 4s
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                    withAnimation(.easeInOut(duration: 0.5)) { isActive = true }
                }
            }
        }
    }
}
