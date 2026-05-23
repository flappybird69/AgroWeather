import SwiftUI
import Charts

struct FREDChartView: View {
    @State private var prices: [MarketPrice] = []
    @State private var isLoading = true

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                if isLoading {
                    ProgressView("Φόρτωση τιμών...")
                        .frame(maxWidth: .infinity).padding(.vertical, 60)
                } else {
                    headerText
                    commoditiesGrid
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
                    .font(.caption.weight(.semibold)).foregroundColor(.secondary).tracking(1)
                Text("Πηγή: FRED (Federal Reserve Bank of St. Louis)")
                    .font(.caption2).foregroundColor(.secondary.opacity(0.6))
            }
            Spacer()
        }
    }

    private var commoditiesGrid: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(prices) { price in
                NavigationLink {
                    FREDDetailView(commodity: price)
                } label: {
                    VStack(spacing: 4) {
                        Text(price.name)
                            .font(.caption.weight(.semibold)).foregroundColor(.primary).lineLimit(1).minimumScaleFactor(0.7)
                        Text(price.formattedValue)
                            .font(.system(size: 18, weight: .bold, design: .rounded)).foregroundColor(.agroGreen)
                        Text(price.unit).font(.system(size: 9)).foregroundColor(.secondary)
                        Text(price.date).font(.system(size: 8)).foregroundColor(.secondary.opacity(0.6))
                    }
                    .padding(10).frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private func loadPrices() async {
        isLoading = true
        prices = await (try? MarketDataService.shared.fetchCommodityPrices()) ?? []
        isLoading = false
    }
}

// MARK: - Detail View

struct FREDDetailView: View {
    let commodity: MarketPrice
    @State private var historicalData: [FREDHistoricalPoint] = []
    @State private var isLoading = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                priceSummary
                chartSection
                dataTable
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(commodity.name)
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadData() }
    }

    private var priceSummary: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Τρέχουσα Τιμή")
                    .font(.caption).foregroundColor(.secondary)
                Text("\(commodity.formattedValue) \(commodity.unit)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.agroGreen)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("Τελευταία Ενημέρωση")
                    .font(.caption).foregroundColor(.secondary)
                Text(commodity.date)
                    .font(.subheadline.weight(.medium))
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ΙΣΤΟΡΙΚΗ ΠΟΡΕΙΑ")
                .font(.caption.weight(.semibold)).foregroundColor(.secondary).tracking(1)

            if isLoading {
                ProgressView().frame(maxWidth: .infinity).padding(40)
            } else if historicalData.isEmpty {
                Text("Δεν υπάρχουν διαθέσιμα ιστορικά δεδομένα")
                    .font(.caption).foregroundColor(.secondary).frame(maxWidth: .infinity).padding(40)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Chart {
                    ForEach(historicalData) { point in
                        LineMark(x: .value("Ημερομηνία", point.date), y: .value("Τιμή", point.value))
                            .foregroundStyle(Color.agroGreen)
                            .interpolationMethod(.catmullRom)
                        AreaMark(x: .value("Ημερομηνία", point.date), y: .value("Τιμή", point.value))
                            .foregroundStyle(LinearGradient(colors: [Color.agroGreen.opacity(0.2), Color.agroGreen.opacity(0.01)], startPoint: .top, endPoint: .bottom))
                            .interpolationMethod(.catmullRom)
                    }
                }
                .chartXAxis { AxisMarks(values: .automatic(desiredCount: 6)) { _ in AxisValueLabel(format: .dateTime.year()) } }
                .chartYAxis { AxisMarks { _ in AxisValueLabel() } }
                .frame(height: 250)
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var dataTable: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ΠΡΟΣΦΑΤΕΣ ΤΙΜΕΣ")
                .font(.caption.weight(.semibold)).foregroundColor(.secondary).tracking(1)

            VStack(spacing: 0) {
                HStack {
                    Text("Ημερομηνία").font(.caption.weight(.semibold)).foregroundColor(.secondary)
                    Spacer()
                    Text("Τιμή (\(commodity.unit))").font(.caption.weight(.semibold)).foregroundColor(.secondary)
                }
                .padding(.horizontal, 12).padding(.vertical, 8)

                Divider()

                ForEach(Array(historicalData.sorted { $0.date > $1.date }.prefix(10).enumerated()), id: \.element.id) { index, point in
                    HStack {
                        Text(point.date, format: .dateTime.year().month().day()).font(.caption)
                        Spacer()
                        Text(String(format: "%.2f", point.value)).font(.caption.weight(.medium))
                    }
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    if index < 9 { Divider().padding(.leading, 12) }
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func loadData() async {
        isLoading = true
        historicalData = (try? await MarketDataService.shared.fetchHistoricalData(seriesId: commodity.code)) ?? []
        isLoading = false
    }
}
