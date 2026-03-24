import SwiftUI

@main
struct UniversalTranslatorApp: App {
    @StateObject private var translatorViewModel = TranslatorViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(translatorViewModel)
                .preferredColorScheme(nil) // Respects system dark/light mode
        }
    }
}
