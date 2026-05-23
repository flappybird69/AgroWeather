import SwiftUI

struct FREDChartView: View {
    @State private var fredPrices: [MarketPrice] = []
    @State private var ecbPrices: [MarketPrice] = []
    @State private var isLoading = true
    @AppStorage("user_fred_api_key") private var userApiKey = ""

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                if isLoading {
                    ProgressView("Φόρτωση τιμών...")
                        .frame(maxWidth: .infinity).padding(.vertical, 60)
                } else {
                    if fredPrices.isEmpty {
                        emptyState
                    } else {
                        headerText
                        commoditiesGrid
                        ecbSection
                    }
                    apiKeySection
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .task { await loadAll() }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis").font(.system(size: 40)).foregroundColor(.agroGreen.opacity(0.3))
            Text("Δεν ήταν δυνατή η λήψη τιμών")
                .font(.headline).foregroundColor(.secondary)
            Text("Χρειάζεστε ένα δωρεάν API key από το FRED\nγια να δείτε τις παγκόσμιες τιμές εμπορευμάτων.")
                .font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center).lineSpacing(4)
        }
        .frame(maxWidth: .infinity).padding(30)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
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
                    Text(price.name).font(.caption.weight(.semibold)).foregroundColor(.primary).lineLimit(1).minimumScaleFactor(0.7)
                    Text(price.formattedValue).font(.system(size: 18, weight: .bold, design: .rounded)).foregroundColor(.agroGreen)
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
            Text("ΔΕΙΚΤΕΣ ΕΕ (ECB)").font(.caption.weight(.semibold)).foregroundColor(.secondary).tracking(1).padding(.leading, 4)
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

    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("FRED API KEY").font(.caption.weight(.semibold)).foregroundColor(.secondary).tracking(1).padding(.leading, 4)

            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "key.fill").font(.caption).foregroundColor(.agroGreen)
                    TextField("Εισάγετε το FRED API key σας", text: $userApiKey)
                        .font(.subheadline)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                .padding(12)
                .background(Color(.systemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Text("Το API key αποθηκεύεται τοπικά στη συσκευή σας.")
                    .font(.caption2).foregroundColor(.secondary)

                Button {
                    guard let url = URL(string: "https://fred.stlouisfed.org/docs/api/api_key.html") else { return }
                    UIApplication.shared.open(url)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.forward").font(.caption2)
                        Text("Δημιουργία δωρεάν λογαριασμού FRED")
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundColor(.agroGreen)
                }

                Text("Με ένα δωρεάν API key από το FRED (Federal Reserve Bank of St. Louis) θα έχετε πρόσβαση σε 19 παγκόσμιες τιμές εμπορευμάτων: σιτάρι, καλαμπόκι, ρύζι, σόγια, ζάχαρη, καφές, κακάο, βαμβάκι, ελαιόλαδο, ηλιέλαιο, φοινικέλαιο, πορτοκάλια, μπανάνες, βοδινό, κοτόπουλο, ψάρια, ξυλεία, καουτσούκ και ηλιέλαιο. Όλα τα δεδομένα ανανεώνονται αυτόματα κάθε 24 ώρες χωρίς χρέωση.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineSpacing(3)
                    .padding(.top, 2)

                if !userApiKey.isEmpty {
                    Button {
                        Task { await refreshData() }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise").font(.caption)
                            Text("Δοκιμή & Φόρτωση δεδομένων")
                                .font(.subheadline.weight(.medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.agroGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding(12)
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

    private func refreshData() async {
        // Clear cache
        let defaults = UserDefaults.standard
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix("fred_cache_") {
            defaults.removeObject(forKey: key)
        }
        await loadAll()
    }
}
