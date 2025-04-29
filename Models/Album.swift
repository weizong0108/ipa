import Foundation

struct Album: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var artist: String
    var releaseDate: Date?
    var coverURL: String?
    var description: String?
    var songs: [Song] = []
    
    // 计算专辑总时长
    var totalDuration: TimeInterval {
        return songs.compactMap { $0.duration }.reduce(0, +)
    }
    
    // 计算歌曲数量
    var songCount: Int {
        return songs.count
    }
}