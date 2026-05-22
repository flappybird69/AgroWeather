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

    var subtitle: String {
        switch self {
        case .soilMoisture: return "0–7 cm"
        case .evapotranspiration: return "ET₀"
        case .soilTemperature: return "0–7 cm"
        case .vaporPressureDeficit: return "Έλλειμμα Πίεσης Υδρατμών"
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
    var isLoading: Bool = false
    var compact: Bool = false

    @State private var appear = false

    var body: some View {
        VStack(spacing: compact ? 2 : 0) {
            header
            mainValue.frame(maxHeight: .infinity, alignment: .leading)
            if !compact {
                footer
            }
        }
        .padding(compact ? 10 : 20)
        .frame(height: compact ? 130 : 200)
        .background(type.gradient)
        .premiumCard()
        .overlay(alignment: .bottomTrailing) {
            glossOverlay
        }
        .opacity(isLoading ? 0.5 : 1)
        .redacted(reason: isLoading ? .placeholder : [])
        .offset(y: appear ? 0 : 20)
        .opacity(appear ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.05)) {
                appear = true
            }
        }
    }

    private var header: some View {
        HStack(spacing: compact ? 6 : 10) {
            Image(systemName: type.icon)
                .font(compact ? .caption : .title3.weight(.semibold))
                .foregroundColor(.white.opacity(0.9))

            VStack(alignment: .leading, spacing: 1) {
                Text(type.title)
                    .font(compact ? .caption.weight(.semibold) : .subheadline.weight(.semibold))
                    .foregroundColor(.white)

                if !compact {
                    Text(type.subtitle)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            Spacer()

            if !compact {
                statusBadge
            }
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch type {
        case .soilMoisture:
            if !isLoading {
                Text(levelLabel)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(levelColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
            }
        case .evapotranspiration:
            if !isLoading {
                Text(levelLabel)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(levelColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
            }
        case .soilTemperature:
            if viewModel.hasFrostRisk && !isLoading {
                Label("Παγετός", systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.red.opacity(0.6))
                    .clipShape(Capsule())
            }
        case .vaporPressureDeficit:
            if !isLoading {
                Text(viewModel.vpdRiskLevel.rawValue)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(vpdBadgeColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
            }
        }
    }

    @ViewBuilder
    private var mainValue: some View {
        switch type {
        case .soilMoisture:
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(viewModel.currentSoilMoisturePercent)")
                    .font(.system(size: compact ? 26 : 52, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("%")
                    .font(.system(size: compact ? 13 : 22, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, compact ? 2 : 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

        case .evapotranspiration:
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(String(format: "%.1f", viewModel.currentEvapotranspiration ?? 0))
                    .font(.system(size: compact ? 26 : 52, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("mm")
                    .font(.system(size: compact ? 13 : 22, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, compact ? 2 : 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

        case .soilTemperature:
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(String(format: "%.1f", viewModel.currentSoilTemperature ?? 0))
                    .font(.system(size: compact ? 26 : 52, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("°C")
                    .font(.system(size: compact ? 13 : 22, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, compact ? 2 : 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

        case .vaporPressureDeficit:
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(String(format: "%.2f", viewModel.currentVPD ?? 0))
                    .font(.system(size: compact ? 22 : 44, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("kPa")
                    .font(.system(size: compact ? 11 : 20, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, compact ? 2 : 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
            .frame(maxWidth: .infinity, alignment: .leading)

        case .evapotranspiration:
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(String(format: "%.1f", viewModel.currentEvapotranspiration ?? 0))
                    .font(.system(size: valueSize, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("mm")
                    .font(.system(size: compact ? 14 : 22, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, compact ? 2 : 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

        case .soilTemperature:
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(String(format: "%.1f", viewModel.currentSoilTemperature ?? 0))
                    .font(.system(size: valueSize, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("°C")
                    .font(.system(size: compact ? 14 : 22, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, compact ? 2 : 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

        case .vaporPressureDeficit:
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(String(format: "%.2f", viewModel.currentVPD ?? 0))
                    .font(.system(size: compact ? 24 : 44, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("kPa")
                    .font(.system(size: compact ? 12 : 20, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, compact ? 2 : 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var footer: some View {
        switch type {
        case .soilMoisture:
            footerRow(icon: soilMoistureIcon, text: soilMoistureDescription)
        case .evapotranspiration:
            footerRow(icon: et0Icon, text: et0Description)
        case .soilTemperature:
            footerRow(icon: soilTempIcon, text: soilTempDescription)
        case .vaporPressureDeficit:
            if compact {
                footerRow(icon: vpdSymbol, text: viewModel.vpdRiskLevel.rawValue)
            } else {
                VStack(spacing: 6) {
                    vpdMiniGauge
                    footerRow(icon: vpdSymbol, text: viewModel.vpdRiskLevel.description)
                }
            }
        }
    }

    private func footerRow(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            Text(text)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(1)
            Spacer()
        }
    }

    private var vpdMiniGauge: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white.opacity(0.2))
                    .frame(height: 5)

                Capsule()
                    .fill(vpdGradient)
                    .frame(width: vpdWidth(geo.size.width), height: 5)
            }
        }
        .frame(height: 5)
    }

    private var vpdGradient: LinearGradient {
        LinearGradient(
            colors: [.green, .yellow, .orange, .red],
            startPoint: .leading, endPoint: .trailing
        )
    }

    private var glossOverlay: some View {
        RoundedRectangle(cornerRadius: 20)
            .stroke(.white.opacity(0.15), lineWidth: 1)
    }

    // MARK: - Computed Properties

    private var levelLabel: String {
        switch type {
        case .soilMoisture:
            switch viewModel.currentSoilMoisturePercent {
            case ..<20: return "Ξηρό"
            case ..<40: return "Μέτριο"
            case ..<60: return "Καλό"
            case ..<80: return "Υγρό"
            default: return "Κορεσμένο"
            }
        case .evapotranspiration:
            guard let v = viewModel.currentEvapotranspiration else { return "" }
            switch v {
            case ..<0.2: return "Ελάχιστη"
            case ..<0.5: return "Χαμηλή"
            case ..<0.8: return "Μέτρια"
            case ..<1.2: return "Υψηλή"
            default: return "Πολύ Υψηλή"
            }
        default: return ""
        }
    }

    private var levelColor: Color {
        switch type {
        case .soilMoisture:
            switch viewModel.currentSoilMoisturePercent {
            case ..<20: return .orange
            case ..<40: return .yellow
            case ..<60: return .green
            case ..<80: return .cyan
            default: return .blue
            }
        case .evapotranspiration:
            guard let v = viewModel.currentEvapotranspiration else { return .white }
            switch v {
            case ..<0.2: return .green
            case ..<0.5: return .yellow
            case ..<0.8: return .orange
            case ..<1.2: return .red
            default: return .purple
            }
        default: return .white
        }
    }

    private var vpdBadgeColor: Color {
        switch viewModel.vpdRiskLevel {
        case .low: return .green
        case .moderate: return .yellow
        case .high: return .orange
        case .extreme: return .red
        }
    }

    private var soilMoistureIcon: String {
        switch viewModel.currentSoilMoisturePercent {
        case ..<20: return "flame.fill"
        case ..<40: return "sun.min"
        case ..<60: return "leaf.fill"
        case ..<80: return "drop.fill"
        default: return "cloud.rain.fill"
        }
    }

    private var soilMoistureDescription: String {
        switch viewModel.currentSoilMoisturePercent {
        case ..<20: return "Πολύ ξηρό — χρειάζεται άμεσο πότισμα"
        case ..<40: return "Ξηρό — σκεφτείτε το πότισμα"
        case ..<60: return "Κανονική υγρασία — επαρκής"
        case ..<80: return "Υγρό — μειώστε το πότισμα"
        default: return "Κορεσμένο — κίνδυνος υπερβολικής υγρασίας"
        }
    }

    private var et0Icon: String {
        guard let v = viewModel.currentEvapotranspiration else { return "equal" }
        switch v {
        case ..<0.2: return "arrow.down.to.line"
        case ..<0.5: return "arrow.down"
        case ..<0.8: return "equal"
        case ..<1.2: return "arrow.up"
        default: return "arrow.up.to.line"
        }
    }

    private var et0Description: String {
        guard let v = viewModel.currentEvapotranspiration else { return "" }
        switch v {
        case ..<0.2: return "Ελάχιστη απώλεια νερού"
        case ..<0.5: return "Μικρή απώλεια νερού"
        case ..<0.8: return "Κανονική απώλεια"
        case ..<1.2: return "Αυξήστε την άρδευση"
        default: return "Άμεση ανάγκη για νερό"
        }
    }

    private var soilTempIcon: String {
        guard let v = viewModel.currentSoilTemperature else { return "equal" }
        switch v {
        case ..<2: return "exclamationmark.triangle.fill"
        case ..<8: return "thermometer.snowflake"
        case ..<15: return "thermometer.low"
        case ..<25: return "thermometer"
        case ..<35: return "thermometer.sun"
        default: return "flame.fill"
        }
    }

    private var soilTempDescription: String {
        guard let v = viewModel.currentSoilTemperature else { return "" }
        switch v {
        case ..<2: return "Κίνδυνος παγετού!"
        case ..<8: return "Ψυχρό έδαφος — περιορισμένη ανάπτυξη"
        case ..<15: return "Δροσερό — καλό για πρώιμες καλλιέργειες"
        case ..<25: return "Ιδανική θερμοκρασία"
        case ..<35: return "Ζεστό — αυξήστε άρδευση"
        default: return "Πολύ ζεστό — κίνδυνος για ρίζες"
        }
    }

    private var vpdSymbol: String {
        switch viewModel.vpdRiskLevel {
        case .low: return "checkmark.circle.fill"
        case .moderate: return "exclamationmark.circle.fill"
        case .high: return "exclamationmark.triangle.fill"
        case .extreme: return "xmark.circle.fill"
        }
    }

    private func vpdWidth(_ total: CGFloat) -> CGFloat {
        guard let v = viewModel.currentVPD else { return 0 }
        return CGFloat(min(v / 2.5, 1.0)) * total
    }
}
