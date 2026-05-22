import Foundation

struct FarmingAdvisor {
    let weather: WeatherData

    // MARK: - Combined Assessment

    var overallAssessment: Assessment {
        var good = 0
        var bad = 0

        if irrigationAdvice == .needsWater || irrigationAdvice == .critical { bad += 1 }
        else { good += 1 }

        if plantingAdvice == .good { good += 1 }
        else if plantingAdvice == .avoid { bad += 1 }

        if sprayingAdvice == .good { good += 1 }
        else if sprayingAdvice == .avoid { bad += 1 }

        if frostRisk != .none { bad += 1 }
        else if frostRisk == .none { good += 1 }

        if vpdRisk == .extreme || vpdRisk == .high { bad += 1 }
        else { good += 1 }

        let score = Double(good) / Double(good + bad)

        if score >= 0.7 { return .good }
        else if score >= 0.4 { return .caution }
        else { return .bad }
    }

    var overallSummary: String {
        let parts: [String] = [
            irrigationSummary,
            plantingSummary,
            sprayingSummary,
            frostSummary,
        ].compactMap { $0 }
        return parts.joined(separator: " ")
    }

    // MARK: - Irrigation

    enum IrrigationAdvice: String {
        case critical = "Άμεσο πότισμα — κρίσιμο"
        case needsWater = "Χρειάζεται πότισμα"
        case monitor = "Παρακολουθήστε την υγρασία"
        case ok = "Επαρκής υγρασία — όχι πότισμα"
        case tooWet = "Υπερβολική υγρασία — αποφύγετε το πότισμα"
    }

    var irrigationAdvice: IrrigationAdvice {
        let sm = weather.currentSoilMoisturePercent
        let et0 = weather.current.evapotranspiration
        let temp = weather.current.temperature ?? 25
        let wind = weather.current.windSpeed ?? 0

        switch sm {
        case ..<15: return .critical
        case ..<30: return et0 > 0.5 || temp > 30 || wind > 20 ? .critical : .needsWater
        case ..<45: return et0 > 1.0 ? .needsWater : .monitor
        case ..<65: return .ok
        case ..<80: return sm > 70 && et0 < 0.3 ? .tooWet : .ok
        default: return .tooWet
        }
    }

    private var irrigationSummary: String? {
        let sm = weather.currentSoilMoisturePercent
        switch irrigationAdvice {
        case .critical: return "⚠️ Το έδαφος είναι πολύ ξηρό (\(sm)%). Απαιτείται άμεση άρδευση."
        case .needsWater: return "💧 Η υγρασία είναι \(sm)% — προγραμματίστε πότισμα σήμερα."
        case .monitor: return "✅ Η υγρασία (\(sm))% είναι σε καλά επίπεδα. Παρακολουθήστε."
        case .ok: return "✅ Το έδαφος έχει επαρκή υγρασία (\(sm))%. Δεν χρειάζεται πότισμα."
        case .tooWet: return "⚠️ Το έδαφος είναι πολύ υγρό (\(sm))%. Κίνδυνος σήψης ριζών."
        }
    }

    // MARK: - Planting

    enum PlantingAdvice: String {
        case good = "Καλό για φύτευση"
        case fair = "Οριακές συνθήκες"
        case avoid = "Αποφύγετε τη φύτευση"
    }

    var plantingAdvice: PlantingAdvice {
        let soilTemp = weather.current.soilTemperature
        let airTemp = weather.current.temperature ?? soilTemp
        let sm = weather.currentSoilMoisturePercent
        let vpd = weather.current.vaporPressureDeficit

        guard 10...30 ~= soilTemp, 8...35 ~= airTemp else { return .avoid }
        guard 20...70 ~= sm else { return .avoid }
        guard vpd < 1.6 else { return .avoid }
        guard weather.maxTemperature < 38, weather.minTemperature > 2 else { return .avoid }

        if 15...25 ~= soilTemp, 30...60 ~= sm, vpd < 1.0 { return .good }
        return .fair
    }

