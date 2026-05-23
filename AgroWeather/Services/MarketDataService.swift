import Foundation

actor MarketDataService {
    static let shared = MarketDataService()
    private let defaults = UserDefaults.standard
    private let cachePrefix = "fred_cache_"
    private let cacheDuration: TimeInterval = 86400 // 24 hours

    // FRED API — Federal Reserve Economic Data
    // Ο χρήστης μπορεί να βάλει το δικό του API key στο Config.plist ή στο Settings
    // Δωρεάν API key: https://fred.stlouisfed.org/docs/api/api_key.html
    private var fredKey: String {
        // Πρώτα έλεγξε αν ο χρήστης έχει βάλει key από την εφαρμογή
        if let userKey = defaults.string(forKey: "user_fred_api_key"), !userKey.isEmpty {
            return userKey
        }
        // Αλλιώς διάβασε από Config.plist
        if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path),
           let key = dict["FRED_API_KEY"] as? String, !key.isEmpty {
            return key
        }
        return ""
    }
    private let fredBase = "https://api.stlouisfed.org/fred/series/observations"

    // ECB Statistical Data Warehouse API
    private let ecbBase = "https://data-api.ecb.europa.eu/service/data"

    func fetchCommodityPrices() async throws -> [MarketPrice] {
        if let cached = loadCachedPrices() { return cached }

        let series: [(String, String, String)] = [
            ("PWHEAMTUSDM", "Σιτάρι", "$/μετρ. τόνο"),
            ("PCORNUSDM", "Καλαμπόκι", "$/μετρ. τόνο"),
            ("PRICENJSADM", "Ρύζι", "$/μετρ. τόνο"),
            ("PSOYBUSDQ", "Σόγια", "$/μετρ. τόνο"),
            ("PSUGAISAPM", "Ζάχαρη", "¢/lb"),
            ("PCOFFOTMUSDM", "Καφές", "¢/lb"),
            ("PCOCOACTRM", "Κακάο", "$/μετρ. τόνο"),
            ("PCOTTINDUSDM", "Βαμβάκι", "¢/lb"),
            ("PRUBBUSDM", "Καουτσούκ", "¢/lb"),
            ("PBEEFUSDM", "Βοδινό", "¢/lb"),
            ("PPOULTRUSDM", "Κοτόπουλο", "¢/lb"),
            ("PFISHUSDM", "Ψάρια", "$/μετρ. τόνο"),
            ("PLOGOREUSDM", "Ξυλεία", "$/m³"),
            ("PWOODCUSDM", "Ξυλεία (μαλακή)", "$/m³"),
            ("PBANABMLM", "Μπανάνες", "$/μετρ. τόνο"),
            ("PORANGBUSDM", "Πορτοκάλια", "$/μετρ. τόνο"),
            ("PALMPOILUSDM", "Φοινικέλαιο", "$/μετρ. τόνο"),
            ("POLVOILUSDM", "Ελαιόλαδο", "$/μετρ. τόνο"),
            ("PSUNOILUSDM", "Ηλιέλαιο", "$/μετρ. τόνο"),
        ]

        var prices: [MarketPrice] = []
        try await withThrowingTaskGroup(of: MarketPrice?.self) { group in
            for (id, name, unit) in series {
                group.addTask {
                    return await self.fetchSingleCommodity(id: id, name: name, unit: unit)
                }
            }
            for try await result in group {
                if let p = result { prices.append(p) }
            }
        }
        saveCachedPrices(prices)
        return prices
    }

    private func fetchSingleCommodity(id: String, name: String, unit: String) async -> MarketPrice? {
        // Check per-commodity cache
        let cacheKey = cachePrefix + id
        if let cached = loadCachedCommodity(key: cacheKey) { return cached }

        let url = "\(fredBase)?series_id=\(id)&api_key=\(fredKey)&file_type=json&sort_order=desc&limit=2"
        guard let parsedURL = URL(string: url) else { return nil }
        var request = URLRequest(url: parsedURL)
        request.timeoutInterval = 8

        guard let (data, _) = try? await URLSession.shared.data(for: request) else { return nil }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let obs = json["observations"] as? [[String: Any]],
              let latest = obs.first,
              let valueStr = latest["value"] as? String,
              valueStr != ".",
              let value = Double(valueStr),
              let date = latest["date"] as? String else { return nil }

        let price = MarketPrice(name: name, code: id, value: value, date: date, unit: unit, source: .fred)
        saveCachedCommodity(price, key: cacheKey)
        return price
    }

    // MARK: - 24h Cache

    private func loadCachedPrices() -> [MarketPrice]? {
        guard let data = defaults.data(forKey: cachePrefix + "all"),
              let cached = try? JSONDecoder().decode(CachedPrices.self, from: data),
              Date().timeIntervalSince(cached.timestamp) < cacheDuration else { return nil }
        return cached.prices
    }

    private func saveCachedPrices(_ prices: [MarketPrice]) {
        guard let data = try? JSONEncoder().encode(CachedPrices(prices: prices, timestamp: Date())) else { return }
        defaults.set(data, forKey: cachePrefix + "all")
    }

    private func loadCachedCommodity(key: String) -> MarketPrice? {
        guard let data = defaults.data(forKey: key),
              let cached = try? JSONDecoder().decode(CachedPrice.self, from: data),
              Date().timeIntervalSince(cached.timestamp) < cacheDuration else { return nil }
        return cached.price
    }

    private func saveCachedCommodity(_ price: MarketPrice, key: String) {
        guard let data = try? JSONEncoder().encode(CachedPrice(price: price, timestamp: Date())) else { return }
        defaults.set(data, forKey: key)
    }

    func fetchHistoricalData(seriesId: String) async throws -> [FREDHistoricalPoint] {
        let url = "\(fredBase)?series_id=\(seriesId)&api_key=\(fredKey)&file_type=json&sort_order=desc&limit=120"
        guard let parsedURL = URL(string: url) else { return [] }
        var request = URLRequest(url: parsedURL)
        request.timeoutInterval = 10

        let (data, _) = try await URLSession.shared.data(for: request)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let obs = json["observations"] as? [[String: Any]] else { return [] }

        var points: [FREDHistoricalPoint] = []
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"

        for entry in obs {
            guard let valueStr = entry["value"] as? String,
                  valueStr != ".",
                  let value = Double(valueStr),
                  let dateStr = entry["date"] as? String,
                  let date = f.date(from: dateStr) else { continue }
            points.append(FREDHistoricalPoint(date: date, value: value))
        }
        return points.sorted { $0.date < $1.date }
    }

    func fetchECBData() async throws -> [MarketPrice] {
        let series = [
            ("AP.M.U2.N.T000.4.A", "Γενικός Δείκτης Γεωργίας (ΕΕ)"),
            ("AP.C.U2.N.T000.4.A", "Δείκτης Φυτικής Παραγωγής (ΕΕ)"),
            ("AP.H.U2.N.T000.4.A", "Δείκτης Ζωικής Παραγωγής (ΕΕ)"),
        ]

        var prices: [MarketPrice] = []
        for (code, name) in series {
            let url = "\(ecbBase)/\(code)?format=jsondata&startPeriod=2024"
            guard let parsedURL = URL(string: url) else { continue }
            var request = URLRequest(url: parsedURL)
            request.timeoutInterval = 10

            guard let (data, _) = try? await URLSession.shared.data(for: request) else { continue }
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let dataSets = json["dataSets"] as? [[String: Any]],
                  let seriesData = dataSets.first?["series"] as? [String: Any],
                  let firstSeries = seriesData.values.first as? [String: Any],
                  let observations = firstSeries["observations"] as? [String: [Double]],
                  let firstObs = observations.values.first,
                  let value = firstObs.first else { continue }

            prices.append(MarketPrice(name: name, code: code, value: value, date: "2024", unit: "Δείκτης 2015=100", source: .ecb))
        }
        return prices
    }
}

