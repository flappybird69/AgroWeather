import Foundation

actor ECPressService {
    static let shared = ECPressService()

    private let base = "https://ec.europa.eu/commission/presscorner/api/search"

    func fetchAgricultureNews(limit: Int = 20) async throws -> [ECPressItem] {
        guard var components = URLComponents(string: base) else { throw ECPressError.invalidURL }
        components.queryItems = [
            URLQueryItem(name: "query", value: "agriculture"),
            URLQueryItem(name: "pagesize", value: "\(limit)"),
            URLQueryItem(name: "language", value: "en")
        ]
        guard let url = components.url else { throw ECPressError.invalidURL }
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw ECPressError.networkError
        }
        return try JSONDecoder().decode(ECPressResponse.self, from: data).docuLanguageListResources
    }
}

enum ECPressError: Error {
    case invalidURL
    case networkError
}

struct ECPressResponse: Codable {
    let totalNumber: Int
    let pageSize: Int
    let pageNumber: Int
    let docuLanguageListResources: [ECPressItem]
}

struct ECPressItem: Identifiable, Codable {
    let ky: Int
    let eventDate: String
    let title: String
    let leadText: String?
    let docutype: ECPressDocType
    let refCode: String

    var id: Int { ky }

    var articleURL: URL? {
        let slug = refCode.replacingOccurrences(of: "/", with: "_")
        return URL(string: "https://ec.europa.eu/commission/presscorner/detail/en/\(slug)")
    }

    var parsedDate: Date? {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: eventDate)
    }
}

struct ECPressDocType: Codable {
    let code: String
    let description: String
}
