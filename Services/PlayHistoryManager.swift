import Foundation

struct PlayRecord: Codable {
    let songId: String
    let timestamp: Date
    let duration: TimeInterval
    let completed: Bool
}

class PlayHistoryManager {
    static let shared = PlayHistoryManager()
    
    private let userDefaults = UserDefaults.standard
    private let historyKey = "playHistory"
    private let maxHistoryItems = 1000
    
    private var playHistory: [PlayRecord] = []
    private var recommendations: [Song] = []
    
    private init() {
        loadHistory()
    }
    
    // 加载播放历史
    private func loadHistory() {
        if let data = userDefaults.data(forKey: historyKey),
           let history = try? JSONDecoder().decode([PlayRecord].self, from: data) {
            playHistory = history
        }
    }
    
    // 保存播放历史
    private func saveHistory() {
        if let data = try? JSONEncoder().encode(playHistory) {
            userDefaults.set(data, forKey: historyKey)
        }
    }
    
    // 添加播放记录
    func addPlayRecord(songId: String, duration: TimeInterval, completed: Bool) {
        let record = PlayRecord(songId: songId,
                              timestamp: Date(),
                              duration: duration,
                              completed: completed)
        
        playHistory.insert(record, at: 0)
        
        // 限制历史记录数量
        if playHistory.count > maxHistoryItems {
            playHistory.removeLast()
        }
        
        saveHistory()
        updateRecommendations()
    }
    
    // 获取播放历史
    func getPlayHistory() -> [PlayRecord] {
        return playHistory
    }
    
    // 清除播放历史
    func clearHistory() {
        playHistory.removeAll()
        saveHistory()
    }
    
    // 获取最近播放的歌曲ID列表
    func getRecentlyPlayedSongIds(limit: Int = 50) -> [String] {
        return Array(Set(playHistory.prefix(limit).map { $0.songId }))
    }
    
    // 获取最常播放的歌曲ID列表
    func getMostPlayedSongIds(limit: Int = 50) -> [String] {
        let songCounts = playHistory.reduce(into: [:]) { counts, record in
            counts[record.songId, default: 0] += 1
        }
        
        return Array(songCounts.sorted { $0.value > $1.value }
            .prefix(limit)
            .map { $0.key })
    }
    
    // 更新推荐列表
    private func updateRecommendations() {
        // 获取用户最近的听歌偏好
        let recentSongs = getRecentlyPlayedSongIds(limit: 20)
        let frequentSongs = getMostPlayedSongIds(limit: 20)
        
        // 这里应该实现更复杂的推荐算法
        // 例如：基于协同过滤、内容特征匹配等
        // 当前使用简单的基于历史的推荐
        
        // 获取推荐歌曲（实际项目中应该调用后端API）
        MusicService.shared.getRecommendations(
            basedOn: recentSongs + frequentSongs
        ) { [weak self] songs in
            self?.recommendations = songs
        }
    }
    
    // 获取推荐歌曲
    func getRecommendations() -> [Song] {
        return recommendations
    }
    
    // 获取某首歌曲的播放次数
    func getPlayCount(for songId: String) -> Int {
        return playHistory.filter { $0.songId == songId }.count
    }
    
    // 获取某首歌曲的最后播放时间
    func getLastPlayTime(for songId: String) -> Date? {
        return playHistory.first { $0.songId == songId }?.timestamp
    }
    
    // 获取播放统计信息
    func getPlayStats() -> [String: Any] {
        let totalPlays = playHistory.count
        let uniqueSongs = Set(playHistory.map { $0.songId }).count
        let completedPlays = playHistory.filter { $0.completed }.count
        let totalDuration = playHistory.reduce(0) { $0 + $1.duration }
        
        return [
            "totalPlays": totalPlays,
            "uniqueSongs": uniqueSongs,
            "completedPlays": completedPlays,
            "totalDuration": totalDuration
        ]
    }
    
    // 导出播放历史
    func exportHistory() -> Data? {
        return try? JSONEncoder().encode(playHistory)
    }
    
    // 导入播放历史
    func importHistory(from data: Data) {
        guard let history = try? JSONDecoder().decode([PlayRecord].self, from: data) else {
            return
        }
        
        playHistory = history
        saveHistory()
        updateRecommendations()
    }
} 