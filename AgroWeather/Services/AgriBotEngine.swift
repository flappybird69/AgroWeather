import Foundation
import NaturalLanguage

actor AgriBotEngine {
    static let shared = AgriBotEngine()
    private let knowledgeBase = KnowledgeBase.shared

    // MARK: - Public API

    func process(question: String, weather: WeatherData?) async -> BotResponse {
        let tokens = tokenize(question)
        let variables = extractWeatherValues(from: question, weather: weather)
        let matchedRules = knowledgeBase.matchRules(for: tokens)

        if matchedRules.isEmpty {
            return BotResponse(
                text: "Μπορώ να σε βοηθήσω με συμβουλές για:\n\n🌱 Φύτευση — Πότε να φυτέψεις ελιές, αμπέλια, εσπεριδοειδή\n💧 Άρδευση — Πότε και πόσο να ποτίσεις\n🧪 Ψεκασμό — Κατάλληλες συνθήκες για ψεκασμό\n❄️ Παγετό — Προστασία από παγετό\n🌾 Συγκομιδή — Πότε να μαζέψεις\n📋 Γενικές συμβουλές για το χωράφι σου\n\nΤι σε ενδιαφέρει;",
                category: .general,
                isQuestion: true
            )
        }

        let bestRule = matchedRules.first!
        let conditionsMet = evaluateConditions(bestRule.conditions, with: variables, weather: weather)
        let overallScore = calculateScore(bestRule.conditions, with: variables, weather: weather)

        let responseText: String
        let adjustedDetail: String

        if overallScore >= 0.7 {
            responseText = bestRule.responseGood
            adjustedDetail = buildDetailString(from: variables, weather: weather, positive: true)
        } else if overallScore >= 0.35 {
            responseText = bestRule.responseNeutral
            adjustedDetail = buildDetailString(from: variables, weather: weather, positive: false)
        } else {
            responseText = bestRule.responseBad
            adjustedDetail = buildDetailString(from: variables, weather: weather, positive: false)
        }

        let detail = conditionsMet.isEmpty
            ? ""
            : "\n\n📊 Δεδομένα που έλεγξα:\n" + adjustedDetail

        let fullResponse = responseText + detail

        return BotResponse(
            text: fullResponse,
            category: bestRule.category,
            isQuestion: false
        )
    }

    // MARK: - Tokenization

    private func tokenize(_ text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        var tokens: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let token = String(text[range])
            if token.count > 1 {
                tokens.append(token.lowercased())
            }
            return true
        }
        return tokens
    }

    // MARK: - Weather Value Extraction from Text

    private func extractWeatherValues(from text: String, weather: WeatherData?) -> [WeatherVariable: Double] {
        var values: [WeatherVariable: Double] = [:]
        guard let weather else { return values }

        values[.soilMoisture] = Double(weather.currentSoilMoisturePercent)
        values[.soilTemperature] = weather.current.soilTemperature
        values[.airTemperature] = weather.current.temperature
        values[.humidity] = weather.current.humidity
        values[.windSpeed] = weather.current.windSpeed
        values[.precipitation] = weather.current.precipitation
        values[.vpd] = weather.current.vaporPressureDeficit
        values[.evapotranspiration] = weather.current.evapotranspiration
        values[.dewpoint] = weather.current.dewpoint
        values[.radiation] = weather.current.radiation
        values[.pressure] = weather.current.pressure

        return values
    }

    // MARK: - Condition Evaluation

    private func evaluateConditions(_ conditions: [RuleCondition], with variables: [WeatherVariable: Double], weather: WeatherData?) -> [String] {
        var met: [String] = []
        for condition in conditions {
            guard let value = variables[condition.variable] else { continue }
            let label = variableLabel(condition.variable)
            if let min = condition.min, value < min {
                met.append("\(label): \(formatValue(condition.variable, value)) — πολύ χαμηλό (χρειάζεται ≥ \(formatValue(condition.variable, min)))")
            } else if let max = condition.max, value > max {
                met.append("\(label): \(formatValue(condition.variable, value)) — πολύ υψηλό (χρειάζεται ≤ \(formatValue(condition.variable, max)))")
            }
        }
        return met
    }

    private func calculateScore(_ conditions: [RuleCondition], with variables: [WeatherVariable: Double], weather: WeatherData?) -> Double {
        guard !conditions.isEmpty else { return 0.5 }

        var totalWeight = 0
        var metWeight = 0

        for condition in conditions {
            guard let value = variables[condition.variable] else { continue }
            totalWeight += condition.weight

            let minMet = condition.min.map { value >= $0 } ?? true
            let maxMet = condition.max.map { value <= $0 } ?? true

            if minMet && maxMet { metWeight += condition.weight }
        }

        guard totalWeight > 0 else { return 0.5 }
        return Double(metWeight) / Double(totalWeight)
    }

    // MARK: - Formatting

    private func buildDetailString(from variables: [WeatherVariable: Double], weather: WeatherData?, positive: Bool) -> String {
        var parts: [String] = []
        for (variable, value) in variables {
            guard let _ = weather else { continue }
            parts.append("• \(variableLabel(variable)): \(formatValue(variable, value))")
        }
        return parts.joined(separator: "\n")
    }

    private func variableLabel(_ variable: WeatherVariable) -> String {
        switch variable {
        case .soilMoisture: return "Υγρασία εδάφους"
        case .soilTemperature: return "Θερμοκρασία εδάφους"
        case .airTemperature: return "Θερμοκρασία αέρα"
        case .humidity: return "Υγρασία αέρα"
        case .windSpeed: return "Ταχύτητα ανέμου"
        case .precipitation: return "Βροχόπτωση"
        case .vpd: return "VPD (Έλλειμμα πίεσης)"
        case .evapotranspiration: return "Εξατμισοδιαπνοή (ET₀)"
        case .dewpoint: return "Σημείο δρόσου"
        case .radiation: return "Ηλιακή ακτινοβολία"
        case .pressure: return "Ατμοσφαιρική πίεση"
        }
    }

    private func formatValue(_ variable: WeatherVariable, _ value: Double) -> String {
        switch variable {
        case .soilMoisture: return "\(Int(value))%"
        case .soilTemperature: return String(format: "%.1f°C", value)
        case .airTemperature: return String(format: "%.1f°C", value)
        case .humidity: return "\(Int(value))%"
        case .windSpeed: return String(format: "%.0f km/h", value)
        case .precipitation: return String(format: "%.1f mm", value)
        case .vpd: return String(format: "%.2f kPa", value)
        case .evapotranspiration: return String(format: "%.2f mm", value)
        case .dewpoint: return String(format: "%.1f°C", value)
        case .radiation: return String(format: "%.0f W/m²", value)
        case .pressure: return String(format: "%.1f hPa", value / 100)
        }
    }
}

// MARK: - Response Model

struct BotResponse: Identifiable {
    let id = UUID()
    let text: String
    let category: RuleCategory
    let isQuestion: Bool
}
