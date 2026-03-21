import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: TranslatorViewModel
    @State private var showSourceLanguagePicker = false
    @State private var showTargetLanguagePicker = false
    @State private var showCopiedToast = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 16) {
                        languageSelectorRow
                        sourceCard
                        targetCard
                        historySection
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100) // Space for FAB
                }

                microphoneButton
            }
            .navigationTitle("Universal Translator")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await viewModel.requestPermissions()
            }
            .overlay {
                if showCopiedToast {
                    copiedToast
                }
            }
            .sheet(isPresented: $showSourceLanguagePicker) {
                LanguagePickerView(
                    title: "Listen for",
                    selectedLanguage: $viewModel.sourceLanguage,
                    showAutoDetect: true
                )
            }
            .sheet(isPresented: $showTargetLanguagePicker) {
                LanguagePickerView(
                    title: "Translate to",
                    selectedLanguage: $viewModel.targetLanguage,
                    showAutoDetect: false
                )
            }
        }
    }

    // MARK: - Language Selector Row

    private var languageSelectorRow: some View {
        HStack(spacing: 8) {
            Button {
                showSourceLanguagePicker = true
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text("FROM")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(viewModel.sourceLanguage.displayName)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)

            Button {
                withAnimation(.spring(duration: 0.3)) {
                    viewModel.swapLanguages()
                }
            } label: {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.tint)
                    .frame(width: 40, height: 40)
                    .background(.tint.opacity(0.12), in: Circle())
            }

            Button {
                showTargetLanguagePicker = true
            } label: {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("TO")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(viewModel.targetLanguage.displayName)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Source Card

    private var sourceCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Original", systemImage: "text.quote")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Spacer()

                if let detected = viewModel.detectedLanguageName {
                    Text("Detected: \(detected)")
                        .font(.caption)
                        .foregroundStyle(.tint)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.tint.opacity(0.1), in: Capsule())
                }
            }

            if viewModel.isListening {
                Text(viewModel.sourceText.isEmpty ? "Listening..." : viewModel.sourceText)
                    .font(.body)
                    .foregroundStyle(viewModel.sourceText.isEmpty ? .secondary : .primary)
                    .frame(maxWidth: .infinity, minHeight: 80, alignment: .topLeading)
            } else {
                TextField("Type or tap the mic to speak...", text: $viewModel.sourceText, axis: .vertical)
                    .font(.body)
                    .lineLimit(3...8)
                    .frame(minHeight: 80, alignment: .topLeading)
            }

            HStack {
                Spacer()
                Button("Clear", systemImage: "xmark.circle") {
                    viewModel.clearAll()
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
                .shadow(color: .primary.opacity(0.08), radius: 4, y: 2)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.quaternary, lineWidth: 1)
        }
    }

    // MARK: - Target Card

    private var targetCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Translation", systemImage: "globe")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Spacer()

                if viewModel.isTranslating {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            Text(viewModel.translatedText.isEmpty ? "Translation will appear here..." : viewModel.translatedText)
                .font(.body)
                .foregroundStyle(viewModel.translatedText.isEmpty ? .secondary : .primary)
                .frame(maxWidth: .infinity, minHeight: 80, alignment: .topLeading)
                .textSelection(.enabled)

            HStack {
                Spacer()

                Button {
                    viewModel.speakTranslation()
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.body)
                }
                .disabled(viewModel.translatedText.isEmpty)
                .tint(.primary)

                Button {
                    viewModel.copyTranslation()
                    withAnimation { showCopiedToast = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation { showCopiedToast = false }
                    }
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.body)
                }
                .disabled(viewModel.translatedText.isEmpty)
                .tint(.primary)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.accentColor.opacity(0.06))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.accentColor.opacity(0.15), lineWidth: 1)
        }
    }

    // MARK: - Microphone FAB

    private var microphoneButton: some View {
        Button {
            viewModel.toggleListening()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: viewModel.isListening ? "stop.fill" : "mic.fill")
                    .font(.title3)
                Text(viewModel.isListening ? "Stop" : "Tap to Speak")
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background {
                Capsule()
                    .fill(viewModel.isListening ? Color.red : Color.accentColor)
                    .shadow(color: (viewModel.isListening ? Color.red : Color.accentColor).opacity(0.4),
                            radius: viewModel.isListening ? 12 : 6, y: 4)
            }
        }
        .padding(.bottom, 24)
        .animation(.spring(duration: 0.3), value: viewModel.isListening)
        .sensoryFeedback(.impact(weight: .medium), trigger: viewModel.isListening)
    }

    // MARK: - History

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("History", systemImage: "clock.arrow.circlepath")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            if viewModel.history.isEmpty {
                Text("No translations yet")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.history) { item in
                        HistoryItemView(item: item) {
                            viewModel.speakHistoryItem(item)
                        }
                    }
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
                .shadow(color: .primary.opacity(0.05), radius: 2, y: 1)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.quaternary, lineWidth: 1)
        }
    }

    // MARK: - Copied Toast

    private var copiedToast: some View {
        VStack {
            Spacer()
            Text("Copied!")
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThickMaterial, in: Capsule())
                .padding(.bottom, 100)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

#Preview {
    ContentView()
        .environmentObject(TranslatorViewModel())
}
