import SwiftUI

struct DashboardView: View {
    @Environment(WeatherViewModel.self) private var viewModel
    @State private var showAddField = false
    @State private var showSettings = false
    @State private var showFieldManagement = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @AppStorage("appearance_mode") private var appearanceMode: AppearanceMode = .system

    var body: some View {
        Group {
            if viewModel.fields.isEmpty {
                emptyState
            } else {
                content
            }
        }
        .sheet(isPresented: $showAddField) {
            AddFieldView()
                .preferredColorScheme(appearanceMode.colorScheme)
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                ProfileEditView()
            }
            .preferredColorScheme(appearanceMode.colorScheme)
        }
        .sheet(isPresented: $showFieldManagement) {
            NavigationStack {
                FieldManagementView()
            }
            .preferredColorScheme(appearanceMode.colorScheme)
        }
        .alert("Σφάλμα", isPresented: $showAlert) {
            Button("OK", role: .cancel) { viewModel.showError = false }
        } message: {
            Text(alertMessage)
        }
        .onChange(of: viewModel.showError) { _, newValue in
            if newValue {
                alertMessage = viewModel.errorMessage ?? "Άγνωστο σφάλμα"
                showAlert = true
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "tree.fill")
                .font(.system(size: 64))
                .foregroundColor(.agroGreen.opacity(0.4))
            Text("Καλώς ήρθατε στο AgroWeather")
                .font(.title2.weight(.semibold))
            Text("Προσθέστε το πρώτο σας χωράφι\nγια να δείτε τα αγρομετεωρολογικά δεδομένα")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            Button {
                showAddField = true
            } label: {
                Label("Προσθήκη Χωραφιού", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(Color.agroGreen)
                    .clipShape(Capsule())
            }
            Spacer()
        }
        .padding()
    }

