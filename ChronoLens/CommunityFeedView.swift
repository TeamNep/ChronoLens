import SwiftUI
import ParseSwift

struct CommunityFeedView: View {
    @Environment(AppState.self) var appState

    var body: some View {
        NavigationStack {
            Group {
                if appState.communityPosts.isEmpty {
                    ContentUnavailableView(
                        "No Posts Yet",
                        systemImage: "person.3",
                        description: Text(
                            "Share discoveries from your Collection to see them here.")
                    )
                } else {
                    List {
                        ForEach(appState.communityPosts, id: \.objectId) { post in
                            NavigationLink {
                                PostDetailView(post: post)
                            } label: {
                                CommunityPostRow(post: post)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                if appState.isOwnPost(post) {
                                    Button(role: .destructive) {
                                        appState.deletePost(post: post)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Community")
            .refreshable {
                appState.loadCommunityPosts()
            }
        }
    }
}

// MARK: - Post Row

private struct CommunityPostRow: View {
    let post: ParsePost
    @State private var image: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            HStack {
                Text(post.authorName ?? "Anonymous")
                    .font(.caption.bold())
                    .foregroundStyle(.blue)
                Spacer()
                if let date = post.createdAt {
                    Text(date, format: .dateTime.month().day().hour().minute())
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Text(post.placeName ?? "Unknown")
                .font(.headline)

            if let caption = post.caption, !caption.isEmpty {
                Text(caption)
                    .font(.body)
                    .foregroundStyle(Color(red: 0.55, green: 0.36, blue: 0.8))
            }

            if let loc = post.locationName, !loc.isEmpty {
                Label(loc, systemImage: "location.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .task {
            await loadImage()
        }
    }

    private func loadImage() async {
        guard let file = post.imageFile, let url = file.url else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            image = UIImage(data: data)
        } catch {
            print("Image load error: \(error)")
        }
    }
}

// MARK: - Post Detail

struct PostDetailView: View {
    let post: ParsePost
    @Environment(AppState.self) var appState
    @State private var commentText = ""
    @State private var image: UIImage?

    private var comments: [ParseComment] {
        appState.communityComments[post.objectId ?? ""] ?? []
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    HStack {
                        Text(post.authorName ?? "Anonymous")
                            .font(.subheadline.bold())
                            .foregroundStyle(.blue)
                        Spacer()
                        if let date = post.createdAt {
                            Text(date, format: .dateTime.month().day().year())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Text(post.placeName ?? "Unknown")
                        .font(.title2.bold())

                    if let summary = post.placeSummary {
                        Text(summary)
                            .foregroundStyle(.secondary)
                    }

                    if let loc = post.locationName, !loc.isEmpty {
                        Label(loc, systemImage: "location.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let caption = post.caption, !caption.isEmpty {
                        Text(caption)
                            .font(.body)
                            .foregroundStyle(Color(red: 0.55, green: 0.36, blue: 0.8))
                    }

                    // TODO: Comments section — uncomment when ready
                    // Divider()
                    //
                    // Text("Comments")
                    //     .font(.headline)
                    //
                    // if comments.isEmpty {
                    //     Text("No comments yet. Be the first!")
                    //         .foregroundStyle(.secondary)
                    //         .font(.subheadline)
                    // } else {
                    //     ForEach(comments, id: \.objectId) { comment in
                    //         VStack(alignment: .leading, spacing: 4) {
                    //             HStack {
                    //                 Text(comment.authorName ?? "Anonymous")
                    //                     .font(.caption.bold())
                    //                 Spacer()
                    //                 if let date = comment.createdAt {
                    //                     Text(date, style: .relative)
                    //                         .font(.caption2)
                    //                         .foregroundStyle(.tertiary)
                    //                 }
                    //             }
                    //             Text(comment.text ?? "")
                    //                 .font(.subheadline)
                    //         }
                    //         .padding(.vertical, 4)
                    //     }
                    // }
                }
                .padding()
            }

            // TODO: Comment input — uncomment when ready
            // HStack(spacing: 8) {
            //     TextField("Add a comment...", text: $commentText)
            //         .textFieldStyle(.roundedBorder)
            //         .onSubmit { addComment() }
            //
            //     Button("Post") {
            //         addComment()
            //     }
            //     .disabled(commentText.trimmingCharacters(in: .whitespaces).isEmpty)
            // }
            // .padding(.horizontal)
            // .padding(.vertical, 8)
            // .background(.bar)
        }
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadImage()
            // appState.loadComments(for: post)
        }
    }

    private func loadImage() async {
        guard let file = post.imageFile, let url = file.url else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            image = UIImage(data: data)
        } catch {
            print("Image load error: \(error)")
        }
    }

    private func addComment() {
        let text = commentText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        appState.addComment(to: post, text: text)
        commentText = ""
    }
}
