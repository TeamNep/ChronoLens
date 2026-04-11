import Foundation
import ParseSwift

struct ParsePlaceEntry: ParseObject {
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    var imageFile: ParseFile?
    var placeName: String?
    var summary: String?
    var latitude: Double?
    var longitude: Double?
    var locationName: String?
    var scannedAt: Date?
    var isShared: Bool?
    var user: Pointer<ChronoUser>?
}

struct ParsePost: ParseObject {
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    var placeEntry: Pointer<ParsePlaceEntry>?
    var imageFile: ParseFile?
    var placeName: String?
    var placeSummary: String?
    var locationName: String?
    var caption: String?
    var authorName: String?
    var user: Pointer<ChronoUser>?
}

struct ParseComment: ParseObject {
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    var post: Pointer<ParsePost>?
    var authorName: String?
    var text: String?
    var user: Pointer<ChronoUser>?
}
