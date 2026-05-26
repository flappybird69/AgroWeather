import SwiftUI

struct IrrigationCalculatorView: View {
    @Environment(WeatherViewModel.self) private var viewModel
    @State private var areaStremma: Double = 10
    @State private var cropType = "Ελιά"

    let crops: [(name: String, factor: Double)] = [
        ("Ελιά", 0.65), ("Αμπέλι", 0.70), ("Πορτοκαλιά", 0.85),
        ("Βαμβάκι", 0.90), ("Καλαμπόκι", 1.00), ("Ντομάτα", 0.95),
        ("Μηδική", 0.85), ("Λαχανικά", 0.80),
    ]

    var waterNeeded: Double? {
        guard let et0 = viewModel.currentEvapotranspiration else { return nil }
        let factor = crops.first(where: { $0.name == cropType })?.factor ?? 0.7
        let mm = et0 * factor
        let litersPerStremma = mm * 667 // 1mm × 667m² = 667L
        return litersPerStremma * areaStremma
    }

    var rainDeficit: Double? {
        guard let rain = viewModel.totalPrecipitation else { return nil }
        let effectiveRain = rain * 0.7
        return max(0, (waterNeeded ?? 0) - effectiveRain * 667 * areaStremma / 1000)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ΥΠΟΛΟΓΙΣΤΗΣ ΑΡΔΕΥΣΗΣ")
                .font(.caption.weight(.semibold)).foregroundColor(.secondary).tracking(1).padding(.leading, 4)

            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "drop.fill").foregroundColor(.blue)
                    Text("ET₀: \(viewModel.currentEvapotranspiration.map { String(format: "%.2f mm", $0) } ?? "—")")
                    Spacer()
                    Image(systemName: "cloud.rain.fill").foregroundColor(.blue)
                    Text("Βροχή: \(viewModel.totalPrecipitation.map { String(format: "%.1f mm", $0) } ?? "—")")
                }
                .font(.caption).foregroundColor(.secondary)

                HStack {
                    Text("Έκταση")
                    Spacer()
                    Picker("", selection: $areaStremma) {
                        ForEach(Array(stride(from: 1, through: 100, by: 1)), id: \.self) { v in
                            Text("\(v) στρέμ.").tag(Double(v))
                        }
                    }
                    .tint(.agroGreen)
                }

                HStack {
                    Text("Καλλιέργεια")
                    Spacer()
                    Picker("", selection: $cropType) {
                        ForEach(crops, id: \.name) { crop in
                            Text(crop.name).tag(crop.name)
                        }
                    }
                    .tint(.agroGreen)
                }

                if let water = waterNeeded {
                    Divider()
                    VStack(spacing: 4) {
                        Text("Χρειάζεστε σήμερα:")
                            .font(.caption).foregroundColor(.secondary)
                        Text("\(String(format: "%.0f", water)) λίτρα")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                        Text("για \(String(format: "%.0f", areaStremma)) στρέμματα \(cropType)")
                            .font(.caption).foregroundColor(.secondary)

                        if let deficit = rainDeficit, deficit > 0 {
                            Text("Μετά τη βροχή: \(String(format: "%.0f", deficit)) λίτρα")
                                .font(.caption).foregroundColor(.orange)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.blue.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Text("Δεν υπάρχουν δεδομένα ET₀. Επιλέξτε ένα χωράφι.")
                        .font(.caption).foregroundColor(.secondary)
                        .frame(maxWidth: .infinity).padding(12)
                }
            }
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
