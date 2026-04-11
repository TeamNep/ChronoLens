import Foundation

struct ChatTurn: Identifiable {
    let id = UUID()
    let isUser: Bool
    let text: String
    let createdAt = Date()
}
