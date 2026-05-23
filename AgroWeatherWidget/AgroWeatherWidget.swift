import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), soilMoisture: 45, soilTemperature: 23.5, fieldName: "Χωράφι μου")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        let entry = EntryService.loadEntry() ?? SimpleEntry(date: Date(), soilMoisture: 45, soilTemperature: 23.5, fieldName: "Χωράφι μου")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let entry = EntryService.loadEntry() ?? SimpleEntry(date: Date(), soilMoisture: 45, soilTemperature: 23.5, fieldName: "Χωράφι μου")
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(1800)))
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let soilMoisture: Int
    let soilTemperature: Double
    let fieldName: String
}

struct AgroWeatherWidgetEntryView: View {
    var entry: SimpleEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "tree.fill")
                    .font(.caption)
                    .foregroundColor(.green)
                Text("AgroWeather")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.green)
            }

            Spacer()

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(entry.soilMoisture)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                Text("%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(String(format: "%.1f", entry.soilTemperature))
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                Text("°C")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(entry.fieldName)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(12)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct AgroWeatherWidget: Widget {
    let kind: String = "AgroWeatherWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            AgroWeatherWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("AgroWeather")
        .description("Υγρασία και θερμοκρασία εδάφους")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Data Sharing via App Group

struct EntryService {
    private static let suiteName = "group.com.agroweather.app"

    static func saveEntry(moisture: Int, temperature: Double, fieldName: String) {
        let defaults = UserDefaults(suiteName: suiteName)
        defaults?.set(moisture, forKey: "widget_moisture")
        defaults?.set(temperature, forKey: "widget_temperature")
        defaults?.set(fieldName, forKey: "widget_field")
    }

    static func loadEntry() -> SimpleEntry? {
        let defaults = UserDefaults(suiteName: suiteName)
        guard let moisture = defaults?.value(forKey: "widget_moisture") as? Int,
              let temperature = defaults?.value(forKey: "widget_temperature") as? Double else { return nil }
        let field = defaults?.string(forKey: "widget_field") ?? "Χωράφι"
        return SimpleEntry(date: Date(), soilMoisture: moisture, soilTemperature: temperature, fieldName: field)
    }
}