    private var content: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                ProfileCard(showSettings: $showSettings)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 10)

                LocalWeatherCard()
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                fieldSelector
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                if viewModel.hasFrostRisk {
                    FrostWarningBanner()
                        .padding(.horizontal, 16)
                        .padding(.bottom, 14)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                premiumCards
                    .padding(.horizontal, 16)

                if viewModel.weatherData != nil {
                    extraInfo
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                }

                if viewModel.showComparison && viewModel.weatherData != nil {
                    FieldComparisonCard()
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .transition(.opacity)
                }

                if let data = viewModel.weatherData {
                    let advisor = FarmingAdvisor(weather: data)
                    AdvisorySection(advisor: advisor)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .transition(.opacity)
                }

                if viewModel.weatherData != nil {
                    IrrigationCalculatorView()
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                }

                ProfitabilityView()
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                if let lastUpdated = viewModel.lastUpdated {
                    Text("Τελευταία ενημέρωση: \(lastUpdated, style: .time)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 16)
                        .padding(.bottom, 24)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .overlay(alignment: .topTrailing) {
            ChatBubble()
                .padding(.trailing, 16)
                .padding(.top, 8)
        }
        .refreshable { await viewModel.refresh() }
        .overlay {
            if viewModel.isLoading && viewModel.weatherData != nil {
                VStack {
                    Spacer()
                    ProgressView()
                        .padding(14)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    Spacer().frame(height: 60)
                }
            }
        }
        .task {
            if viewModel.weatherData == nil {
                await viewModel.fetchAll()
            } else if viewModel.showComparison && viewModel.fieldComparisons.isEmpty {
                await viewModel.loadComparisonData()
            }
        }
    }

    private var fieldSelector: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.fields) { field in
                        Button {
                            viewModel.selectField(field)
                            HapticManager.selection()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: field.id == viewModel.selectedField?.id ? "map.fill" : "map")
                                    .font(.system(size: 10))
                                Text(field.name)
                                    .font(.system(size: 13, weight: .semibold))
                                    .lineLimit(1)
                            }
                            .foregroundColor(field.id == viewModel.selectedField?.id ? .white : .primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(field.id == viewModel.selectedField?.id ? Color.agroGreen : Color(.secondarySystemGroupedBackground))
                            .clipShape(Capsule())
                            .id(field.id)
                        }
                        .contextMenu {
                            Button {
                                showFieldManagement = true
                            } label: {
                                Label("Διαχείριση χωραφιών", systemImage: "gear")
                            }
                        }
                    }

                    if viewModel.canAddMoreFields {
                        Button {
                            showAddField = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.agroGreen)
                                .padding(8)
                                .background(Color.agroGreen.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .onChange(of: viewModel.selectedField?.id) { _, newId in
                withAnimation { proxy.scrollTo(newId, anchor: .center) }
            }
        }
    }

    // MARK: - Premium Cards

    private var premiumCards: some View {
        VStack(spacing: 12) {
            if viewModel.weatherData != nil {
                cardRow(types: [.soilMoisture, .evapotranspiration])
                cardRow(types: [.soilTemperature, .vaporPressureDeficit])
            } else if viewModel.isLoading {
                loadingGrid
            } else if !viewModel.isLoading {
                errorState
            }
        }
    }

    private func cardRow(types: [WeatherCardType]) -> some View {
        HStack(spacing: 12) {
            ForEach(types, id: \.self) { type in
                WeatherCardView(type: type)
            }
        }
        .frame(height: 120)
    }

    private var loadingGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                loadingCard
                loadingCard
            }
            .frame(height: 120)
            HStack(spacing: 12) {
                loadingCard
                loadingCard
            }
            .frame(height: 120)
        }
    }

    private var loadingCard: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.secondarySystemGroupedBackground))
            .overlay(ProgressView().tint(.agroGreen))
    }

    private var errorState: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 40)
            Image(systemName: "cloud.slash.fill")
                .font(.system(size: 44))
                .foregroundColor(.secondary.opacity(0.5))
            Text("Δεν είναι δυνατή η λήψη δεδομένων")
                .font(.headline).foregroundColor(.secondary)
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.subheadline).foregroundColor(.secondary.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            Text("Τραβήξτε προς τα κάτω για ανανέωση")
                .font(.caption).foregroundColor(.secondary.opacity(0.6))
            Spacer().frame(height: 40)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }

    // MARK: - Extra Info

    private var extraInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ΕΠΙΠΛΕΟΝ ΔΕΔΟΜΕΝΑ")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .tracking(1)
                .padding(.leading, 4)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                extraCard(icon: "thermometer", label: "Θερμοκρασία Αέρα",
                          value: viewModel.airTemperature.map { String(format: "%.1f°C", $0) } ?? "—",
                          detail: "\(String(format: "%.1f", viewModel.minTemperature ?? 0))° / \(String(format: "%.1f", viewModel.maxTemperature ?? 0))°")

                extraCard(icon: "humidity.fill", label: "Υγρασία",
                          value: viewModel.airHumidity.map { "\(Int($0))%" } ?? "—",
                          detail: "Σημείο δρόσου: \(viewModel.dewpoint.map { String(format: "%.1f°C", $0) } ?? "—")")

                extraCard(icon: "wind", label: "Άνεμος",
                          value: viewModel.windSpeed.map { String(format: "%.1f km/h", $0) } ?? "—",
                          detail: "Ριπές: \(viewModel.windGusts.map { String(format: "%.1f", $0) } ?? "—") km/h")

                extraCard(icon: "cloud.rain.fill", label: "Βροχόπτωση",
                          value: viewModel.precipitation.map { String(format: "%.1f mm", $0) } ?? "—",
                          detail: "Σύνολο σήμερα: \(viewModel.totalPrecipitation.map { String(format: "%.1f mm", $0) } ?? "—")")

                extraCard(icon: "sun.max.fill", label: "Ηλιακή Ακτινοβολία",
                          value: viewModel.radiation.map { String(format: "%.0f W/m²", $0) } ?? "—",
                          detail: "Νέφωση: \(viewModel.cloudCover.map { "\(Int($0))%" } ?? "—")")

                extraCard(icon: "gauge.medium", label: "Πίεση",
                          value: viewModel.pressure.map { String(format: "%.1f hPa", $0 / 100) } ?? "—",
                          detail: "Επίδραση στον καιρό")
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func extraCard(icon: String, label: String, value: String, detail: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.agroGreen)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body.weight(.semibold))
                Text(detail)
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.7))
                    .lineLimit(1)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

}
