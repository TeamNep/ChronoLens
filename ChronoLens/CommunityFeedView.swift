import SwiftUI
import ParseSwift

struct CommunityFeedView: View {
    @Environment(AppState.self) var appState
    @State private var selectedSegment = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Feed", selection: $selectedSegment) {
                    Text("Feed").tag(0)
                    Text("Bookmarks").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)

                if selectedSegment == 0 {
                    feedList(posts: appState.communityPosts, emptyTitle: "No Posts Yet", emptyMessage: "Share discoveries from your Collection to see them here.")
                } else {
                    feedList(posts: appState.bookmarkedPosts, emptyTitle: "No Bookmarks", emptyMessage: "Bookmark community posts to save them for later reading.")
                }
            }
            .navigationTitle("Community")
            .refreshable {
                appState.loadCommunityPosts()
                appState.loadBookmarks()
            }
        }
    }

    @ViewBuilder
    private func feedList(posts: [ParsePost], emptyTitle: String, emptyMessage: String) -> some View {
        if posts.isEmpty {
            ContentUnavailableView(
                emptyTitle,
                systemImage: selectedSegment == 0 ? "person.3" : "bookmark",
                description: Text(emptyMessage)
            )
        } else {
            List {
                ForEach(posts, id: \.objectId) { post in
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
                    .swipeActions(edge: .leading) {
                        Button {
                            appState.toggleBookmark(post: post)
                        } label: {
                            Label(
                                appState.isBookmarked(post) ? "Unbookmark" : "Bookmark",
                                systemImage: appState.isBookmarked(post) ? "bookmark.slash" : "bookmark"
                            )
                        }
                        .tint(.orange)
                    }
                }
            }
            .listStyle(.plain)
        }
    }
}

// MARK: - Post Row

private struct CommunityPostRow: View {
    let post: ParsePost
    @Environment(AppState.self) var appState
    @State private var image: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 190)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            HStack {
                Text(post.authorName ?? "Anonymous")
                    .font(.caption.bold())
                    .foregroundStyle(.blue)
                Spacer()
                if let date = post.createdAt {
                    Text(date, format: .dateTime.month().day().hour().minute())
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Text(post.placeName ?? "Unknown")
                .font(.headline)

            if let caption = post.caption, !caption.isEmpty {
                Text(caption)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineSpacing(1)
            }

            if let loc = post.locationName, !loc.isEmpty {
                Label(loc, systemImage: "location.fill")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            HStack(spacing: 10) {
                ReactionButton(post: post, emoji: "❤️")
                ReactionButton(post: post, emoji: "🔥")
                ReactionButton(post: post, emoji: "👏")

                Spacer()

                if appState.isBookmarked(post) {
                    Image(systemName: "bookmark.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                let commentCount = appState.communityComments[post.objectId ?? ""]?.count ?? 0
                if commentCount > 0 {
                    Label("\(commentCount)", systemImage: "bubble.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 2)
        }
        .padding(.vertical, 6)
        .task {
            await loadImage()
            appState.loadReactions(for: post)
            appState.loadComments(for: post)
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

// MARK: - Reaction Button

private struct ReactionButton: View {
    let post: ParsePost
    let emoji: String
    @Environment(AppState.self) var appState

    var body: some View {
        let count = appState.reactionCount(on: post, emoji: emoji)
        let reacted = appState.hasReacted(on: post, emoji: emoji)

        Button {
            appState.toggleReaction(on: post, emoji: emoji)
        } label: {
            HStack(spacing: 2) {
                Text(emoji)
                    .font(.caption)
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .foregroundStyle(reacted ? .blue : .secondary)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(reacted ? Color.blue.opacity(0.1) : Color.clear)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(reacted ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
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
                VStack(alignment: .leading, spacing: 14) {
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
                    }

                    HStack {
                        Text(post.authorName ?? "Anonymous")
                            .font(.subheadline.bold())
                            .foregroundStyle(.blue)
                        Spacer()
                        if let date = post.createdAt {
                            Text(date, format: .dateTime.month().day().year())
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }

                    Text(post.placeName ?? "Unknown")
                        .font(.title2.bold())

                    if let summary = post.placeSummary {
                        Text(summary)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .lineSpacing(2)
                    }

                    if let loc = post.locationName, !loc.isEmpty {
                        Label(loc, systemImage: "location.fill")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    if let caption = post.caption, !caption.isEmpty {
                        Text(caption)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .italic()
                    }

                    // Reactions
                    HStack(spacing: 10) {
                        ReactionButton(post: post, emoji: "❤️")
                        ReactionButton(post: post, emoji: "🔥")
                        ReactionButton(post: post, emoji: "👏")
                        ReactionButton(post: post, emoji: "🤯")
                        ReactionButton(post: post, emoji: "📸")

                        Spacer()

                        Button {
                            appState.toggleBookmark(post: post)
                        } label: {
                            Image(systemName: appState.isBookmarked(post) ? "bookmark.fill" : "bookmark")
                                .font(.body)
                                .foregroundStyle(appState.isBookmarked(post) ? .orange : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 6)

                    Divider()

                    Text("Comments")
                        .font(.headline)
                        .padding(.top, 4)

                    if comments.isEmpty {
                        Text("No comments yet. Be the first!")
                            .foregroundStyle(.tertiary)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    } else {
                        ForEach(comments, id: \.objectId) { comment in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(comment.authorName ?? "Anonymous")
                                        .font(.caption.bold())
                                    Spacer()
                                    if let date = comment.createdAt {
                                        Text(date, style: .relative)
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                                Text(comment.text ?? "")
                                    .font(.subheadline)
                            }
                            .padding(12)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
                .padding()
            }

            // Comment input
            HStack(spacing: 8) {
                TextField("Add a comment...", text: $commentText)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .onSubmit { addComment() }

                Button {
                    addComment()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                }
                .disabled(commentText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(.bar)
        }
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadImage()
            appState.loadComments(for: post)
            appState.loadReactions(for: post)
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
