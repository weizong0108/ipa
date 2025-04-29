import Foundation
import Combine

class HomeViewModel: ObservableObject {
    private var musicService = MusicService.shared
    private var cancellables = Set<AnyCancellable>()
    
    @Published var featuredPlaylists: [Playlist] = []
    @Published var recommendedSongs: [Song] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    func loadHomeData() {
        isLoading = true
        errorMessage = nil
        
        // 获取推荐歌单
        musicService.fetchFeaturedPlaylists { [weak self] playlists in
            DispatchQueue.main.async {
                self?.featuredPlaylists = playlists
                self?.isLoading = false
            }
        }
        
        // 获取推荐歌曲
        musicService.fetchRecommendedSongs { [weak self] songs in
            DispatchQueue.main.async {
                self?.recommendedSongs = songs
            }
        }
    }
}