import SwiftUI

struct FieldComparisonCard: View {
    @Environment(WeatherViewModel.self) private var viewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            comparisonRows
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.left.arrow.right.circle.fill")
                .font(.subheadline)
                .foregroundColor(.agroGreen)
            Text("ΣΥΓΚΡΙΣΗ ΧΩΡΑΦΙΩΝ")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .tracking(1)
            Spacer()

            if viewModel.isComparisonLoading {
                ProgressView()
                    .scaleEffect(0.7)
            }
        }
    }

    private var comparisonRows: some View {
        VStack(spacing: 8) {
            metricRow(
                icon: "drop.fill", color: .blue,
                title: "Υγρασία Εδάφους",
                value: { $0.soilMoisturePercent.map { "\($0)%" } ?? "—" }
            )
            metricRow(
                icon: "thermometer.medium", color: .green,
                title: "Θερμοκρασία Εδάφους",
                value: { $0.soilTemperature.map { String(format: "%.1f°C", $0) } ?? "—" }
            )
            metricRow(
                icon: "sun.max.fill", color: .orange,
                title: "ET₀",
                value: { $0.evapotranspiration.map { String(format: "%.1f mm", $0) } ?? "—" }
            )
            metricRow(
                icon: "humidity.fill", color: .purple,
                title: "VPD",
                value: { $0.vpd.map { String(format: "%.2f kPa", $0) } ?? "—" }
            )
        }
    }

    private func metricRow(
        icon: String,
        color: Color,
        title: String,
        value: @escaping (FieldComparison) -> String
    ) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }

            HStack(spacing: 0) {
                ForEach(Array(viewModel.fieldComparisons.enumerated()), id: \.element.id) { index, comp in
                    VStack(spacing: 2) {
                        Text(value(comp))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)

                        Text(comp.fieldName)
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)

                    if index < viewModel.fieldComparisons.count - 1 {
                        Divider()
                            .frame(height: 24)
                    }
                }
            }
        }
        .padding(8)
        .background(Color(.systemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
