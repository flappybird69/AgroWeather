import Foundation

actor WeatherService {
    static let shared = WeatherService()
    private let baseURL = "https://api.open-meteo.com/v1/forecast"

    func fetchWeather(latitude: Double, longitude: Double) async throws -> WeatherResponse {
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(format: "%.4f", latitude)),
            URLQueryItem(name: "longitude", value: String(format: "%.4f", longitude)),
            URLQueryItem(name: "hourly", value: [
                "soil_temperature_0_to_7cm",
                "soil_moisture_0_to_7cm",
                "et0_fao_evapotranspiration",
                "vapor_pressure_deficit",
                "temperature_2m",
                "relative_humidity_2m",
                "precipitation",
                "rain",
                "wind_speed_10m",
                "wind_gusts_10m",
                "surface_pressure",
                "dewpoint_2m",
                "shortwave_radiation",
                "cloud_cover",
            ].joined(separator: ",")),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: "3"),
        ]

        guard let url = components.url else {
            throw WeatherError.invalidURL
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WeatherError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw WeatherError.httpError(httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode(WeatherResponse.self, from: data)
        } catch {
            throw WeatherError.decodingError
        }
    }
}

enum WeatherError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Σφάλμα σύνδεσης"
        case .invalidResponse: return "Αποτυχία σύνδεσης με τον διακομιστή"
        case .httpError(let code): return "Σφάλμα διακομιστή (\(code))"
        case .decodingError: return "Σφάλμα ανάγνωσης δεδομένων"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .httpError: return "Δοκιμάστε ξανά σε λίγα λεπτά"
        default: return "Τραβήξτε για ανανέωση"
        }
    }
}
