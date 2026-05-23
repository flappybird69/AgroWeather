import SwiftUI
import Charts

struct FREDChartView: View {
    @State private var prices: [MarketPrice] = []
    @State private var isLoading = true
    @State private var selectedCommodity: MarketPrice?
    @State private var historicalData: [FREDHistoricalPoint] = []
    @State private var isLoadingHistory = false

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                if isLoading {
                    ProgressView("Φόρτωση τιμών...")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                } else {
                    headerText
                    commoditiesGrid
                    if let selected = selectedCommodity {
                        chartSection(selected)
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .task { await loadPrices() }
    }

    private var headerText: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("ΠΑΓΚΟΣΜΙΕΣ ΤΙΜΕΣ ΕΜΠΟΡΕΥΜΑΤΩΝ")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                    .tracking(1)
                Text("Πηγή: FRED (Federal Reserve Bank of St. Louis)")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.6))
            }
            Spacer()
        }
    }

    private var commoditiesGrid: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(prices) { price in
                Button {
                    selectedCommodity = price
                    Task { await loadHistory(for: price.code) }
                } label: {
                    VStack(spacing: 4) {
                        Text(price.name)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text(price.formattedValue)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(price.value > 0 ? .agroGreen : .secondary)
                        Text(price.unit)
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                        Text(price.date)
                            .font(.system(size: 8))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .background(selectedCommodity?.code == price.code ? Color.agroGreen.opacity(0.1) : Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedCommodity?.code == price.code ? Color.agroGreen.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
                }
            }
        }
    }

    private func chartSection(_ commodity: MarketPrice) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Ιστορικό \(commodity.name)")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                if isLoadingHistory {
                    ProgressView().scaleEffect(0.7)
                }
            }

            if historicalData.isEmpty && !isLoadingHistory {
                Text("Δεν υπάρχουν διαθέσιμα ιστορικά δεδομένα")
                    .font(.caption).foregroundColor(.secondary)
                    .frame(maxWidth: .infinity).padding(20)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else if !historicalData.isEmpty {
                Chart {
                    ForEach(historicalData) { point in
                        LineMark(
                            x: .value("Ημερομηνία", point.date),
                            y: .value("Τιμή", point.value)
                        )
                        .foregroundStyle(.agroGreen)
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("Ημερομηνία", point.date),
                            y: .value("Τιμή", point.value)
                        )
                        .foregroundStyle(LinearGradient(
                            colors: [Color.agroGreen.opacity(0.2), Color.agroGreen.opacity(0.01)],
                            startPoint: .top, endPoint: .bottom
                        ))
                        .interpolationMethod(.catmullRom)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                        AxisValueLabel(format: .dateTime.year())
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel()
                    }
                }
                .frame(height: 200)
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func loadPrices() async {
        isLoading = true
        prices = await (try? MarketDataService.shared.fetchCommodityPrices()) ?? []
        isLoading = false
    }

    private func loadHistory(for id: String) async {
        isLoadingHistory = true
        historicalData = (try? await MarketDataService.shared.fetchHistoricalData(seriesId: id)) ?? []
        isLoadingHistory = false
    }
}
