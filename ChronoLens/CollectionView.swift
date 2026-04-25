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
        HStack(spacing: 14) {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
                    .frame(width: 64, height: 64)
                    .overlay {
                        ProgressView().controlSize(.small)
                    }
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(entry.placeName ?? "Unknown")
                    .font(.headline)
                Text(entry.summary ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                HStack(spacing: 4) {
                    if let date = entry.scannedAt {
                        Text(date, style: .date)
                    }
                    if let loc = entry.locationName {
                        Text("·")
                        Text(loc)
                            .lineLimit(1)
                    }
                    if entry.isShared == true {
                        Image(systemName: "globe")
                            .foregroundStyle(.blue)
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
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
            VStack(alignment: .leading, spacing: 18) {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                }

                Text(entry.placeName ?? "Unknown")
                    .font(.title.bold())

                Text(entry.summary ?? "")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)

                HStack(spacing: 16) {
                    if let date = entry.scannedAt {
                        HStack(spacing: 4) {
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
                }

                Button {
                    showChat = true
                } label: {
                    Label("Chat About This Place", systemImage: "bubble.left.and.text.bubble.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Divider()
                    .padding(.vertical, 4)

                if !shared && entry.isShared != true {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Share to Community")
                            .font(.headline)

                        TextField("Add a caption (optional)", text: $caption)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                        Button {
                            shareToCommunity()
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Shared to Community")
                    }
                    .foregroundStyle(.green)
                    .font(.subheadline.weight(.medium))
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
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
