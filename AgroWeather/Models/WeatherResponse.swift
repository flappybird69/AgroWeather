import Foundation

struct WeatherResponse: Codable {
    let latitude: Double
    let longitude: Double
    let generationtimeMs: Double
    let utcOffsetSeconds: Int
    let timezone: String
    let timezoneAbbreviation: String
    let hourlyUnits: HourlyUnits
    let hourly: HourlyData

    enum CodingKeys: String, CodingKey {
        case latitude, longitude, timezone
        case generationtimeMs = "generationtime_ms"
        case utcOffsetSeconds = "utc_offset_seconds"
        case timezoneAbbreviation = "timezone_abbreviation"
        case hourlyUnits = "hourly_units"
        case hourly
    }
}

struct HourlyUnits: Codable {
    let time: String
    let soilTemperature: String
    let soilMoisture: String
    let evapotranspiration: String
    let vaporPressureDeficit: String
    let temperature: String
    let humidity: String
    let precipitation: String
    let rain: String
    let windSpeed: String
    let windGusts: String
    let pressure: String
    let dewpoint: String
    let radiation: String
    let cloudCover: String

    enum CodingKeys: String, CodingKey {
        case time
        case soilTemperature = "soil_temperature_0_to_7cm"
        case soilMoisture = "soil_moisture_0_to_7cm"
        case evapotranspiration = "et0_fao_evapotranspiration"
        case vaporPressureDeficit = "vapor_pressure_deficit"
        case temperature = "temperature_2m"
        case humidity = "relative_humidity_2m"
        case precipitation
        case rain
        case windSpeed = "wind_speed_10m"
        case windGusts = "wind_gusts_10m"
        case pressure = "surface_pressure"
        case dewpoint = "dewpoint_2m"
        case radiation = "shortwave_radiation"
        case cloudCover = "cloud_cover"
    }
}

struct HourlyData: Codable {
    let time: [String]
    let soilTemperature: [Double?]
    let soilMoisture: [Double?]
    let evapotranspiration: [Double?]
    let vaporPressureDeficit: [Double?]
    let temperature: [Double?]
    let humidity: [Double?]
    let precipitation: [Double?]
    let rain: [Double?]
    let windSpeed: [Double?]
    let windGusts: [Double?]
    let pressure: [Double?]
    let dewpoint: [Double?]
    let radiation: [Double?]
    let cloudCover: [Double?]

    enum CodingKeys: String, CodingKey {
        case time
        case soilTemperature = "soil_temperature_0_to_7cm"
        case soilMoisture = "soil_moisture_0_to_7cm"
        case evapotranspiration = "et0_fao_evapotranspiration"
        case vaporPressureDeficit = "vapor_pressure_deficit"
        case temperature = "temperature_2m"
        case humidity = "relative_humidity_2m"
        case precipitation
        case rain
        case windSpeed = "wind_speed_10m"
        case windGusts = "wind_gusts_10m"
        case pressure = "surface_pressure"
        case dewpoint = "dewpoint_2m"
        case radiation = "shortwave_radiation"
        case cloudCover = "cloud_cover"
    }
}