    private var plantingSummary: String? {
        switch plantingAdvice {
        case .good: return "🌱 Ιδανικές συνθήκες για φύτευση. Η θερμοκρασία εδάφους (\(weather.current.soilTemperature.formattedTemperature())) είναι κατάλληλη."
        case .fair: return "🌱 Οριακές συνθήκες για φύτευση. Ελέγξτε την πρόβλεψη των επόμενων ημερών."
        case .avoid: return "🌱 Μη συνιστάται φύτευση. Ελέγξτε υγρασία εδάφους και θερμοκρασία."
        }
    }

    // MARK: - Spraying

    enum SprayingAdvice: String {
        case good = "Καλό για ψεκασμό"
        case caution = "Προσοχή — μέτριες συνθήκες"
        case avoid = "Αποφύγετε τον ψεκασμό"
    }

    var sprayingAdvice: SprayingAdvice {
        let wind = weather.current.windSpeed ?? 0
        let windGust = weather.current.windGusts ?? 0
        let rain = weather.current.precipitation ?? 0
        let humidity = weather.current.humidity ?? 50
        let temp = weather.current.temperature ?? 20

        guard wind < 15 else { return .avoid }
        guard windGust < 25 else { return .avoid }
        guard rain < 0.5 else { return .avoid }
        guard temp < 30, temp > 5 else { return .avoid }
        guard humidity < 80 else { return .caution }

        if wind < 8, humidity < 65, temp > 10 { return .good }
        return .caution
    }

    private var sprayingSummary: String? {
        switch sprayingAdvice {
        case .good: return "🧪 Ιδανικές συνθήκες για ψεκασμό. Άνεμος \(weather.current.windSpeed.map { String(format: "%.0f km/h", $0) } ?? "—")."
        case .caution: return "🧪 Προσοχή στον ψεκασμό — ελέγξτε άνεμο και υγρασία."
        case .avoid: return "🧪 Αποφύγετε τον ψεκασμό — δυσμενείς συνθήκες."
        }
    }

    // MARK: - Frost

    enum FrostRisk: String {
        case imminent = "Άμεσος κίνδυνος παγετού"
        case watch = "Παρακολουθήστε τον παγετό"
        case none = "Κανένας κίνδυνος παγετού"
    }

    var frostRisk: FrostRisk {
        let lowest = weather.lowestSoilTemperature
        switch lowest {
        case ..<0: return .imminent
        case ..<3: return .watch
        default: return .none
        }
    }

    private var frostSummary: String? {
        guard frostRisk != .none else { return nil }
        if frostRisk == .imminent {
            return "❄️ ΚΙΝΔΥΝΟΣ ΠΑΓΕΤΟΥ! Λάβετε προστατευτικά μέτρα (αντλίες, καλύμματα). Ελάχιστη: \(weather.lowestSoilTemperature.formattedTemperature())."
        }
        return "❄️ Προσοχή σε παγετό τις επόμενες ώρες (\(weather.lowestSoilTemperature.formattedTemperature())."
    }

    // MARK: - VPD / Disease

    var vpdRisk: VPDRiskLevel { weather.currentVpdRisk }

    var diseaseRisk: String {
        let humidity = weather.current.humidity ?? 50
        let temp = weather.current.temperature ?? 20
        let dewpoint = weather.current.dewpoint ?? 0
        let moisture = weather.currentSoilMoisturePercent

        var risks: [String] = []
        if humidity > 85 { risks.append("περονόσπορος") }
        if humidity > 75 && temp > 15 && temp < 25 { risks.append("ωίδιο") }
        if moisture > 75 { risks.append("σήψη ριζών") }
        if dewpoint > 15 && humidity > 80 { risks.append("βοτρύτης") }

        if risks.isEmpty { return "Χαμηλός κίνδυνος ασθενειών" }
        return "⚠️ Κίνδυνος: \(risks.joined(separator: ", ")). Λάβετε προληπτικά μέτρα."
    }
}

enum Assessment: String {
    case good = "Καλό"
    case caution = "Προσοχή"
    case bad = "Δύσκολες Συνθήκες"

    var icon: String {
        switch self {
        case .good: return "checkmark.circle.fill"
        case .caution: return "exclamationmark.circle.fill"
        case .bad: return "xmark.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .good: return "green"
        case .caution: return "yellow"
        case .bad: return "red"
        }
    }
}
