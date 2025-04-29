import Foundation

struct Playlist: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var description: String?
    var coverURL: String?
    var songs: [Song] = []
}