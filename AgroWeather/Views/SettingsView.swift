import SwiftUI

enum AppearanceMode: String, CaseIterable, Codable {
    case system = "Συστήματος"
    case light = "Φωτεινό"
    case dark = "Σκοτεινό"

    var icon: String {
        switch self {
        case .system: return "gearshape.fill"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

struct SettingsView: View {
    @AppStorage("appearance_mode") private var appearanceMode: AppearanceMode = .system
    @AppStorage("icloud_sync_enabled") private var iCloudSync = true
    @AppStorage("reminders_enabled") private var remindersEnabled = true

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        Form {
            Section {
                ForEach(AppearanceMode.allCases, id: \.rawValue) { mode in
                    Button {
                        appearanceMode = mode
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: mode.icon)
                                .font(.title3)
                                .foregroundColor(appearanceMode == mode ? .agroGreen : .secondary)
                                .frame(width: 24)

                            Text(mode.rawValue)
                                .font(.body)
                                .foregroundColor(.primary)

                            Spacer()

                            if appearanceMode == mode {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.agroGreen)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Label("Εμφάνιση", systemImage: "paintbrush.fill")
            }

            Section {
                Toggle(isOn: $iCloudSync) {
                    HStack(spacing: 10) {
                        Image(systemName: "icloud.fill")
                            .font(.title3)
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("iCloud Συγχρονισμός")
                                .font(.body)
                            Text("Συγχρονισμός δεδομένων σε όλες τις συσκευές")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .tint(.agroGreen)

                Toggle(isOn: $remindersEnabled) {
                    HStack(spacing: 10) {
                        Image(systemName: "bell.fill")
                            .font(.title3)
                            .foregroundColor(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Υπενθυμίσεις")
                                .font(.body)
                            Text("Τοπικές ειδοποιήσεις για εργασίες")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .tint(.agroGreen)
            } header: {
                Label("Συγχρονισμός", systemImage: "arrow.triangle.2.circlepath")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("AgroWeather \(appVersion)")
                        .font(.subheadline.weight(.semibold))

                    Text("""
                    Η εφαρμογή αυτή γεννήθηκε μέσα από την αγάπη για την ελληνική γη και τον καθημερινό, τίμιο αγώνα των ανθρώπων της. Σχεδιάστηκε για να γίνει το στήριγμα κάθε παραγωγού που παλεύει με τον καιρό και το χώμα.

                    Είναι αφιερωμένη σε όλους τους αγρότες της πατρίδας μας, μα πάνω απ' όλα, στον καλό μου φίλο, τον Τάσο, που με τον δικό του καθημερινό αγώνα αποτέλεσε την έμπνευση για να γίνει αυτό το εργαλείο πραγματικότητα.

                    Τάσο, για σένα και για κάθε φίλο που μοχθεί στο χωράφι.
                    """)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Πηγές: Open‑Meteo · World Bank · ECB · CAP Reform EU · Apple MapKit")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.6))
                        .padding(.top, 4)

                    HStack(spacing: 12) {
                        Button { openURL("https://doc-hosting.flycricket.io/agroweatherpro-privacy-policy/50e0b302-6153-4d83-a8bd-391d0aaeb2f8/privacy") } label: {
                            Text("Πολιτική Απορρήτου").font(.caption.weight(.medium)).foregroundColor(.agroGreen)
                        }
                        Button { openURL("https://doc-hosting.flycricket.io/agroweatherpro-terms-of-use/a377387f-9afd-4b71-8b26-700af0272355/terms") } label: {
                            Text("Όροι Χρήσης").font(.caption.weight(.medium)).foregroundColor(.agroGreen)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(.vertical, 4)
            } header: {
                Label("Πληροφορίες", systemImage: "info.circle.fill")
            }
        }
        .navigationTitle("Ρυθμίσεις")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(appearanceMode.colorScheme)
    }

    private func openURL(_ url: String) {
        guard let url = URL(string: url) else { return }
        UIApplication.shared.open(url)
    }
}