// MARK: - Model

enum MarketDataSource: String, Codable {
    case fred = "FRED"
    case ecb = "ΕΚΤ"

    var citation: String {
        switch self {
        case .fred: return "Πηγή: FRED, Federal Reserve Bank of St. Louis — fred.stlouisfed.org • Open access"
        case .ecb: return "Πηγή: Ευρωπαϊκή Κεντρική Τράπεζα (ECB SDW) — ecb.europa.eu • Αναπαραγωγή με αναφορά πηγής"
        }
    }
}

struct MarketPrice: Identifiable, Codable {
    var id = UUID()
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

struct FREDHistoricalPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

// MARK: - Cache Models

struct CachedPrices: Codable {
    let prices: [MarketPrice]
    let timestamp: Date
}

struct CachedPrice: Codable {
    let price: MarketPrice
    let timestamp: Date
}

struct DataCitation {
    let text: String
    let url: String
    let license: String

    static let all: [DataCitation] = [
        DataCitation(text: "Αγρομετεωρολογικά δεδομένα: Open‑Meteo Agrometeorology API", url: "https://open-meteo.com", license: "Δωρεάν για εμπορική χρήση — open‑meteo.com/license"),
        DataCitation(text: "Τιμές εμπορευμάτων: FRED (Federal Reserve Bank of St. Louis)", url: "https://fred.stlouisfed.org", license: "Open access — fred.stlouisfed.org"),
        DataCitation(text: "Γεωργικοί δείκτες: Ευρωπαϊκή Κεντρική Τράπεζα (ECB SDW)", url: "https://sdw.ecb.europa.eu", license: "Αναπαραγωγή με αναφορά πηγής — ecb.europa.eu"),
        DataCitation(text: "Γεωργικά νέα: CAP Reform EU", url: "https://www.capreform.eu", license: "Ανοιχτή πρόσβαση"),
        DataCitation(text: "Χάρτες: Apple MapKit", url: "https://developer.apple.com/maps/", license: "Δωρεάν για εμπορική χρήση — developer.apple.com"),
    ]
}
