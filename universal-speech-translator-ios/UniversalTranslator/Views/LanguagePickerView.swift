import SwiftUI

struct LanguagePickerView: View {
    let title: String
    @Binding var selectedLanguage: Language
    let showAutoDetect: Bool

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var languages: [Language] {
        var list = Language.all
        if showAutoDetect {
            list.insert(.autoDetect, at: 0)
        }
        if searchText.isEmpty {
            return list
        }
        return list.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List(languages) { language in
                Button {
                    selectedLanguage = language
                    dismiss()
                } label: {
                    HStack {
                        Text(language.displayName)
                            .foregroundStyle(.primary)

                        Spacer()

                        if language.id == selectedLanguage.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search languages")
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    LanguagePickerView(
        title: "Translate to",
        selectedLanguage: .constant(.english),
        showAutoDetect: false
    )
}
