import SwiftUI

struct LocalWeatherCard: View {
    @Environment(WeatherViewModel.self) private var viewModel

    var body: some View {
        Group {
            if let w = viewModel.weatherData?.localWeather {
                HStack(spacing: 14) {
                    Image(systemName: w.symbolName)
                        .font(.title)
                        .foregroundColor(.agroGreen)
                        .frame(width: 36)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(String(format: "%.0f°C", w.temperature))")
                            .font(.system(size: 22, weight: .bold, design: .rounded))

                        Text(w.condition)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack(spacing: 8) {
                            HStack(spacing: 2) {
                                Image(systemName: "arrow.up").font(.system(size: 7)).foregroundColor(.red)
                                Text("\(String(format: "%.0f°", w.highToday))").font(.system(size: 10))
                            }
                            HStack(spacing: 2) {
                                Image(systemName: "arrow.down").font(.system(size: 7)).foregroundColor(.blue)
                                Text("\(String(format: "%.0f°", w.lowToday))").font(.system(size: 10))
                            }
                            HStack(spacing: 2) {
                                Image(systemName: "drop.fill").font(.system(size: 7)).foregroundColor(.blue)
                                Text("\(Int(w.humidity))%").font(.system(size: 10))
                            }
                            HStack(spacing: 2) {
                                Image(systemName: "wind").font(.system(size: 7)).foregroundColor(.secondary)
                                Text("\(String(format: "%.0f", w.windSpeed)) km/h").font(.system(size: 10))
                            }
                        }
                    }

                    Spacer()
                }
                .padding(12)
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
