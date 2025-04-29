import Foundation

struct User: Identifiable, Codable {
    var id: UUID = UUID()
    var username: String
    var avatarURL: String?
    var bio: String?
}