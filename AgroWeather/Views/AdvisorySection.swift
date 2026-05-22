import SwiftUI

struct AdvisorySection: View {
    let advisor: FarmingAdvisor

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            summaryBlock
            recommendationsGrid
            diseaseBlock
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .font(.subheadline)
                .foregroundColor(.agroGold)
            Text("ΣΥΜΒΟΥΛΕΣ ΓΙΑ ΣΗΜΕΡΑ")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .tracking(1)
            Spacer()
            assessmentBadge
        }
    }

    private var assessmentBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: advisor.overallAssessment.icon)
                .font(.caption)
            Text(advisor.overallAssessment.rawValue)
                .font(.caption.weight(.semibold))
        }
        .foregroundColor(assessmentColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(assessmentColor.opacity(0.12))
        .clipShape(Capsule())
    }

    private var assessmentColor: Color {
        switch advisor.overallAssessment {
        case .good: return .green
        case .caution: return .yellow
        case .bad: return .red
        }
    }

    private var summaryBlock: some View {
        Text(advisor.overallSummary)
            .font(.subheadline)
            .foregroundColor(.primary)
            .lineSpacing(4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color(.systemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var recommendationsGrid: some View {
        VStack(spacing: 8) {
            recommendationRow(
                icon: "drop.fill", color: .blue,
                title: "Άρδευση",
                value: advisor.irrigationAdvice.rawValue,
                detail: "Υγρασία εδάφους: \(advisor.weather.currentSoilMoisturePercent)%"
            )
            recommendationRow(
                icon: "leaf.fill", color: .green,
                title: "Φύτευση",
                value: advisor.plantingAdvice.rawValue,
                detail: "Θερμοκρασία εδάφους: \(advisor.weather.current.soilTemperature.formattedTemperature())"
            )
            recommendationRow(
                icon: "wind", color: .orange,
                title: "Ψεκασμός",
                value: advisor.sprayingAdvice.rawValue,
                detail: advisor.weather.current.windSpeed.map { String(format: "Άνεμος: %.0f km/h", $0) } ?? ""
            )
            if advisor.frostRisk != .none {
                recommendationRow(
                    icon: "exclamationmark.triangle.fill", color: .red,
                    title: "Παγετός",
                    value: advisor.frostRisk.rawValue,
                    detail: "Ελάχιστη: \(advisor.weather.lowestSoilTemperature.formattedTemperature())"
                )
            }
        }
    }

    private func recommendationRow(icon: String, color: Color, title: String, value: String, detail: String) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.12))
                    .frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                    Text(value)
                        .font(.caption)
                        .foregroundColor(color)
                }
                if !detail.isEmpty {
                    Text(detail)
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }

            Spacer()
        }
        .padding(8)
        .background(Color(.systemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var diseaseBlock: some View {
        HStack(spacing: 8) {
            Image(systemName: "cross.case.fill")
                .font(.caption)
                .foregroundColor(.purple)
            Text(advisor.diseaseRisk)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(10)
        .background(Color.purple.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
