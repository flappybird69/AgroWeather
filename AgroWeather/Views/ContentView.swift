import SwiftUI

struct ContentView: View {
    @Environment(WeatherViewModel.self) private var viewModel
    @State private var showAddField = false
    @State private var showSettings = false
    @AppStorage("appearance_mode") private var appearanceMode: AppearanceMode = .system

    var body: some View {
        TabView {
            NavigationStack {
                DashboardView()
                    .navigationTitle(viewModel.selectedField?.name ?? "AgroWeather")
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            HStack(spacing: 4) {
                                Button {
                                    showSettings = true
                                } label: {
                                    Image(systemName: "gearshape.fill")
                                        .font(.title3)
                                        .foregroundColor(.secondary)
                                }
                                Button {
                                    showAddField = true
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(.agroGreen)
                                        .symbolRenderingMode(.hierarchical)
                                }
                            }
                        }
                    }
                    .toolbarBackground(.hidden, for: .navigationBar)
            }
            .tabItem { Label("Κεντρική", systemImage: "house.fill") }

            NavigationStack {
                ForecastView()
                    .navigationTitle("Πρόγνωση")
                    .navigationBarTitleDisplayMode(.large)
                    .toolbarBackground(.hidden, for: .navigationBar)
            }
            .tabItem { Label("Πρόγνωση", systemImage: "chart.line.uptrend.xyaxis") }

            NavigationStack {
                FarmLogView()
                    .navigationTitle("Ημερολόγιο")
                    .navigationBarTitleDisplayMode(.large)
                    .toolbarBackground(.hidden, for: .navigationBar)
            }
            .tabItem { Label("Ημερολόγιο", systemImage: "book.fill") }

            NavigationStack {
                AgriBotView()
                    .navigationTitle("Κύριος Στάθης")
                    .navigationBarTitleDisplayMode(.large)
                    .toolbarBackground(.hidden, for: .navigationBar)
            }
            .tabItem { Label("Κύριος Στάθης", systemImage: "leaf.arrow.triangle.circlepath") }

            NavigationStack {
                NewsListView()
                    .navigationTitle("Νέα & Προγράμματα")
                    .navigationBarTitleDisplayMode(.large)
                    .toolbarBackground(.hidden, for: .navigationBar)
            }
            .tabItem { Label("Νέα", systemImage: "newspaper.fill") }
        }
        .tint(.agroGreen)
        .sheet(isPresented: $showAddField) {
            AddFieldView()
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView()
            }
        }
    }
}
