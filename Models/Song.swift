import Foundation

struct Song: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var artist: String
    var album: String?
    var albumId: UUID?
    var coverURL: String?
    var duration: TimeInterval?
    var audioURL: String?
}