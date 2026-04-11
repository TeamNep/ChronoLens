import Foundation
import ParseSwift

@Observable
class AppState {
    var collection: [ParsePlaceEntry] = []
    var communityPosts: [ParsePost] = []
    var communityComments: [String: [ParseComment]] = [:] // postId -> comments
    var travelModeEnabled = false
    var isLoggedIn = false
    var currentUsername: String = ""

    func checkLoginStatus() {
        if let user = ChronoUser.current {
            isLoggedIn = true
            currentUsername = user.username ?? "User"
            loadCollection()
            loadCommunityPosts()
        }
    }

    func onLoginSuccess() {
        if let user = ChronoUser.current {
            currentUsername = user.username ?? "User"
        }
        isLoggedIn = true
        loadCollection()
        loadCommunityPosts()
    }

    func logout() {
        ChronoUser.logout { [weak self] _ in
            DispatchQueue.main.async {
                self?.isLoggedIn = false
                self?.collection = []
                self?.communityPosts = []
                self?.communityComments = [:]
                self?.currentUsername = ""
            }
        }
    }

    // MARK: - Collection

    func saveToCollection(imageData: Data, placeName: String, summary: String,
                          latitude: Double?, longitude: Double?, locationName: String?) {
        guard let user = ChronoUser.current else { return }

        let imageFile = ParseFile(name: "landmark.jpg", data: imageData)

        // Upload file first, then save the object with the uploaded file URL
        imageFile.save { [weak self] fileResult in
            switch fileResult {
            case .success(let uploadedFile):
                var entry = ParsePlaceEntry()
                entry.imageFile = uploadedFile
                entry.placeName = placeName
                entry.summary = summary
                entry.latitude = latitude
                entry.longitude = longitude
                entry.locationName = locationName
                entry.scannedAt = Date()
                entry.isShared = false
                entry.user = Pointer<ChronoUser>(objectId: user.objectId ?? "")

                entry.save { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let saved):
                            self?.collection.insert(saved, at: 0)
                        case .failure(let error):
                            print("Save entry error: \(error)")
                        }
                    }
                }
            case .failure(let error):
                print("File upload error: \(error)")
            }
        }
    }

    func replaceInCollection(existing: ParsePlaceEntry, imageData: Data,
                              placeName: String, summary: String,
                              latitude: Double?, longitude: Double?, locationName: String?) {
        existing.delete { [weak self] result in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    self?.collection.removeAll { $0.objectId == existing.objectId }
                }
                self?.saveToCollection(
                    imageData: imageData,
                    placeName: placeName,
                    summary: summary,
                    latitude: latitude,
                    longitude: longitude,
                    locationName: locationName
                )
            case .failure(let error):
                print("Delete old entry error: \(error)")
            }
        }
    }

    func deleteFromCollection(entry: ParsePlaceEntry) {
        entry.delete { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.collection.removeAll { $0.objectId == entry.objectId }
                case .failure(let error):
                    print("Delete collection entry error: \(error)")
                }
            }
        }
    }

    func loadCollection() {
        guard let user = ChronoUser.current,
              let objectId = user.objectId else { return }

        let pointer = Pointer<ChronoUser>(objectId: objectId)
        var query = ParsePlaceEntry.query("user" == pointer)
        query = query.order([.descending("scannedAt")])

        query.find { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let entries):
                    self?.collection = entries
                case .failure(let error):
                    print("Load collection error: \(error)")
                }
            }
        }
    }

    // MARK: - Community Posts

    func isOwnPost(_ post: ParsePost) -> Bool {
        guard let user = ChronoUser.current,
              let userId = user.objectId else { return false }
        return post.user?.objectId == userId
    }

    func deletePost(post: ParsePost) {
        post.delete { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.communityPosts.removeAll { $0.objectId == post.objectId }
                case .failure(let error):
                    print("Delete post error: \(error)")
                }
            }
        }
    }

    func shareToCommunity(entry: ParsePlaceEntry, caption: String) {
        guard let user = ChronoUser.current else { return }

        var post = ParsePost()
        if let entryId = entry.objectId {
            post.placeEntry = Pointer<ParsePlaceEntry>(objectId: entryId)
        }
        post.imageFile = entry.imageFile
        post.placeName = entry.placeName
        post.placeSummary = entry.summary
        post.locationName = entry.locationName
        post.caption = caption
        post.authorName = user.fullName ?? user.username ?? "Anonymous"
        post.user = Pointer<ChronoUser>(objectId: user.objectId ?? "")

        post.save { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let savedPost):
                    self?.communityPosts.insert(savedPost, at: 0)
                    if var updatedEntry = self?.collection.first(where: { $0.objectId == entry.objectId }) {
                        updatedEntry.isShared = true
                        updatedEntry.save { updateResult in
                            DispatchQueue.main.async {
                                if case .success(let saved) = updateResult,
                                   let idx = self?.collection.firstIndex(where: { $0.objectId == entry.objectId }) {
                                    self?.collection[idx] = saved
                                }
                            }
                        }
                    }
                case .failure(let error):
                    print("Share error: \(error)")
                }
            }
        }
    }

    func loadCommunityPosts() {
        var query = ParsePost.query()
        query = query.order([.descending("createdAt")])
            .limit(50)

        query.find { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let posts):
                    self?.communityPosts = posts
                case .failure(let error):
                    print("Load posts error: \(error)")
                }
            }
        }
    }

    // MARK: - Comments

    func addComment(to post: ParsePost, text: String) {
        guard let user = ChronoUser.current else { return }
        let postId = post.objectId ?? ""

        var comment = ParseComment()
        if let postObjId = post.objectId {
            comment.post = Pointer<ParsePost>(objectId: postObjId)
        }
        comment.authorName = user.fullName ?? user.username ?? "Anonymous"
        comment.text = text
        comment.user = Pointer<ChronoUser>(objectId: user.objectId ?? "")

        comment.save { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let saved):
                    var existing = self?.communityComments[postId] ?? []
                    existing.append(saved)
                    self?.communityComments[postId] = existing
                case .failure(let error):
                    print("Comment error: \(error)")
                }
            }
        }
    }

    func loadComments(for post: ParsePost) {
        guard let postObjId = post.objectId else { return }
        let pointer = Pointer<ParsePost>(objectId: postObjId)

        var query = ParseComment.query("post" == pointer)
        query = query.order([.ascending("createdAt")])

        query.find { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let comments):
                    self?.communityComments[postObjId] = comments
                case .failure(let error):
                    print("Load comments error: \(error)")
                }
            }
        }
    }
}
