import SwiftUI

enum WeatherCardType: CaseIterable {
    case soilMoisture
    case evapotranspiration
    case soilTemperature
    case vaporPressureDeficit

    var title: String {
        switch self {
        case .soilMoisture: return "Υγρασία Εδάφους"
        case .evapotranspiration: return "Εξατμισοδιαπνοή"
        case .soilTemperature: return "Θερμοκρασία Εδάφους"
        case .vaporPressureDeficit: return "VPD"
        }
    }

    var icon: String {
        switch self {
        case .soilMoisture: return "drop.fill"
        case .evapotranspiration: return "sun.max.fill"
        case .soilTemperature: return "thermometer.medium"
        case .vaporPressureDeficit: return "humidity.fill"
        }
    }

    var unit: String {
        switch self {
        case .soilMoisture: return "%"
        case .evapotranspiration: return "mm"
        case .soilTemperature: return "°C"
        case .vaporPressureDeficit: return "kPa"
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .soilMoisture: return .moistureCard
        case .evapotranspiration: return .et0Card
        case .soilTemperature: return .tempCard
        case .vaporPressureDeficit: return .vpdCard
        }
    }
}

struct WeatherCardView: View {
    @Environment(WeatherViewModel.self) private var viewModel
    let type: WeatherCardType

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.caption)
                    .foregroundColor(.white)
                Text(type.title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }

            Spacer()

            valueText
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            unitText
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(type.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private var valueText: some View {
        switch type {
        case .soilMoisture:
            Text("\(viewModel.currentSoilMoisturePercent)")
        case .evapotranspiration:
            Text(String(format: "%.1f", viewModel.currentEvapotranspiration ?? 0))
        case .soilTemperature:
            Text(String(format: "%.1f", viewModel.currentSoilTemperature ?? 0))
        case .vaporPressureDeficit:
            Text(String(format: "%.2f", viewModel.currentVPD ?? 0))
        }
    }

    @ViewBuilder
    private var unitText: some View {
        switch type {
        case .soilMoisture:
            Text("%")
        case .evapotranspiration:
            Text("mm")
        case .soilTemperature:
            Text("°C")
        case .vaporPressureDeficit:
            Text("kPa")
        }
    }
}
