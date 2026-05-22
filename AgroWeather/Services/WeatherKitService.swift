import Foundation

struct LocalWeather {
    let temperature: Double
    let condition: String
    let symbolName: String
    let feelsLike: Double
    let humidity: Double
    let windSpeed: Double
    let highToday: Double
    let lowToday: Double
}

extension WeatherData {
    var localWeather: LocalWeather {
        let temp = current.temperature ?? current.soilTemperature
        let feels = current.dewpoint ?? temp
        return LocalWeather(
            temperature: temp,
            condition: conditionLabel,
            symbolName: conditionSymbol,
            feelsLike: feels,
            humidity: current.humidity ?? 50,
            windSpeed: current.windSpeed ?? 0,
            highToday: maxTemperature,
            lowToday: minTemperature
        )
    }

    private var conditionLabel: String {
        let rain = current.precipitation ?? 0
        let humidity = current.humidity ?? 50
        let cloud = current.cloudCover ?? 0
        let temp = current.temperature ?? current.soilTemperature

        if rain > 1 { return "Βροχερός" }
        if rain > 0.1 { return "Ασθενής βροχή" }
        if cloud > 80 { return "Συννεφιά" }
        if cloud > 50 { return "Μερική συννεφιά" }
        if temp > 30 { return "Ηλιοφάνεια" }
        if temp > 20 { return "Καθαρός" }
        if humidity > 75 { return "Υγρός" }
        return "Αίθριος"
    }

    private var conditionSymbol: String {
        let rain = current.precipitation ?? 0
        let cloud = current.cloudCover ?? 0
        let temp = current.temperature ?? current.soilTemperature

        if rain > 1 { return "cloud.rain.fill" }
        if rain > 0.1 { return "cloud.drizzle.fill" }
        if cloud > 80 { return "cloud.fill" }
        if cloud > 50 { return "cloud.sun.fill" }
        if temp > 30 { return "sun.max.fill" }
        return "sun.max.fill"
    }
}
