import SwiftUI

struct ForecastView: View {
    @Environment(WeatherViewModel.self) private var viewModel

    var body: some View {
        Group {
            if viewModel.selectedField == nil {
                emptyState
            } else if viewModel.hourlyForecast.isEmpty {
                loadingState
            } else {
                content
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(.agroGreen.opacity(0.3))
            Text("Επιλέξτε ένα χωράφι")
                .font(.headline).foregroundColor(.secondary)
            Text("Για να δείτε την πρόγνωση καιρού")
                .font(.subheadline).foregroundColor(.secondary.opacity(0.7))
            Spacer()
        }
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            Spacer()
            ProgressView()
            Text("Φόρτωση πρόγνωσης...")
                .font(.subheadline).foregroundColor(.secondary)
            Spacer()
        }
    }

    private var content: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                nextHoursSection
                dailyOverview
                hourlyList
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Next Hours

    private var nextHoursSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "clock.fill", title: "ΕΠΟΜΕΝΕΣ ΩΡΕΣ")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.hourlyForecast.prefix(12)) { hour in
                        hourCell(hour)
                    }
                }
            }
        }
    }

    private func hourCell(_ hour: HourlyForecast) -> some View {
        VStack(spacing: 6) {
            Text(hour.time, style: .time)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)

            Image(systemName: hour.temperature.map { $0 > 20 ? "sun.max.fill" : $0 > 10 ? "cloud.sun.fill" : "cloud.fill" } ?? "cloud.fill")
                .font(.title3)
                .foregroundColor(.agroGreen)

            Text(hour.temperature.map { String(format: "%.0f°", $0) } ?? "—")
                .font(.system(size: 15, weight: .semibold, design: .rounded))

            if let rain = hour.precipitation, rain > 0 {
                Text(String(format: "%.1fmm", rain))
                    .font(.system(size: 9))
                    .foregroundColor(.blue)
            }

            if let wind = hour.windSpeed {
                Image(systemName: "wind")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary.opacity(0.5))
                Text(String(format: "%.0f", wind))
                    .font(.system(size: 9))
                    .foregroundColor(.secondary.opacity(0.7))
            }
        }
        .padding(10)
        .frame(width: 64)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Daily Overview

    private var dailyOverview: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "sun.horizon.fill", title: "ΣΗΜΕΡΙΝΗ ΕΠΙΣΚΟΠΗΣΗ")

            HStack(spacing: 12) {
                dailyStat(icon: "thermometer", label: "Μέγιστη", value: viewModel.maxTemperature.map { String(format: "%.1f°C", $0) } ?? "—", color: .red)
                dailyStat(icon: "thermometer", label: "Ελάχιστη", value: viewModel.minTemperature.map { String(format: "%.1f°C", $0) } ?? "—", color: .blue)
                dailyStat(icon: "drop.fill", label: "Βροχή", value: viewModel.totalPrecipitation.map { String(format: "%.1f mm", $0) } ?? "—", color: .blue)
                dailyStat(icon: "wind", label: "Άνεμος", value: viewModel.maxWindSpeed.map { String(format: "%.0f km/h", $0) } ?? "—", color: .green)
            }
        }
    }

    private func dailyStat(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Hourly List

    private var hourlyList: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "list.bullet", title: "ΑΝΑΛΥΤΙΚΗ ΠΡΟΓΝΩΣΗ")

            VStack(spacing: 0) {
                ForEach(Array(viewModel.hourlyForecast.prefix(24).enumerated()), id: \.element.id) { index, hour in
                    hourRow(hour)
                    if index < 23 {
                        Divider().padding(.leading, 60)
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private func hourRow(_ hour: HourlyForecast) -> some View {
        HStack(spacing: 10) {
            Text(hour.time, style: .time)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 44, alignment: .leading)

            Image(systemName: hour.temperature.map { $0 > 20 ? "sun.max.fill" : $0 > 10 ? "cloud.sun.fill" : "cloud.fill" } ?? "cloud.fill")
                .font(.subheadline)
                .foregroundColor(.agroGreen)
                .frame(width: 20)

            Text(hour.temperature.map { String(format: "%.0f°C", $0) } ?? "—")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .frame(width: 44)

            if let precip = hour.precipitation, precip > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.blue)
                    Text(String(format: "%.1f", precip))
                        .font(.system(size: 11))
                        .foregroundColor(.blue)
                }
                .frame(width: 40)
            } else {
                Text("—")
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.4))
                    .frame(width: 40)
            }

            if let wind = hour.windSpeed {
                HStack(spacing: 2) {
                    Image(systemName: "wind")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                    Text(String(format: "%.0f", wind))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .frame(width: 36)
            } else {
                Text("—")
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.4))
                    .frame(width: 36)
            }

            if let humidity = hour.humidity {
                Text("\(Int(humidity))%")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .frame(width: 32)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.caption).foregroundColor(.secondary)
            Text(title).font(.caption.weight(.semibold)).foregroundColor(.secondary).tracking(1)
        }
        .padding(.leading, 4)
    }
}
