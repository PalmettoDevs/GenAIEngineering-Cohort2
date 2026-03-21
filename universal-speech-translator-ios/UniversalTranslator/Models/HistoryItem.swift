import Foundation

struct HistoryItem: Identifiable {
    let id = UUID()
    let original: String
    let translated: String
    let sourceLang: String
    let targetLang: String
    let timestamp = Date()

    var sourceName: String {
        Language.find(byId: sourceLang)?.displayName ?? sourceLang
    }

    var targetName: String {
        Language.find(byId: targetLang)?.displayName ?? targetLang
    }
}
