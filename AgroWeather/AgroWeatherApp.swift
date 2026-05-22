import SwiftUI

@main
struct AgroWeatherApp: App {
    @State private var viewModel = WeatherViewModel()
    @AppStorage("appearance_mode") private var appearanceMode: AppearanceMode = .system

    var body: some Scene {
        WindowGroup {
            SplashScreen()
                .environment(viewModel)
                .preferredColorScheme(appearanceMode == .system ? nil :
                                        appearanceMode == .dark ? .dark : .light)
        }
    }
}
