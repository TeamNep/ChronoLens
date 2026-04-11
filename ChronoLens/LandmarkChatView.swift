import SwiftUI

struct LandmarkChatView: View {
    let placeName: String
    let summary: String
    let imageData: Data
    var latitude: Double?
    var longitude: Double?
    var locationName: String?

    @Environment(AppState.self) var appState
    @State private var chatMessages: [ChatTurn] = []
    @State private var inputText = ""
    @State private var isLoading = false
    @State private var savedToCollection = false
    @State private var showDuplicateAlert = false
    @State private var duplicateEntry: ParsePlaceEntry?

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        // Header with image and summary
                        if let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 180)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        Text(summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Divider()
                            .padding(.vertical, 4)

                        if chatMessages.isEmpty && !isLoading {
                            Text("Ask anything about \(placeName)")
                                .foregroundStyle(.tertiary)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 20)
                        }

                        // Chat messages
                        ForEach(chatMessages) { msg in
                            ChatBubble(message: msg)
                                .id(msg.id)
                        }

                        if isLoading {
                            HStack {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Thinking...")
                                    .foregroundStyle(.secondary)
                                    .font(.subheadline)
                            }
                            .id("loading")
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                }
                .onChange(of: chatMessages.count) {
                    withAnimation {
                        if let last = chatMessages.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: isLoading) {
                    if isLoading {
                        withAnimation {
                            proxy.scrollTo("loading", anchor: .bottom)
                        }
                    }
                }
            }

            // Input bar
            HStack(spacing: 8) {
                TextField("Ask about \(placeName)...", text: $inputText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { sendMessage() }

                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                }
                .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.bar)
        }
        .navigationTitle(placeName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    saveToCollection()
                } label: {
                    Image(
                        systemName: savedToCollection
                            ? "checkmark.circle.fill" : "square.and.arrow.down"
                    )
                }
                .disabled(savedToCollection)
            }
        }
        .alert("Already in Collection", isPresented: $showDuplicateAlert) {
            Button("Replace") {
                if let existing = duplicateEntry {
                    appState.replaceInCollection(
                        existing: existing,
                        imageData: imageData,
                        placeName: placeName,
                        summary: summary,
                        latitude: latitude,
                        longitude: longitude,
                        locationName: locationName
                    )
                    savedToCollection = true
                }
            }
            Button("Keep Both") {
                appState.saveToCollection(
                    imageData: imageData,
                    placeName: placeName,
                    summary: summary,
                    latitude: latitude,
                    longitude: longitude,
                    locationName: locationName
                )
                savedToCollection = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("\"\(placeName)\" is already in your collection. Would you like to replace it or keep both?")
        }
    }

    private func sendMessage() {
        let question = inputText.trimmingCharacters(in: .whitespaces)
        guard !question.isEmpty else { return }

        chatMessages.append(ChatTurn(isUser: true, text: question))
        inputText = ""
        isLoading = true

        // Build conversation history (all prior messages, excluding the one we just added)
        let history: [(role: String, content: String)] = chatMessages.dropLast().map { msg in
            (role: msg.isUser ? "user" : "assistant", content: msg.text)
        }

        Task {
            do {
                let answer = try await NVIDIATextService().askQuestion(
                    about: placeName,
                    summary: summary,
                    conversationHistory: history,
                    question: question
                )
                chatMessages.append(ChatTurn(isUser: false, text: answer))
            } catch {
                chatMessages.append(
                    ChatTurn(isUser: false, text: "Sorry, something went wrong: \(error.localizedDescription)")
                )
            }
            isLoading = false
        }
    }

    private func saveToCollection() {
        if let existing = appState.collection.first(where: {
            $0.placeName?.lowercased() == placeName.lowercased()
        }) {
            duplicateEntry = existing
            showDuplicateAlert = true
        } else {
            appState.saveToCollection(
                imageData: imageData,
                placeName: placeName,
                summary: summary,
                latitude: latitude,
                longitude: longitude,
                locationName: locationName
            )
            savedToCollection = true
        }
    }
}

// MARK: - Chat Bubble

struct ChatBubble: View {
    let message: ChatTurn

    var body: some View {
        HStack {
            if message.isUser { Spacer(minLength: 48) }

            Text(message.text)
                .padding(12)
                .background(message.isUser ? Color.blue : Color(.systemGray5))
                .foregroundStyle(message.isUser ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            if !message.isUser { Spacer(minLength: 48) }
        }
    }
}
