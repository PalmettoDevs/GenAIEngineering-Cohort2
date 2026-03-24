import SwiftUI

struct HistoryItemView: View {
    let item: HistoryItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                Text(item.original)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                Divider()

                Text(item.translated)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text("\(item.sourceName) → \(item.targetName)")
                    .font(.caption2)
                    .foregroundStyle(.tint)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.quaternary.opacity(0.5))
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HistoryItemView(
        item: HistoryItem(
            original: "Hello, how are you?",
            translated: "Hola, ¿cómo estás?",
            sourceLang: "en",
            targetLang: "es"
        ),
        onTap: {}
    )
    .padding()
}
