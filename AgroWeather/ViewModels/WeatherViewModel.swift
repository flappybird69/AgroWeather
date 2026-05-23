import Foundation
import Observation
import UIKit

@Observable
final class WeatherViewModel {
    var fields: [Field] = []
    var selectedField: Field?
    var weatherData: WeatherData?
    var isLoading = false
    var errorMessage: String?
    var showError = false
    var isSyncingFromCloud = false
    var fieldComparisons: [FieldComparison] = []
    var isComparisonLoading = false

    private let fieldsKey = "saved_fields"
    private let selectedFieldIdKey = "selected_field_id"
    private let weatherCacheKey = "cached_weather_json"
    private let weatherService = WeatherService.shared
    private let cloudStore = NSUbiquitousKeyValueStore.default
    private let cloudFieldsKey = "icloud_saved_fields"
    private let cloudSelectedKey = "icloud_selected_field_id"
    private let defaults = UserDefaults.standard

    var iCloudSyncEnabled: Bool { defaults.bool(forKey: "icloud_sync_enabled") }
    var remindersEnabled: Bool { defaults.bool(forKey: "reminders_enabled") }

    // MARK: - Core Weather

    var currentSoilMoisture: Double? { weatherData?.current.soilMoisture }
    var currentSoilMoisturePercent: Int { weatherData?.currentSoilMoisturePercent ?? 0 }
    var currentSoilTemperature: Double? { weatherData?.current.soilTemperature }
    var currentEvapotranspiration: Double? { weatherData?.current.evapotranspiration }
    var currentVPD: Double? { weatherData?.current.vaporPressureDeficit }
    var vpdRiskLevel: VPDRiskLevel { weatherData?.currentVpdRisk ?? .low }
    var hasFrostRisk: Bool { weatherData?.hasFrostRisk ?? false }
    var frostRiskHours: [HourlyForecast] { weatherData?.frostRiskHours ?? [] }
    var lowestSoilTemperature: Double? { weatherData?.lowestSoilTemperature }
    var lastUpdated: Date? { weatherData?.lastUpdated }
    var totalDailyET0: Double? { weatherData?.totalDailyET0 }
    var hourlyForecast: [HourlyForecast] { weatherData?.hourlyForecast ?? [] }

    // MARK: - Extra Weather

    var airTemperature: Double? { weatherData?.current.temperature }
    var airHumidity: Double? { weatherData?.current.humidity }
    var precipitation: Double? { weatherData?.current.precipitation }
    var rain: Double? { weatherData?.current.rain }
    var windSpeed: Double? { weatherData?.current.windSpeed }
    var windGusts: Double? { weatherData?.current.windGusts }
    var pressure: Double? { weatherData?.current.pressure }
    var dewpoint: Double? { weatherData?.current.dewpoint }
    var radiation: Double? { weatherData?.current.radiation }
    var cloudCover: Double? { weatherData?.current.cloudCover }
    var maxTemperature: Double? { weatherData?.maxTemperature }
    var minTemperature: Double? { weatherData?.minTemperature }
    var totalPrecipitation: Double? { weatherData?.totalPrecipitation }
    var maxWindSpeed: Double? { weatherData?.maxWindSpeed }

    var showComparison: Bool { fields.count >= 2 }

    init() {
        if defaults.object(forKey: "icloud_sync_enabled") == nil { defaults.set(true, forKey: "icloud_sync_enabled") }
        if defaults.object(forKey: "reminders_enabled") == nil { defaults.set(true, forKey: "reminders_enabled") }
        listenForCloudChanges()
        loadFields()
        loadCachedWeather()
        if iCloudSyncEnabled { syncFromCloud() }
    }

    // MARK: - iCloud Sync

