import SwiftUI
import ParseSwift

struct CollectionView: View {
    @Environment(AppState.self) var appState

    var body: some View {
        NavigationStack {
            Group {
                if appState.collection.isEmpty {
                    ContentUnavailableView(
                        "No Places Yet",
                        systemImage: "square.stack",
                        description: Text("Scan landmarks from the Explore tab to build your collection.")
                    )
                } else {
                    List {
                        ForEach(appState.collection, id: \.objectId) { entry in
                            NavigationLink {
                                CollectionDetailView(entry: entry)
                            } label: {
                                CollectionRow(entry: entry)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    appState.deleteFromCollection(entry: entry)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Collection")
            .refreshable {
                appState.loadCollection()
            }
        }
    }
}

// MARK: - Row

private struct CollectionRow: View {
    let entry: ParsePlaceEntry
    @State private var image: UIImage?

    var body: some View {
        HStack(spacing: 12) {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay {
                        ProgressView().controlSize(.small)
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.placeName ?? "Unknown")
                    .font(.headline)
                Text(entry.summary ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                HStack {
                    if let date = entry.scannedAt {
                        Text(date, style: .date)
                    }
                    if let loc = entry.locationName {
                        Text("- \(loc)")
                    }
                    if entry.isShared == true {
                        Image(systemName: "globe")
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .task {
            await loadImage()
        }
    }

    private func loadImage() async {
        guard let file = entry.imageFile, let url = file.url else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            image = UIImage(data: data)
        } catch {
            print("Image load error: \(error)")
        }
    }
}

// MARK: - Detail

struct CollectionDetailView: View {
    let entry: ParsePlaceEntry
    @Environment(AppState.self) var appState
    @State private var caption = ""
    @State private var shared = false
    @State private var showChat = false
    @State private var image: UIImage?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Text(entry.placeName ?? "Unknown")
                    .font(.title.bold())

                Text(entry.summary ?? "")
                    .foregroundStyle(.secondary)

                if let date = entry.scannedAt {
                    HStack {
                        Image(systemName: "clock")
                        Text(date, format: .dateTime.month().day().year().hour().minute())
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                if let loc = entry.locationName {
                    Label(loc, systemImage: "location.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button {
                    showChat = true
                } label: {
                    Label("Chat About This Place", systemImage: "bubble.left.and.text.bubble.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Divider()

                if !shared && entry.isShared != true {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Share to Community")
                            .font(.headline)

                        TextField("Add a caption (optional)", text: $caption)
                            .textFieldStyle(.roundedBorder)

                        Button {
                            shareToCommunity()
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    Label("Shared to Community", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
            .padding()
        }
        .navigationTitle(entry.placeName ?? "Detail")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showChat) {
            if let name = entry.placeName, let summary = entry.summary {
                LandmarkChatView(
                    placeName: name,
                    summary: summary,
                    imageData: Data(),
                    latitude: entry.latitude,
                    longitude: entry.longitude,
                    locationName: entry.locationName
                )
            }
        }
        .task {
            await loadImage()
        }
    }

    private func loadImage() async {
        guard let file = entry.imageFile, let url = file.url else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            image = UIImage(data: data)
        } catch {
            print("Image load error: \(error)")
        }
    }

    private func shareToCommunity() {
        appState.shareToCommunity(entry: entry, caption: caption)
        shared = true
    }
}
