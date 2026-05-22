import SwiftUI

struct MarketDataView: View {
    @State private var wbPrices: [MarketPrice] = []
    @State private var ecbPrices: [MarketPrice] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                if isLoading {
                    VStack(spacing: 12) {
                        Spacer().frame(height: 40)
                        ProgressView()
                        Text("Φόρτωση τιμών...")
                            .font(.subheadline).foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    wbSection
                    ecbSection
                    citationsSection
                }
            }
            .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground))
        .task { await loadData() }
        .refreshable { await loadData() }
    }

    // MARK: - World Bank

    private var wbSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "dollarsign.circle.fill", title: "ΠΑΓΚΟΣΜΙΕΣ ΤΙΜΕΣ ΕΜΠΟΡΕΥΜΑΤΩΝ")

            VStack(spacing: 0) {
                ForEach(Array(wbPrices.enumerated()), id: \.element.id) { index, price in
                    priceRow(price)
                    if index < wbPrices.count - 1 {
                        Divider().padding(.leading, 16)
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            citationBar(.worldBank)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - ECB

    private var ecbSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "eurosign.circle.fill", title: "ΔΕΙΚΤΕΣ ΕΕ — ECB")

            VStack(spacing: 0) {
                ForEach(Array(ecbPrices.enumerated()), id: \.element.id) { index, price in
                    priceRow(price)
                    if index < ecbPrices.count - 1 {
                        Divider().padding(.leading, 16)
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            citationBar(.ecb)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Citations

    private var citationsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "text.book.closed.fill", title: "ΠΗΓΕΣ ΔΕΔΟΜΕΝΩΝ & ΑΔΕΙΕΣ")

            VStack(spacing: 0) {
                ForEach(DataCitation.all, id: \.text) { citation in
                    Button {
                        guard let url = URL(string: citation.url) else { return }
                        UIApplication.shared.open(url)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "link.circle.fill")
                                .font(.title3)
                                .foregroundColor(.agroGreen)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(citation.text)
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.primary)
                                Text(citation.license)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "arrow.up.forward")
                                .font(.caption2)
                                .foregroundColor(.secondary.opacity(0.4))
                        }
                        .padding(12)
                        .contentShape(Rectangle())
                    }
                    if citation.text != DataCitation.all.last?.text {
                        Divider().padding(.leading, 40)
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Components

    private func priceRow(_ price: MarketPrice) -> some View {
        HStack(spacing: 10) {
            Text(price.name)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.primary)
                .lineLimit(1)

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text(price.formattedValue)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                HStack(spacing: 4) {
                    Text(price.unit)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                    Text("· \(price.date)")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary.opacity(0.6))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func citationBar(_ source: MarketDataSource) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 9))
                .foregroundColor(.secondary.opacity(0.5))
            Text(source.citation)
                .font(.system(size: 8))
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(.leading, 4)
    }

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.caption).foregroundColor(.secondary)
            Text(title).font(.caption.weight(.semibold)).foregroundColor(.secondary).tracking(1)
        }
        .padding(.leading, 4)
    }

    private func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            async let wb = MarketDataService.shared.fetchWorldBankPrices()
            async let ecb = MarketDataService.shared.fetchECBData()

            let (wbResult, ecbResult) = try await (wb, ecb)
            wbPrices = wbResult.sorted { $0.name < $1.name }
            ecbPrices = ecbResult.sorted { $0.name < $1.name }
        } catch {
            errorMessage = "Αδυναμία λήψης τιμών"
        }

        isLoading = false
    }
}
