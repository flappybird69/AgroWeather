import SwiftUI

struct ProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("user_name") private var userName = ""
    @State private var profileImage: UIImage?
    @State private var showCamera = false
    @State private var showPhotoPicker = false

    private let profileKey = "profile_image"

    var body: some View {
        Form {
            Section {
                HStack(spacing: 16) {
                    ZStack {
                        if let img = profileImage {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 72, height: 72)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.agroGreen.opacity(0.15))
                                .frame(width: 72, height: 72)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.title)
                                        .foregroundColor(.agroGreen)
                                )
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Button {
                            showCamera = true
                        } label: {
                            Label("Φωτογραφία", systemImage: "camera.fill")
                        }
                        .tint(.agroGreen)

                        Button {
                            showPhotoPicker = true
                        } label: {
                            Label("Από άλμπουμ", systemImage: "photo.on.rectangle")
                        }
                        .tint(.agroGreen)
                    }
                    .font(.subheadline)
                }
                .padding(.vertical, 4)
            } header: {
                Label("Φωτογραφία", systemImage: "person.crop.circle.fill")
            }

            Section {
                TextField("Το όνομά σας", text: $userName)
            } header: {
                Label("Όνομα", systemImage: "textformat")
            }
        }
        .navigationTitle("Το Προφίλ μου")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Τέλος") { saveAndDismiss() }
                    .fontWeight(.semibold)
            }
        }
        .onAppear(perform: loadImage)
        .sheet(isPresented: $showCamera) {
            CameraPicker(image: Binding<UIImage?>(
                get: { nil },
                set: { if let img = $0 { profileImage = img; saveImage() } }
            ))
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPicker(images: Binding(
                get: { profileImage.map { [$0] } ?? [] },
                set: { profileImage = $0.first; if let img = $0.first { saveImage() } }
            ))
        }
    }

    private func loadImage() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = docs.appendingPathComponent(profileKey)
        guard let data = try? Data(contentsOf: url) else { return }
        profileImage = UIImage(data: data)
    }

    private func saveImage() {
        guard let img = profileImage, let data = img.jpegData(compressionQuality: 0.7) else { return }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = docs.appendingPathComponent(profileKey)
        try? data.write(to: url)
    }

    private func saveAndDismiss() {
        if let img = profileImage { saveImage() }
        dismiss()
    }
}
