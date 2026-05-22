import SwiftUI

struct OnboardingView: View {
    @AppStorage("has_seen_onboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0

    private let pages: [(icon: String, title: String, desc: String)] = [
        ("tree.fill", "Καλώς ήρθατε στο AgroWeather",
         "Η εφαρμογή που βοηθά Έλληνες αγρότες να παρακολουθούν τα χωράφια τους με ακρίβεια."),
        ("map.fill", "Τα Χωράφια σας",
         "Προσθέστε τα χωράφια σας με ένα πάτημα στον χάρτη ή αναζητώντας την τοποθεσία."),
        ("cloud.sun.fill", "Αγρομετεωρολογικά Δεδομένα",
         "Υγρασία εδάφους, θερμοκρασία, εξάτμιση, VPD, άνεμος, βροχή — όλα δωρεάν από το Open‑Meteo."),
        ("lightbulb.fill", "Έξυπνες Συμβουλές",
         "Ο Κύριος Στάθης αναλύει τα δεδομένα και σου λέει πότε να ποτίσεις, να ψεκάσεις ή να φυτέψεις."),
        ("book.fill", "Ημερολόγιο & Σημειώσεις",
         "Καταγράψτε κάθε εργασία, βγάλτε φωτογραφίες, βάλτε υπενθυμίσεις. Όλα συγχρονίζονται στο iCloud."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    pageView(icon: page.icon, title: page.title, desc: page.desc)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            VStack(spacing: 16) {
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Capsule()
                            .fill(currentPage == i ? Color.agroGreen : Color.agroGreen.opacity(0.2))
                            .frame(width: currentPage == i ? 24 : 8, height: 8)
                            .animation(.spring, value: currentPage)
                    }
                }

                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation { currentPage += 1 }
                    } else {
                        hasSeenOnboarding = true
                    }
                } label: {
                    HStack {
                        Text(currentPage < pages.count - 1 ? "Συνέχεια" : "Ξεκινήστε")
                            .font(.headline.weight(.semibold))
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title3)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.agroGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(20)
            .padding(.bottom, 12)
        }
        .background(Color(.systemBackground))
    }

    private func pageView(icon: String, title: String, desc: String) -> some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 72))
                .foregroundColor(.agroGreen)
                .symbolRenderingMode(.hierarchical)

            Text(title)
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)

            Text(desc)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .lineSpacing(4)

            Spacer()
        }
        .padding()
    }
}
