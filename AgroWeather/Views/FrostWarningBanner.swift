import SwiftUI

struct FrostWarningBanner: View {
    @Environment(WeatherViewModel.self) private var viewModel

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundColor(.white)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Προειδοποίηση Παγετού")
                        .font(.headline.weight(.bold))
                        .foregroundColor(.white)

                    if let lowest = viewModel.lowestSoilTemperature {
                        Text("Ελάχιστη: \(lowest.formattedTemperature())")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }

                Spacer()
            }

            if !viewModel.frostRiskHours.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(frostHourPreviews) { p in
                            VStack(spacing: 3) {
                                Text(p.time, style: .time)
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.85))
                                Text(String(format: "%.1f°C", p.temperature))
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial.opacity(0.35))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
            }

            Text("Λάβετε προστατευτικά μέτρα για ελιές, πορτοκαλιές και ευαίσθητες καλλιέργειες")
                .font(.caption)
                .foregroundColor(.white.opacity(0.85))
        }
        .padding(16)
        .background(LinearGradient.frostCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .frostRed.opacity(0.35), radius: 16, y: 6)
    }

    private var frostHourPreviews: [FrostHourPreview] {
        viewModel.frostRiskHours.prefix(8).map {
            FrostHourPreview(time: $0.time, temperature: $0.soilTemperature)
        }
    }
}

private struct FrostHourPreview: Identifiable {
    let id = UUID()
    let time: Date
    let temperature: Double
}
