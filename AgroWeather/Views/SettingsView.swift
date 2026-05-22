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
}

struct SettingsView: View {
    @AppStorage("appearance_mode") private var appearanceMode: AppearanceMode = .system
    @AppStorage("icloud_sync_enabled") private var iCloudSync = true
    @AppStorage("reminders_enabled") private var remindersEnabled = true

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
                    Text("AgroWeather v1.0")
                        .font(.subheadline.weight(.semibold))

                    Text("""
                    Η εφαρμογή αυτή γεννήθηκε μέσα από την αγάπη για την ελληνική γη και τον καθημερινό, τίμιο αγώνα των ανθρώπων της. Σχεδιάστηκε για να γίνει το στήριγμα κάθε παραγωγού, κάθε ξωμάχου που παλεύει με τον καιρό και το χώμα.

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
                }
                .padding(.vertical, 4)
            } header: {
                Label("Πληροφορίες", systemImage: "info.circle.fill")
            }
        }
        .navigationTitle("Ρυθμίσεις")
        .navigationBarTitleDisplayMode(.inline)
    }
}
