import SwiftUI

struct ProfileCard: View {
    @AppStorage("user_name") private var userName = ""
    @Binding var showSettings: Bool
    @State private var profileImage: UIImage?

    private let profileKey = "profile_image"

    var body: some View {
        Button {
            showSettings = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    if let img = profileImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.agroGreen.opacity(0.15))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.title3)
                                    .foregroundColor(.agroGreen)
                            )
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(greeting)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                    if !userName.isEmpty {
                        Text(userName)
                            .font(.title3.weight(.bold))
                            .foregroundColor(.primary)
                    } else {
                        Text("Πατήστε για να ορίσετε όνομα")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.4))
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .onAppear(perform: loadImage)
        .onChange(of: showSettings) { _, newValue in
            if !newValue { loadImage() }
        }
    }

    private func loadImage() {
        DispatchQueue.global(qos: .background).async {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let url = docs.appendingPathComponent(profileKey)
            guard let data = try? Data(contentsOf: url) else { return }
            let image = UIImage(data: data)
            DispatchQueue.main.async {
                withAnimation(.easeOut(duration: 0.15)) { profileImage = image }
            }
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Καλημέρα"
        case 12..<17: return "Καλησπέρα"
        default: return "Καλησπέρα"
        }
    }
}
