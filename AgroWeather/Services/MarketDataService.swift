import Foundation

actor MarketDataService {
    static let shared = MarketDataService()

    // World Bank API — Commodity Price Data
    // Δωρεάν, no API key required. CC BY 4.0 license.
    // Citation: "Source: World Bank Pink Sheet"
    private let worldBankBase = "https://api.worldbank.org/v2/country/all/indicator"

    // ECB Statistical Data Warehouse API
    // Δωρεάν, no API key required. Citation required.
    // Citation: "Source: European Central Bank (ECB)"
    private let ecbBase = "https://sdw-wsrest.ecb.europa.eu/service/data"

    func fetchWorldBankPrices() async throws -> [MarketPrice] {
        // World Bank Commodity Price Index (Pink Sheet)
        // CM.MKT.INDEX.PI = Commodity Price Index
        // CM.MKT.INDEX.FI = Food Price Index
        let indicators = [
            ("CM.MKT.INDEX.PI", "Γενικός Δείκτης Εμπορευμάτων"),
            ("CM.MKT.INDEX.FI", "Δείκτης Τροφίμων"),
            ("CM.MKT.INDEX.NF", "Δείκτης Μη-Τροφίμων"),
            ("CM.AGR.CORN", "Καλαμπόκι"),
            ("CM.AGR.WHT", "Σιτάρι"),
            ("CM.AGR.RICE", "Ρύζι"),
            ("CM.AGR.SOYBEAN", "Σόγια"),
            ("CM.AGR.SUGAR", "Ζάχαρη"),
            ("CM.AGR.COFFEE", "Καφές"),
            ("CM.AGR.OILVEG", "Φυτικά Έλαια"),
            ("CM.AGR.COTTON", "Βαμβάκι"),
            ("CM.AGR.RUBBER", "Καουτσούκ"),
            ("CM.AGR.BEEF", "Βοδινό"),
            ("CM.AGR.POULTRY", "Κοτόπουλο"),
            ("CM.AGR.FISH", "Ψάρια"),
            ("CM.AGR.SHRIMP", "Γαρίδες"),
            ("CM.AGR.LOG", "Ξυλεία"),
            ("CM.AGR.PLYWOOD", "Κόντρα Πλακέ"),
            ("CM.AGR.BANANA", "Μπανάνες"),
            ("CM.AGR.ORANGE", "Πορτοκάλια"),
        ]

        var prices: [MarketPrice] = []

        for (code, name) in indicators {
            let url = "\(worldBankBase)/\(code)?format=json&per_page=2&date=2024:2026"
            var request = URLRequest(url: URL(string: url)!)
            request.timeoutInterval = 10

            guard let (data, _) = try? await URLSession.shared.data(for: request) else { continue }
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [Any], json.count >= 2,
                  let values = json[1] as? [[Any]] else { continue }

            let recentValues = values.prefix(4).compactMap { entry -> (Double, String)? in
                guard entry.count >= 3,
                      let value = entry[1] as? Double,
                      let date = entry[2] as? String else {
                    if entry.count >= 2,
                       let value = entry[1] as? Double {
                        return (value, "2024")
                    }
                    return nil
                }
                return (value, date)
            }

            if let (value, date) = recentValues.first {
                prices.append(MarketPrice(
                    name: name,
                    code: code,
                    value: value,
                    date: date,
                    unit: unitFor(code),
                    source: .worldBank
                ))
            }
        }

        return prices
    }

    func fetchECBData() async throws -> [MarketPrice] {
        // ECB Agricultural Price Indices
        // AP = Agricultural Price Index
        // CITATION: "Source: European Central Bank (https://www.ecb.europa.eu)"

        let series = [
            ("AP.M.U2.N.T000.4.A", "Γενικός Δείκτης Γεωργίας (ΕΕ)"),
            ("AP.C.U2.N.T000.4.A", "Δείκτης Φυτικής Παραγωγής (ΕΕ)"),
            ("AP.H.U2.N.T000.4.A", "Δείκτης Ζωικής Παραγωγής (ΕΕ)"),
        ]

        var prices: [MarketPrice] = []

        for (code, name) in series {
            let url = "\(ecbBase)/\(code)?format=jsondata&startPeriod=2024"
            var request = URLRequest(url: URL(string: url)!)
            request.timeoutInterval = 10

            guard let (data, _) = try? await URLSession.shared.data(for: request) else { continue }

            // Parse ECB JSON structure
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let dataSets = json["dataSets"] as? [[String: Any]],
                  let seriesData = dataSets.first?["series"] as? [String: Any],
                  let firstSeries = seriesData.values.first as? [String: Any],
                  let observations = firstSeries["observations"] as? [String: [Double]],
                  let firstObs = observations.values.first,
                  let value = firstObs.first else { continue }

            prices.append(MarketPrice(
                name: name,
                code: code,
                value: value,
                date: "2024",
                unit: "Δείκτης 2015=100",
                source: .ecb
            ))
        }

        return prices
    }

    private func unitFor(_ code: String) -> String {
        if code.contains("INDEX") { return "Δείκτης 2010=100" }
        if code.contains("CORN") || code.contains("WHT") || code.contains("RICE") { return "$/τόνο" }
        if code.contains("SUGAR") { return "¢/kg" }
        if code.contains("COFFEE") { return "¢/kg" }
        if code.contains("OILVEG") { return "$/τόνο" }
        if code.contains("COTTON") { return "¢/kg" }
        if code.contains("BEEF") || code.contains("POULTRY") || code.contains("FISH") { return "¢/kg" }
        if code.contains("SOYBEAN") { return "$/τόνο" }
        if code.contains("BANANA") || code.contains("ORANGE") { return "$/τόνο" }
        if code.contains("RUBBER") { return "¢/kg" }
        if code.contains("LOG") || code.contains("PLYWOOD") { return "$/m³" }
        if code.contains("SHRIMP") { return "¢/kg" }
        return "—"
    }
}

