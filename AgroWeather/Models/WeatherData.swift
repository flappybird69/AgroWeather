import Foundation

struct WeatherData {
    let current: HourlyForecast
    let hourlyForecast: [HourlyForecast]
    let lastUpdated: Date

    var currentSoilMoisturePercent: Int {
        min(100, max(0, Int(current.soilMoisture * 100)))
    }

    var currentVpdRisk: VPDRiskLevel {
        VPDRiskLevel(vpd: current.vaporPressureDeficit)
    }

    var hasFrostRisk: Bool {
        hourlyForecast.contains { $0.soilTemperature < 2.0 }
    }

    var frostRiskHours: [HourlyForecast] {
        hourlyForecast.filter { $0.soilTemperature < 2.0 }
    }

    var lowestSoilTemperature: Double {
        hourlyForecast.map(\.soilTemperature).min() ?? current.soilTemperature
    }

    var totalDailyET0: Double {
        hourlyForecast.prefix(24).reduce(0) { $0 + $1.evapotranspiration }
    }

    var maxTemperature: Double {
        hourlyForecast.prefix(24).compactMap(\.temperature).max() ?? current.temperature ?? 0
    }

    var minTemperature: Double {
        hourlyForecast.prefix(24).compactMap(\.temperature).min() ?? current.temperature ?? 0
    }

    var totalPrecipitation: Double {
        hourlyForecast.prefix(24).compactMap(\.precipitation).reduce(0, +)
    }

    var maxWindSpeed: Double {
        hourlyForecast.prefix(24).compactMap(\.windSpeed).max() ?? current.windSpeed ?? 0
    }
}

struct HourlyForecast: Identifiable {
    let id = UUID()
    let time: Date
    let soilTemperature: Double
    let soilMoisture: Double
    let evapotranspiration: Double
    let vaporPressureDeficit: Double
    let temperature: Double?
    let humidity: Double?
    let precipitation: Double?
    let rain: Double?
    let windSpeed: Double?
    let windGusts: Double?
    let pressure: Double?
    let dewpoint: Double?
    let radiation: Double?
    let cloudCover: Double?
}

enum VPDRiskLevel: String, CaseIterable {
    case low = "Χαμηλός"
    case moderate = "Μέτριος"
    case high = "Υψηλός"
    case extreme = "Ακραίος"

    var description: String {
        switch self {
        case .low: return "Ιδανικές συνθήκες για τα φυτά"
        case .moderate: return "Παρακολουθήστε την υγρασία"
        case .high: return "Αυξημένη καταπόνηση φυτών"
        case .extreme: return "Άμεσος κίνδυνος για τα φυτά"
        }
    }

    init(vpd: Double) {
        switch vpd {
        case ..<0.6: self = .low
        case ..<1.0: self = .moderate
        case ..<1.6: self = .high
        default: self = .extreme
        }
    }
}

extension WeatherResponse {
    func toWeatherData() -> WeatherData? {
        guard !hourly.time.isEmpty else { return nil }

        let fallbackFormatter = DateFormatter()
        fallbackFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"

        let forecasts: [HourlyForecast] = hourly.time.enumerated().compactMap { index, timeString in
            guard let date = fallbackFormatter.date(from: timeString) else { return nil }
            return HourlyForecast(
                time: date,
                soilTemperature: hourly.soilTemperature[index] ?? 0,
                soilMoisture: hourly.soilMoisture[index] ?? 0,
                evapotranspiration: hourly.evapotranspiration[index] ?? 0,
                vaporPressureDeficit: hourly.vaporPressureDeficit[index] ?? 0,
                temperature: hourly.temperature[index],
                humidity: hourly.humidity[index],
                precipitation: hourly.precipitation[index],
                rain: hourly.rain[index],
                windSpeed: hourly.windSpeed[index],
                windGusts: hourly.windGusts[index],
                pressure: hourly.pressure[index],
                dewpoint: hourly.dewpoint[index],
                radiation: hourly.radiation[index],
                cloudCover: hourly.cloudCover[index]
            )
        }

        guard !forecasts.isEmpty else { return nil }

        let now = Date()
        let closest = forecasts.min(by: { abs($0.time.timeIntervalSince(now)) < abs($1.time.timeIntervalSince(now)) })!
        let current = forecasts.first(where: { $0.time == closest.time }) ?? forecasts[0]

        return WeatherData(
            current: current,
            hourlyForecast: Array(forecasts.prefix(72)),
            lastUpdated: Date()
        )
    }
}
