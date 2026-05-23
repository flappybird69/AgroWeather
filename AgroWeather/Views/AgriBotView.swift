import SwiftUI

struct AgriBotView: View {
    @Environment(WeatherViewModel.self) private var viewModel
    @State private var messages: [BotMessage] = []
    @State private var inputText = ""
    @State private var isProcessing = false
    @FocusState private var isFocused: Bool

    private let engine = AgriBotEngine.shared

    var body: some View {
        VStack(spacing: 0) {
            if messages.isEmpty {
                welcomeView
            } else {
                chatScrollView
            }
            inputBar
        }
        .background(Color(.systemGroupedBackground))
        .task {
            if viewModel.weatherData == nil, viewModel.selectedField != nil {
                await viewModel.fetchWeather()
            }
        }
        .onChange(of: viewModel.selectedField?.id) { _, _ in
            messages = []
            Task { await viewModel.fetchWeather() }
        }
    }

    private var welcomeView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer().frame(height: 20)

                ZStack {
                    Circle()
                        .fill(Color.agroGreen.opacity(0.08))
                        .frame(width: 100, height: 100)

                    Image(systemName: "leaf.arrow.triangle.circlepath")
                        .font(.system(size: 44))
                        .foregroundColor(.agroGreen)
                        .symbolRenderingMode(.hierarchical)
                }

                Text("Ο άνθρωπός σου στο χωράφι")
                    .font(.title.weight(.bold))
                    .multilineTextAlignment(.center)

                if let field = viewModel.selectedField {
                    HStack(spacing: 4) {
                        Image(systemName: "map.fill")
                            .font(.caption)
                            .foregroundColor(.agroGreen)
                        Text("Χωράφι: \(field.name)")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.agroGreen)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.agroGreen.opacity(0.1))
                    .clipShape(Capsule())
                }

                Text("Ρώτα τον Στάθη")
                    .font(.body)
                    .foregroundColor(.secondary)

                VStack(spacing: 10) {
                    suggestionChip("🌱 Είναι καλή εποχή για φύτευση;")
                    suggestionChip("💧 Χρειάζεται πότισμα σήμερα;")
                    suggestionChip("🧪 Μπορώ να ψεκάσω;")
                    suggestionChip("❄️ Υπάρχει κίνδυνος παγετού;")
                    suggestionChip("🌾 Τι εργασίες να κάνω σήμερα;")
                }

                Spacer()
            }
            .padding()
        }
    }

    private var chatScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(messages) { msg in
                        MessageBubble(message: msg)
                            .id(msg.id)
                    }
                    if isProcessing {
                        HStack {
                            HStack(spacing: 6) {
                                DotView(delay: 0)
                                DotView(delay: 0.2)
                                DotView(delay: 0.4)
                            }
                            .padding(14)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            Spacer()
                        }
                        .padding(.horizontal)
                        .id("loading")
                    }
                }
                .padding()
            }
            .onChange(of: messages.count) { _, _ in
                withAnimation { proxy.scrollTo(messages.last?.id, anchor: .bottom) }
            }
        }
    }

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 10) {
                TextField("Ρώτα τον Στάθη...", text: $inputText)
                    .font(.body)
                    .focused($isFocused)
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onSubmit { sendMessage() }

                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(inputText.trimmingCharacters(in: .whitespaces).isEmpty ? .secondary.opacity(0.3) : .agroGreen)
                }
                .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isProcessing)
            }
            .padding(12)
            .background(.regularMaterial)
        }
    }

    private func suggestionChip(_ text: String) -> some View {
        Button {
            inputText = text
            sendMessage()
        } label: {
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }

        messages.append(BotMessage(text: text, isUser: true))
        inputText = ""
        isProcessing = true

        Task {
            do {
                let response = await engine.process(question: text, weather: viewModel.weatherData)
                let delay = response.text.contains("Μπορώ να σε βοηθήσω") ? 0.3 : 0.8
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                messages.append(BotMessage(text: response.text, isUser: false, category: response.category))
            }
            isProcessing = false
        }
    }
}

// MARK: - Message Model

struct BotMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let category: RuleCategory?
    let timestamp: Date

    init(text: String, isUser: Bool, category: RuleCategory? = nil) {
        self.text = text
        self.isUser = isUser
        self.category = category
        self.timestamp = Date()
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: BotMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser { Spacer(minLength: 40) }

            if !message.isUser {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.agroGreen.opacity(0.1))
                        .frame(width: 28, height: 28)
                    Image(systemName: message.category?.icon ?? "leaf.fill")
                        .font(.caption)
                        .foregroundColor(.agroGreen)
                }
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.subheadline)
                    .foregroundColor(message.isUser ? .white : .primary)
                    .lineSpacing(3)
                    .padding(14)
                    .background(message.isUser ? Color.agroGreen : Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                if !message.isUser, let category = message.category {
                    Text(category.rawValue)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                }
            }

            if !message.isUser { Spacer(minLength: 40) }
        }
    }
}

// MARK: - Loading Dots

struct DotView: View {
    let delay: Double
    @State private var show = false

    var body: some View {
        Circle()
            .fill(Color.agroGreen.opacity(0.5))
            .frame(width: 8, height: 8)
            .opacity(show ? 1 : 0.2)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.6).repeatForever().delay(delay)) {
                    show.toggle()
                }
            }
    }
}
