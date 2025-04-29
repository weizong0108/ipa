import Combine
import SwiftUI

class Router: ObservableObject {
    @Published var currentTab: Tab = .home
    @Published var selectedSongId: UUID? = nil
    @Published var selectedAlbumId: UUID? = nil
    
    enum Tab {
        case home, browse, search, nowPlaying, profile
    }
    
    // 导航到歌曲详情页
    func navigateToSongDetail(songId: UUID) {
        self.selectedSongId = songId
    }
    
    // 导航到专辑页面
    func navigateToAlbum(albumId: UUID) {
        self.selectedAlbumId = albumId
    }
}