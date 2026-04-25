import Foundation
import ParseSwift
import UserNotifications

@Observable
class AppState {
    var collection: [ParsePlaceEntry] = []
    var communityPosts: [ParsePost] = []
    var communityComments: [String: [ParseComment]] = [:] // postId -> comments
    var communityReactions: [String: [ParseReaction]] = [:] // postId -> reactions
    var bookmarkedPostIds: Set<String> = []
    var bookmarkedPosts: [ParsePost] = []
    var userBadge: ParseUserBadge?
    var travelModeEnabled = false {
        didSet {
            UserDefaults.standard.set(travelModeEnabled, forKey: "travelModeEnabled")
            if travelModeEnabled {
                scheduleDailyReminder()
            } else {
                cancelDailyReminder()
            }
        }
    }
    var reminderHour: Int = 9 {
        didSet {
            UserDefaults.standard.set(reminderHour, forKey: "reminderHour")
            if travelModeEnabled { scheduleDailyReminder() }
        }
    }
    var reminderMinute: Int = 0 {
        didSet {
            UserDefaults.standard.set(reminderMinute, forKey: "reminderMinute")
            if travelModeEnabled { scheduleDailyReminder() }
        }
    }
    var isLoggedIn = false
    var currentUsername: String = ""

    func checkLoginStatus() {
        loadPersistedSettings()
        if let user = ChronoUser.current {
            isLoggedIn = true
            currentUsername = user.username ?? "User"
            loadCollection()
            loadCommunityPosts()
            loadBookmarks()
            loadUserBadge()
        }
    }

    func onLoginSuccess() {
        if let user = ChronoUser.current {
            currentUsername = user.username ?? "User"
        }
        isLoggedIn = true
        loadCollection()
        loadCommunityPosts()
        loadBookmarks()
        loadUserBadge()
    }

    private func loadPersistedSettings() {
        let defaults = UserDefaults.standard
        // Use a sentinel to detect first launch vs stored false
        if defaults.object(forKey: "travelModeEnabled") != nil {
            travelModeEnabled = defaults.bool(forKey: "travelModeEnabled")
        }
        if defaults.object(forKey: "reminderHour") != nil {
            reminderHour = defaults.integer(forKey: "reminderHour")
        }
        if defaults.object(forKey: "reminderMinute") != nil {
            reminderMinute = defaults.integer(forKey: "reminderMinute")
        }
    }

