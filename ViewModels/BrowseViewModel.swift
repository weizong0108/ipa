import Foundation
import Combine

class BrowseViewModel: ObservableObject {
    private var musicService = MusicService.shared
    private var embyService = EmbyService.shared
    private var cancellables = Set<AnyCancellable>()
    
    @Published var categories: [String] = ["流行", "摇滚", "民谣", "电子", "古典", "嘻哈"]
    @Published var categoryPlaylists: [String: [Playlist]] = [:]
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // Emby相关数据
    @Published var embyMusicLibraries: [[String: Any]] = []
    @Published var embyAlbums: [String: [Album]] = [:]
    @Published var showingEmbyContent: Bool = false
    
    func loadBrowseData() {
        isLoading = true
        errorMessage = nil
        
        // 检查是否连接到Emby服务器
        if embyService.isConnected {
            loadEmbyData()
        } else {
            loadLocalData()
        }
    }
    
    // 加载本地数据
    private func loadLocalData() {
        let group = DispatchGroup()
        
        // 获取每个分类的歌单
        for category in categories {
            group.enter()
            musicService.fetchCategoryPlaylists(category: category) { [weak self] playlists in
                DispatchQueue.main.async {
                    self?.categoryPlaylists[category] = playlists
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.isLoading = false
            self?.showingEmbyContent = false
        }
    }
    
    // 加载Emby服务器数据
    private func loadEmbyData() {
        Task {
            do {
                // 获取音乐库
                let libraries = try await embyService.getMusicLibraries()
                
                // 更新UI
                await MainActor.run {
                    self.embyMusicLibraries = libraries
                    self.showingEmbyContent = true
                    
                    // 为每个音乐库加载专辑
                    for library in libraries {
                        if let libraryId = library["ItemId"] as? String {
                            loadEmbyAlbums(for: libraryId)
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "加载Emby数据失败: \(error.localizedDescription)"
                    self.isLoading = false
                    
                    // 如果Emby数据加载失败，回退到本地数据
                    self.loadLocalData()
                }
            }
        }
    }
    
    // 为指定音乐库加载专辑
    private func loadEmbyAlbums(for libraryId: String) {
        Task {
            do {
                // 获取专辑数据
                let albumsData = try await embyService.getAlbums(libraryId: libraryId)
                
                // 将Emby专辑数据转换为App的Album模型
                var albums: [Album] = []
                
                for albumData in albumsData {
                    if let name = albumData["Name"] as? String {
                        let artist = (albumData["AlbumArtist"] as? String) ?? "未知艺术家"
                        let id = UUID()
                        
                        let album = Album(
                            title: name,
                            artist: artist,
                            releaseDate: nil,
                            coverURL: nil,
                            description: "来自Emby服务器"
                        )
                        
                        albums.append(album)
                    }
                }
                
                // 更新UI
                await MainActor.run {
                    self.embyAlbums[libraryId] = albums
                    self.isLoading = false
                }
            } catch {
                print("加载Emby专辑失败: \(error.localizedDescription)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}