    private func listenForCloudChanges() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(cloudDidChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: cloudStore
        )
    }

    @objc private func cloudDidChange() {
        guard iCloudSyncEnabled else { return }
        syncFromCloud()
    }

    private func syncFromCloud() {
        guard iCloudSyncEnabled, !isSyncingFromCloud else { return }
        isSyncingFromCloud = true
        defer { isSyncingFromCloud = false }

        if fields.isEmpty {
            if let data = cloudStore.data(forKey: cloudFieldsKey),
               let cloudFields = try? JSONDecoder().decode([Field].self, from: data) {
                fields = cloudFields
                saveLocal()
                if let savedId = cloudStore.string(forKey: cloudSelectedKey),
                   let field = fields.first(where: { $0.id.uuidString == savedId }) {
                    selectedField = field
                } else { selectedField = fields.first }
            }
        }
    }

    private func pushToCloud() {
        guard iCloudSyncEnabled, let data = try? JSONEncoder().encode(fields) else { return }
        cloudStore.set(data, forKey: cloudFieldsKey)
        cloudStore.set(selectedField?.id.uuidString, forKey: cloudSelectedKey)
        cloudStore.synchronize()
    }

    // MARK: - Offline Cache

    private func loadCachedWeather() {
        guard let json = defaults.string(forKey: weatherCacheKey),
              let data = json.data(using: .utf8),
              let response = try? JSONDecoder().decode(WeatherResponse.self, from: data) else { return }
        weatherData = response.toWeatherData()
    }

    private func saveWeatherCache() { }

    private func cacheWeatherResponse(_ response: WeatherResponse) {
        guard let data = try? JSONEncoder().encode(response),
              let json = String(data: data, encoding: .utf8) else { return }
        defaults.set(json, forKey: weatherCacheKey)
    }

    // MARK: - Persistence

    func loadFields() {
        guard let data = defaults.data(forKey: fieldsKey) else { return }
        fields = (try? JSONDecoder().decode([Field].self, from: data)) ?? []
        restoreSelection()
    }

    private func restoreSelection() {
        if let savedId = defaults.string(forKey: selectedFieldIdKey),
           let field = fields.first(where: { $0.id.uuidString == savedId }) {
            selectedField = field
        } else { selectedField = fields.first }
    }

    private func saveLocal() {
        guard let data = try? JSONEncoder().encode(fields) else { return }
        defaults.set(data, forKey: fieldsKey)
        defaults.set(selectedField?.id.uuidString, forKey: selectedFieldIdKey)
    }

    private func persist() {
        saveLocal()
        pushToCloud()
    }

    // MARK: - Field CRUD

    func addField(name: String, latitude: Double, longitude: Double) {
        let field = Field(name: name, latitude: latitude, longitude: longitude)
        fields.append(field)
        selectedField = field
        persist()
        HapticManager.success()
        Task { await fetchAll() }
    }

    func deleteField(_ field: Field) {
        fields.removeAll { $0.id == field.id }
        fieldComparisons.removeAll { $0.fieldId == field.id }
        if selectedField?.id == field.id { selectedField = fields.first }
        persist()
        HapticManager.medium()
        if showComparison { Task { await loadComparisonData() } }
    }

    func renameField(_ field: Field, newName: String) {
        guard let idx = fields.firstIndex(where: { $0.id == field.id }) else { return }
        fields[idx].name = newName
        if selectedField?.id == field.id { selectedField = fields[idx] }
        persist()
    }

    func selectField(_ field: Field) {
        selectedField = field
        persist()
        HapticManager.selection()
        Task { await fetchWeather() }
    }

    // MARK: - Weather

    func fetchWeather() async {
        guard let field = selectedField else { return }
        isLoading = true
        errorMessage = nil

        do {
            let response = try await weatherService.fetchWeather(latitude: field.latitude, longitude: field.longitude)
            weatherData = response.toWeatherData()
            cacheWeatherResponse(response)
            if weatherData?.hasFrostRisk == true { HapticManager.frostAlert() }
        } catch let error as WeatherError {
            errorMessage = error.errorDescription
            showError = true
        } catch {
            errorMessage = "Προέκυψε απρόβλεπτο σφάλμα"
            showError = true
        }
        isLoading = false
    }

    @MainActor
    func fetchAll() async {
        await fetchWeather()
        if showComparison { await loadComparisonData() }
    }

    func refresh() async {
        HapticManager.light()
        await fetchAll()
    }

    var canAddMoreFields: Bool { fields.count < 5 }

    // MARK: - Field Comparison

    func loadComparisonData() async {
        guard fields.count >= 2 else { fieldComparisons = []; return }
        isComparisonLoading = true
        var results: [FieldComparison] = []
        for field in fields {
            if let cached = fieldComparisons.first(where: { $0.fieldId == field.id }) {
                results.append(cached); continue
            }
            do {
                let response = try await weatherService.fetchWeather(latitude: field.latitude, longitude: field.longitude)
                if let data = response.toWeatherData() {
                    results.append(FieldComparison(fieldId: field.id, fieldName: field.name, soilMoisturePercent: data.currentSoilMoisturePercent, soilTemperature: data.current.soilTemperature, evapotranspiration: data.current.evapotranspiration, vpd: data.current.vaporPressureDeficit, temperature: data.current.temperature, humidity: data.current.humidity, windSpeed: data.current.windSpeed))
                }
            } catch {
                results.append(FieldComparison(fieldId: field.id, fieldName: field.name, soilMoisturePercent: nil, soilTemperature: nil, evapotranspiration: nil, vpd: nil, temperature: nil, humidity: nil, windSpeed: nil))
            }
        }
        fieldComparisons = results
        isComparisonLoading = false
    }
}

struct FieldComparison: Identifiable {
    let id = UUID()
    let fieldId: UUID
    let fieldName: String
    let soilMoisturePercent: Int?
    let soilTemperature: Double?
    let evapotranspiration: Double?
    let vpd: Double?
    let temperature: Double?
    let humidity: Double?
    let windSpeed: Double?
}
