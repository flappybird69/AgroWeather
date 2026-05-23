import SwiftUI

struct ContentView: View {
    @Environment(WeatherViewModel.self) private var viewModel
    @State private var selectedTab = 0
    @State private var showAddField = false
    @State private var showSettings = false
    @AppStorage("appearance_mode") private var appearanceMode: AppearanceMode = .system

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                DashboardView()
                    .navigationTitle(viewModel.selectedField?.name ?? "AgroWeather")
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            HStack(spacing: 4) {
                                Button { showSettings = true } label: {
                                    Image(systemName: "gearshape.fill").font(.title3).foregroundColor(.secondary)
                                }
                                Button { showAddField = true } label: {
                                    Image(systemName: "plus.circle.fill").font(.title3).foregroundColor(.agroGreen).symbolRenderingMode(.hierarchical)
                                }
                            }
                        }
                    }
                    .toolbarBackground(.hidden, for: .navigationBar)
            }
            .tabItem { Label("Κεντρική", systemImage: "house.fill") }
            .tag(0)

            NavigationStack {
                ForecastView()
                    .navigationTitle("Πρόγνωση")
                    .navigationBarTitleDisplayMode(.large)
                    .toolbarBackground(.hidden, for: .navigationBar)
            }
            .tabItem { Label("Πρόγνωση", systemImage: "chart.line.uptrend.xyaxis") }
            .tag(1)

            NavigationStack {
                FarmLogView()
                    .navigationTitle("Ημερολόγιο")
                    .navigationBarTitleDisplayMode(.large)
                    .toolbarBackground(.hidden, for: .navigationBar)
            }
            .tabItem { Label("Ημερολόγιο", systemImage: "book.fill") }
            .tag(2)

            NavigationStack {
                FREDChartView()
                    .id(selectedTab == 3)
                    .navigationTitle("Αγορές")
                    .navigationBarTitleDisplayMode(.large)
                    .toolbarBackground(.hidden, for: .navigationBar)
            }
            .tabItem { Label("Αγορές", systemImage: "chart.bar.fill") }
            .tag(3)

            NavigationStack {
                NewsListView()
                    .navigationTitle("Νέα & Προγράμματα")
                    .navigationBarTitleDisplayMode(.large)
                    .toolbarBackground(.hidden, for: .navigationBar)
            }
            .tabItem { Label("Νέα", systemImage: "newspaper.fill") }
            .tag(4)
        }
        .tint(.agroGreen)
        .sheet(isPresented: $showAddField) { AddFieldView().preferredColorScheme(appearanceMode.colorScheme) }
        .sheet(isPresented: $showSettings) { NavigationStack { SettingsView() }.preferredColorScheme(appearanceMode.colorScheme) }
    }
}
