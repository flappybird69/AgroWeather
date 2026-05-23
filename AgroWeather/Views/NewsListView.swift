import SwiftUI

struct NewsListView: View {
    @State private var rssItems: [RSSItem] = []
    @State private var wbPrices: [MarketPrice] = []
    @State private var ecbPrices: [MarketPrice] = []
    @State private var ecPressItems: [ECPressItem] = []
    @State private var isLoadingRSS = true
    @State private var isLoadingPrices = true
    @State private var isLoadingECPress = true
    @State private var errorMessage: String?

    private var sortedPrices: [MarketPrice] {
        (wbPrices + ecbPrices).sorted { $0.name < $1.name }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                marketSection
                euProgramsSection
                ecPressSection
                rssSection
                citationsSection
            }
            .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground))
        .task {
            await loadRSS()
            await loadPrices()
            await loadECPress()
        }
        .refreshable {
            await loadRSS()
            await loadPrices()
            await loadECPress()
        }
    }

    // MARK: - Market Prices

    private var marketSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "chart.line.uptrend.xyaxis", title: "ΑΓΟΡΕΣ ΕΜΠΟΡΕΥΜΑΤΩΝ")

            if isLoadingPrices {
                VStack(spacing: 8) {
                    ProgressView()
                    Text("Φόρτωση τιμών...").font(.caption).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            } else {
                VStack(spacing: 0) {
                    HStack {
                        Text("Εμπόρευμα").font(.caption.weight(.medium)).foregroundColor(.secondary)
                        Spacer()
                        Text("Τιμή").font(.caption.weight(.medium)).foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)

                    Divider()

                    ForEach(Array(sortedPrices.enumerated()), id: \.element.id) { index, price in
                        priceRow(price)
                        if index < sortedPrices.count - 1 {
                            Divider().padding(.leading, 16)
                        }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                citationBar(.fred)
                citationBar(.ecb)
            }
        }
        .padding(.horizontal, 16)
    }

    private func priceRow(_ price: MarketPrice) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                Text(price.name)
                    .font(.subheadline.weight(.medium))
                HStack(spacing: 4) {
                    Text(price.source.rawValue)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.agroGreen)
                    Text("· \(price.date)")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary.opacity(0.6))
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text(price.formattedValue)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Text(price.unit)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    // MARK: - EU Programs

    private var euProgramsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "eurosign.circle.fill", title: "ΕΥΡΩΠΑΪΚΑ ΠΡΟΓΡΑΜΜΑΤΑ")

            VStack(spacing: 0) {
                programRow(icon: "star.fill", color: .blue, title: "ΚΑΠ 2023–2027", subtitle: "Κοινή Αγροτική Πολιτική — άμεσες ενισχύσεις, αγροτική ανάπτυξη, παρεμβάσεις αγοράς", url: "https://agriculture.ec.europa.eu/common-agricultural-policy/cap-overview/cap-2023-27_el")
                Divider().padding(.leading, 50)
                programRow(icon: "leaf.fill", color: .green, title: "Νέοι Αγρότες", subtitle: "Πρόγραμμα εγκατάστασης νέων γεωργών — επιδότηση έως 40.000€", url: "https://www.minagric.gr/for-farmer-2/agrotikes-symvoyles/neoigewrgoi")
                Divider().padding(.leading, 50)
                programRow(icon: "drop.fill", color: .teal, title: "Βιολογική Γεωργία", subtitle: "Ενισχύσεις μετατροπής και διατήρησης βιολογικών καλλιεργειών", url: "https://www.minagric.gr/for-farmer-2/biologicalagriculture")
                Divider().padding(.leading, 50)
                programRow(icon: "wrench.adjustable.fill", color: .orange, title: "Σχέδια Βελτίωσης", subtitle: "Επενδύσεις σε γεωργικές εκμεταλλεύσεις — εξοπλισμός, υποδομές", url: "https://www.minagric.gr/for-farmer-2/sxediabeltiosis")
                Divider().padding(.leading, 50)
                programRow(icon: "building.columns.fill", color: .purple, title: "ΟΠΕΚΕΠΕ", subtitle: "Οργανισμός Πληρωμών — δηλώσεις ΟΣΔΕ, εκταφές, ενισχύσεις", url: "https://www.opekepe.gr")
                Divider().padding(.leading, 50)
                programRow(icon: "map.fill", color: .red, title: "Leader / CLLD", subtitle: "Τοπική ανάπτυξη με πρωτοβουλία τοπικών κοινοτήτων", url: "https://ec.europa.eu/enrd/leader-clld_el.html")
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            Text("Πηγή: ΥπΑΑΤ (minagric.gr) · Ευρωπαϊκή Επιτροπή (ec.europa.eu)")
                .font(.system(size: 8))
                .foregroundColor(.secondary.opacity(0.5))
                .padding(.leading, 4)
        }
        .padding(.horizontal, 16)
    }

    private func programRow(icon: String, color: Color, title: String, subtitle: String, url: String) -> some View {
        Button {
            guard let url = URL(string: url) else { return }
            UIApplication.shared.open(url)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8).fill(color.opacity(0.12)).frame(width: 34, height: 34)
                    Image(systemName: icon).font(.subheadline).foregroundColor(color)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.subheadline.weight(.semibold))
                    Text(subtitle).font(.caption).foregroundColor(.secondary).lineLimit(2)
                }
                Spacer()
                Image(systemName: "arrow.up.forward").font(.caption2).foregroundColor(.secondary.opacity(0.4))
            }
            .padding(12).contentShape(Rectangle())
        }
    }

    // MARK: - RSS News

    private var rssSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "newspaper.fill", title: "ΑΓΡΟΤΙΚΑ ΝΕΑ")

            if isLoadingRSS {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Φόρτωση νέων...").font(.subheadline).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 40)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            } else if let error = errorMessage {
                VStack(spacing: 8) {
                    Image(systemName: "wifi.slash").font(.title2).foregroundColor(.secondary)
                    Text(error).font(.subheadline).foregroundColor(.secondary)
                    Button("Δοκιμάστε ξανά") { Task { await loadRSS() } }
                        .font(.subheadline.weight(.medium)).foregroundColor(.agroGreen)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 40)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            } else if rssItems.isEmpty {
                Text("Δεν υπάρχουν διαθέσιμα νέα")
                    .font(.subheadline).foregroundColor(.secondary)
                    .frame(maxWidth: .infinity).padding(.vertical, 40)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(rssItems.prefix(15))) { item in
                        rssRow(item)
                    }
                }

                citationBar(.fred)
            }
        }
        .padding(.horizontal, 16)
    }

    private func rssRow(_ item: RSSItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(item.source.name)
                    .font(.system(size: 9, weight: .bold)).foregroundColor(.agroGreen)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color.agroGreen.opacity(0.1)).clipShape(Capsule())
                if let date = item.pubDate {
                    Text(date, style: .date).font(.caption2).foregroundColor(.secondary.opacity(0.7))
                }
                Spacer()
            }

            Text(item.title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(3)

            if !item.description.isEmpty {
                Text(item.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
            }

            if URL(string: item.link) != nil {
                Button {
                    guard let url = URL(string: item.link) else { return }
                    UIApplication.shared.open(url)
                } label: {
                    HStack(spacing: 4) {
                        Text("Διάβασε περισσότερα")
                            .font(.caption.weight(.medium))
                        Image(systemName: "arrow.up.forward")
                            .font(.system(size: 8, weight: .semibold))
                    }
                    .foregroundColor(.agroGreen)
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Citations

    private var citationsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "text.book.closed.fill", title: "ΠΗΓΕΣ & ΑΔΕΙΕΣ")

            VStack(spacing: 0) {
                ForEach(DataCitation.all, id: \.text) { citation in
                    Button {
                        guard let url = URL(string: citation.url) else { return }
                        UIApplication.shared.open(url)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "link.circle.fill").font(.title3).foregroundColor(.agroGreen)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(citation.text).font(.caption.weight(.semibold))
                                Text(citation.license).font(.caption2).foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.forward").font(.caption2).foregroundColor(.secondary.opacity(0.4))
                        }
                        .padding(12).contentShape(Rectangle())
                    }
                    if citation.text != DataCitation.all.last?.text { Divider().padding(.leading, 40) }
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.horizontal, 16)
    }

    // MARK: - EC Press Corner

    private var ecPressSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "building.columns.fill", title: "EC ΑΝΑΚΟΙΝΩΣΕΙΣ ΓΕΩΡΓΙΑΣ")

            if isLoadingECPress {
                VStack(spacing: 8) {
                    ProgressView()
                    Text("Φόρτωση ανακοινώσεων...").font(.caption).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            } else if ecPressItems.isEmpty {
                Text("Δεν υπάρχουν διαθέσιμες ανακοινώσεις")
                    .font(.subheadline).foregroundColor(.secondary)
                    .frame(maxWidth: .infinity).padding(.vertical, 30)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            } else {
                VStack(spacing: 0) {
                    ForEach(ecPressItems.prefix(12)) { item in
                        ecPressRow(item)
                        if item.id != ecPressItems.prefix(12).last?.id {
                            Divider().padding(.leading, 16)
                        }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill").font(.system(size: 9)).foregroundColor(.secondary.opacity(0.5))
                    Text("Πηγή: Ευρωπαϊκή Επιτροπή — ec.europa.eu · © EU, αναπαραγωγή με αναφορά πηγής")
                        .font(.system(size: 8)).foregroundColor(.secondary.opacity(0.5))
                }
                .padding(.leading, 4)
            }
        }
        .padding(.horizontal, 16)
    }

    private func ecPressRow(_ item: ECPressItem) -> some View {
        Button {
            guard let url = item.articleURL else { return }
            UIApplication.shared.open(url)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("EC")
                        .font(.system(size: 9, weight: .bold)).foregroundColor(.blue)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1)).clipShape(Capsule())
                    Text(item.docutype.description)
                        .font(.system(size: 9, weight: .medium)).foregroundColor(.secondary)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color(.tertiarySystemGroupedBackground)).clipShape(Capsule())
                    if let date = item.parsedDate {
                        Text(date, style: .date).font(.caption2).foregroundColor(.secondary.opacity(0.7))
                    }
                    Spacer()
                }
                Text(item.title).font(.subheadline.weight(.semibold)).lineLimit(2)
                if let lead = item.leadText, !lead.isEmpty {
                    Text(lead).font(.caption).foregroundColor(.secondary).lineLimit(2)
                }
            }
            .padding(12).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func loadECPress() async {
        isLoadingECPress = true
        ecPressItems = (try? await ECPressService.shared.fetchAgricultureNews()) ?? []
        isLoadingECPress = false
    }

    // MARK: - Helpers

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.caption).foregroundColor(.secondary)
            Text(title).font(.caption.weight(.semibold)).foregroundColor(.secondary).tracking(1)
        }
        .padding(.leading, 4)
    }

    private func citationBar(_ source: MarketDataSource) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "info.circle.fill").font(.system(size: 9)).foregroundColor(.secondary.opacity(0.5))
            Text(source.citation).font(.system(size: 8)).foregroundColor(.secondary.opacity(0.5))
        }
        .padding(.leading, 4)
    }

    private func loadRSS() async {
        isLoadingRSS = true; errorMessage = nil
        let service = RSSService.shared
        var all: [RSSItem] = []
        for source in RSSSource.all {
            if let items = try? await service.fetchRSS(source: source) {
                all.append(contentsOf: items)
            }
        }
        all.sort { ($0.pubDate ?? .distantPast) > ($1.pubDate ?? .distantPast) }
        rssItems = all
        if all.isEmpty { errorMessage = "Αδυναμία λήψης νέων" }
        isLoadingRSS = false
    }

    private func loadPrices() async {
        isLoadingPrices = true
        do {
            async let fred = MarketDataService.shared.fetchCommodityPrices()
            async let ecb = MarketDataService.shared.fetchECBData()
            let (f, e) = try await (fred, ecb)
            wbPrices = f.sorted { $0.name < $1.name }
            ecbPrices = e.sorted { $0.name < $1.name }
        } catch {}
        isLoadingPrices = false
    }
}