// MARK: - Model

struct MarketPrice: Identifiable {
    let id = UUID()
    let name: String
    let code: String
    let value: Double
    let date: String
    let unit: String
    let source: MarketDataSource

    var formattedValue: String {
        if unit.contains("Δείκτης") { return String(format: "%.1f", value) }
        if value > 100 { return String(format: "%.0f", value) }
        if value > 1 { return String(format: "%.1f", value) }
        return String(format: "%.2f", value)
    }
}

enum MarketDataSource: String {
    case worldBank = "Παγκόσμια Τράπεζα"
    case ecb = "Ευρωπαϊκή Κεντρική Τράπεζα"
    case fao = "FAO"

    var citation: String {
        switch self {
        case .worldBank: return "Πηγή: Παγκόσμια Τράπεζα (World Bank Pink Sheet) — worldbank.org • Δεδομένα εμπορευμάτων υπό CC BY 4.0"
        case .ecb: return "Πηγή: Ευρωπαϊκή Κεντρική Τράπεζα (ECB Statistical Data Warehouse) — ecb.europa.eu • Αναπαραγωγή επιτρέπεται με αναφορά πηγής"
        case .fao: return "Πηγή: Food and Agriculture Organization (FAO) — fao.org • Δεδομένα τροφίμων υπό CC BY‑NC‑SA 3.0 IGO"
        }
    }
}

// MARK: - Citation Helper

struct DataCitation {
    let text: String
    let url: String
    let license: String

    static let all: [DataCitation] = [
        DataCitation(
            text: "Αγρομετεωρολογικά δεδομένα: Open‑Meteo Agrometeorology API",
            url: "https://open-meteo.com",
            license: "Δωρεάν για εμπορική χρήση — open‑meteo.com/license"
        ),
        DataCitation(
            text: "Τιμές εμπορευμάτων: Παγκόσμια Τράπεζα (World Bank Pink Sheet)",
            url: "https://www.worldbank.org/en/research/commodity-markets",
            license: "CC BY 4.0"
        ),
        DataCitation(
            text: "Γεωργικοί δείκτες: Ευρωπαϊκή Κεντρική Τράπεζα (ECB SDW)",
            url: "https://sdw.ecb.europa.eu",
            license: "Αναπαραγωγή επιτρέπεται με αναφορά πηγής — ecb.europa.eu"
        ),
        DataCitation(
            text: "Γεωργικά νέα: Ευρωπαϊκή Επιτροπή — DG Agriculture",
            url: "https://agriculture.ec.europa.eu",
            license: "© Ευρωπαϊκή Ένωση — reuse permitted with attribution"
        ),
        DataCitation(
            text: "EC Ανακοινώσεις: European Commission Press Corner",
            url: "https://ec.europa.eu/commission/presscorner",
            license: "© Ευρωπαϊκή Ένωση — reuse permitted (Decision 2011/833/EU)"
        ),
        DataCitation(
            text: "Γεωργικά νέα: CAP Reform EU",
            url: "https://www.capreform.eu",
            license: "Ανοιχτή πρόσβαση"
        ),
        DataCitation(
            text: "Γεωργικά νέα: AgriLand.ie — EU Farming News",
            url: "https://www.agriland.ie",
            license: "© AgriLand Media — RSS syndication with attribution"
        ),
        DataCitation(
            text: "Γεωργικά νέα: Euractiv Agriculture & Food",
            url: "https://www.euractiv.com/sections/agriculture-food/",
            license: "© Euractiv — RSS syndication with attribution"
        ),
        DataCitation(
            text: "Γεωργικά νέα: Farming UK",
            url: "https://www.farminguk.com",
            license: "© Farming UK — RSS syndication with attribution"
        ),
        DataCitation(
            text: "Χάρτες: Apple MapKit",
            url: "https://developer.apple.com/maps/",
            license: "Δωρεάν για εμπορική χρήση — developer.apple.com"
        ),
    ]
}