    func logout() {
        ChronoUser.logout { [weak self] _ in
            DispatchQueue.main.async {
                self?.isLoggedIn = false
                self?.collection = []
                self?.communityPosts = []
                self?.communityComments = [:]
                self?.communityReactions = [:]
                self?.bookmarkedPostIds = []
                self?.bookmarkedPosts = []
                self?.userBadge = nil
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

    // MARK: - Reactions

    func toggleReaction(on post: ParsePost, emoji: String) {
        guard let user = ChronoUser.current,
              let userId = user.objectId,
              let postId = post.objectId else { return }

        let existing = communityReactions[postId]?.first {
            $0.user?.objectId == userId && $0.emoji == emoji
        }

        if let existing {
            // Remove reaction
            existing.delete { [weak self] result in
                DispatchQueue.main.async {
                    if case .success = result {
                        self?.communityReactions[postId]?.removeAll { $0.objectId == existing.objectId }
                    }
                }
            }
        } else {
            // Add reaction
            var reaction = ParseReaction()
            reaction.post = Pointer<ParsePost>(objectId: postId)
            reaction.emoji = emoji
            reaction.user = Pointer<ChronoUser>(objectId: userId)
            reaction.authorName = user.fullName ?? user.username ?? "Anonymous"

            reaction.save { [weak self] result in
                DispatchQueue.main.async {
                    if case .success(let saved) = result {
                        var list = self?.communityReactions[postId] ?? []
                        list.append(saved)
                        self?.communityReactions[postId] = list
                    }
                }
            }
        }
    }

    func hasReacted(on post: ParsePost, emoji: String) -> Bool {
        guard let userId = ChronoUser.current?.objectId,
              let postId = post.objectId else { return false }
        return communityReactions[postId]?.contains { $0.user?.objectId == userId && $0.emoji == emoji } ?? false
    }

    func reactionCount(on post: ParsePost, emoji: String) -> Int {
        guard let postId = post.objectId else { return 0 }
        return communityReactions[postId]?.filter { $0.emoji == emoji }.count ?? 0
    }

    func loadReactions(for post: ParsePost) {
        guard let postId = post.objectId else { return }
        let pointer = Pointer<ParsePost>(objectId: postId)

        let query = ParseReaction.query("post" == pointer)
        query.find { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let reactions) = result {
                    self?.communityReactions[postId] = reactions
                }
            }
        }
    }

    // MARK: - Bookmarks

    func toggleBookmark(post: ParsePost) {
        guard let user = ChronoUser.current,
              let userId = user.objectId,
              let postId = post.objectId else { return }

        if bookmarkedPostIds.contains(postId) {
            // Remove bookmark
            let pointer = Pointer<ParsePost>(objectId: postId)
            let userPointer = Pointer<ChronoUser>(objectId: userId)
            let query = ParseBookmark.query("post" == pointer, "user" == userPointer)

            query.find { [weak self] result in
                if case .success(let bookmarks) = result, let bookmark = bookmarks.first {
                    bookmark.delete { deleteResult in
                        DispatchQueue.main.async {
                            if case .success = deleteResult {
                                self?.bookmarkedPostIds.remove(postId)
                                self?.bookmarkedPosts.removeAll { $0.objectId == postId }
                            }
                        }
                    }
                }
            }
        } else {
            // Add bookmark
            var bookmark = ParseBookmark()
            bookmark.post = Pointer<ParsePost>(objectId: postId)
            bookmark.user = Pointer<ChronoUser>(objectId: userId)

            bookmark.save { [weak self] result in
                DispatchQueue.main.async {
                    if case .success = result {
                        self?.bookmarkedPostIds.insert(postId)
                        self?.bookmarkedPosts.insert(post, at: 0)
                    }
                }
            }
        }
    }

    func isBookmarked(_ post: ParsePost) -> Bool {
        guard let postId = post.objectId else { return false }
        return bookmarkedPostIds.contains(postId)
    }

    func loadBookmarks() {
        guard let user = ChronoUser.current,
              let userId = user.objectId else { return }

        let userPointer = Pointer<ChronoUser>(objectId: userId)
        let query = ParseBookmark.query("user" == userPointer)

        query.find { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let bookmarks) = result {
                    self?.bookmarkedPostIds = Set(bookmarks.compactMap { $0.post?.objectId })
                    // Resolve full posts from community posts
                    self?.refreshBookmarkedPosts()
                }
            }
        }
    }

    func refreshBookmarkedPosts() {
        bookmarkedPosts = communityPosts.filter { post in
            guard let id = post.objectId else { return false }
            return bookmarkedPostIds.contains(id)
        }
    }

    // MARK: - Badges & Streaks

    func loadUserBadge() {
        guard let user = ChronoUser.current,
              let userId = user.objectId else { return }

        let pointer = Pointer<ChronoUser>(objectId: userId)
        let query = ParseUserBadge.query("user" == pointer)

        query.find { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let badges) = result {
                    if let existing = badges.first {
                        self?.userBadge = existing
                    } else {
                        // No badge record yet — create a beginner badge
                        self?.createInitialBadge(userId: userId)
                    }
                }
            }
        }
    }

    private func createInitialBadge(userId: String) {
        var badge = ParseUserBadge()
        badge.user = Pointer<ChronoUser>(objectId: userId)
        badge.totalScans = 0
        badge.currentStreak = 0
        badge.longestStreak = 0
        badge.lastScanDate = nil
        badge.badgeLevel = "beginner"

        badge.save { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let saved) = result {
                    self?.userBadge = saved
                }
            }
        }
    }

    func recordDiscovery() {
        guard let user = ChronoUser.current,
              let userId = user.objectId else { return }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())

        if var badge = userBadge {
            let isNewDay = badge.lastScanDate != today

            // Always increment total scans
            badge.totalScans = (badge.totalScans ?? 0) + 1

            // Only update streak on first scan of a new day
            if isNewDay {
                let yesterday = formatter.string(from: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())
                let wasYesterday = badge.lastScanDate == yesterday

                badge.currentStreak = wasYesterday ? (badge.currentStreak ?? 0) + 1 : 1
                badge.longestStreak = max(badge.longestStreak ?? 0, badge.currentStreak ?? 1)
                badge.lastScanDate = today
            }

            badge.badgeLevel = Self.badgeLevel(for: badge.totalScans ?? 1)

            badge.save { [weak self] result in
                DispatchQueue.main.async {
                    if case .success(let saved) = result {
                        self?.userBadge = saved
                    }
                }
            }
        } else {
            // First ever scan — create badge
            var badge = ParseUserBadge()
            badge.user = Pointer<ChronoUser>(objectId: userId)
            badge.totalScans = 1
            badge.currentStreak = 1
            badge.longestStreak = 1
            badge.lastScanDate = today
            badge.badgeLevel = Self.badgeLevel(for: 1)

            badge.save { [weak self] result in
                DispatchQueue.main.async {
                    if case .success(let saved) = result {
                        self?.userBadge = saved
                    }
                }
            }
        }
    }

    static func badgeLevel(for scans: Int) -> String {
        switch scans {
        case 0..<5: return "beginner"
        case 5..<15: return "explorer"
        case 15..<30: return "historian"
        case 30..<50: return "master"
        default: return "legend"
        }
    }

    static func badgeEmoji(for level: String) -> String {
        switch level {
        case "beginner": return "🔍"
        case "explorer": return "🧭"
        case "historian": return "📜"
        case "master": return "🏛️"
        case "legend": return "👑"
        default: return "🔍"
        }
    }

    static func badgeTitle(for level: String) -> String {
        switch level {
        case "beginner": return "Beginner"
        case "explorer": return "Explorer"
        case "historian": return "Historian"
        case "master": return "Master"
        case "legend": return "Legend"
        default: return "Beginner"
        }
    }

    static func nextBadgeInfo(currentScans: Int) -> (nextLevel: String, scansNeeded: Int)? {
        switch currentScans {
        case 0..<5: return ("Explorer", 5 - currentScans)
        case 5..<15: return ("Historian", 15 - currentScans)
        case 15..<30: return ("Master", 30 - currentScans)
        case 30..<50: return ("Legend", 50 - currentScans)
        default: return nil
        }
    }

    // MARK: - Daily Reminder Notifications

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error {
                print("Notification permission error: \(error)")
            }
            if !granted {
                DispatchQueue.main.async {
                    self.travelModeEnabled = false
                }
            }
        }
    }

    func scheduleDailyReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["dailyDiscoveryReminder"])

        let content = UNMutableNotificationContent()
        content.title = "Time to Explore!"
        content.body = "Scan and learn about at least one unique historical item today. Keep your streak going!"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = reminderHour
        dateComponents.minute = reminderMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyDiscoveryReminder", content: content, trigger: trigger)

        center.add(request) { error in
            if let error {
                print("Schedule notification error: \(error)")
            }
        }
    }

    func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyDiscoveryReminder"])
    }
}
