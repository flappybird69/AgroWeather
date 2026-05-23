import SwiftUI

struct FREDChartView: View {
    @State private var fredPrices: [MarketPrice] = []
    @State private var ecbPrices: [MarketPrice] = []
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
                    ecbSection
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .task { await loadAll() }
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
            ForEach(fredPrices) { price in
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

    private var ecbSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ΔΕΙΚΤΕΣ ΕΕ (ECB)")
                .font(.caption.weight(.semibold)).foregroundColor(.secondary).tracking(1)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                ForEach(Array(ecbPrices.enumerated()), id: \.element.id) { index, price in
                    HStack {
                        Text(price.name).font(.subheadline.weight(.medium))
                        Spacer()
                        Text(price.formattedValue).font(.subheadline.weight(.bold)).foregroundColor(.agroGreen)
                        Text(price.unit).font(.caption).foregroundColor(.secondary).padding(.leading, 4)
                    }
                    .padding(12)
                    if index < ecbPrices.count - 1 { Divider().padding(.leading, 12) }
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func loadAll() async {
        isLoading = true
        async let fred = MarketDataService.shared.fetchCommodityPrices()
        async let ecb = MarketDataService.shared.fetchECBData()
        (fredPrices, ecbPrices) = await ((try? fred) ?? [], (try? ecb) ?? [])
        isLoading = false
    }
}
