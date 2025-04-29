import Foundation
import Combine

class SearchViewModel: ObservableObject {
    private var musicService = MusicService.shared
    private var embyService = EmbyService.shared
    private var cancellables = Set<AnyCancellable>()
    
    @Published var searchQuery: String = ""
    @Published var searchResults: SearchResults = SearchResults()
    @Published var isSearching: Bool = false
    @Published var errorMessage: String? = nil
    @Published var searchSource: SearchSource = .local
    
    enum SearchSource {
        case local
        case emby
    }
    
    struct SearchResults {
        var songs: [Song] = []
        var playlists: [Playlist] = []
        var embyItems: [[String: Any]] = []
    }
    
    func search() {
        guard !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = SearchResults()
            return
        }
        
        isSearching = true
        errorMessage = nil
        
        // 根据当前连接状态决定搜索来源
        if embyService.isConnected && searchSource == .emby {
            searchEmby()
        } else {
            searchLocal()
        }
    }
    
    // 搜索本地数据
    private func searchLocal() {
        let group = DispatchGroup()
        
        // 搜索歌曲
        group.enter()
        musicService.searchSongs(query: searchQuery) { [weak self] songs in
            DispatchQueue.main.async {
                self?.searchResults.songs = songs
                group.leave()
            }
        }
        
        // 搜索歌单
        group.enter()
        musicService.searchPlaylists(query: searchQuery) { [weak self] playlists in
            DispatchQueue.main.async {
                self?.searchResults.playlists = playlists
                group.leave()
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.isSearching = false
        }
    }
    
    // 搜索Emby服务器
    private func searchEmby() {
        Task {
            do {
                // 获取音乐库
                let libraries = try await embyService.getMusicLibraries()
                
                var allEmbyItems: [[String: Any]] = []
                
                // 在每个音乐库中搜索
                for library in libraries {
                    if let libraryId = library["ItemId"] as? String {
                        // 构建搜索选项
                        let options: [String: Any] = [
                            "SearchTerm": searchQuery,
                            "IncludeItemTypes": "Audio,MusicAlbum,MusicArtist",
                            "Recursive": true,
                            "Limit": 50
                        ]
                        
                        // 执行搜索
                        let items = try await embyService.getMusic(libraryId: libraryId, options: options)
                        allEmbyItems.append(contentsOf: items)
                    }
                }
                
                // 更新UI
                await MainActor.run {
                    self.searchResults.embyItems = allEmbyItems
                    self.isSearching = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "搜索Emby失败: \(error.localizedDescription)"
                    self.isSearching = false
                    
                    // 如果Emby搜索失败，回退到本地搜索
                    self.searchLocal()
                }
            }
        }
    }
    
    // 切换搜索源
    func toggleSearchSource() {
        if searchSource == .local {
            searchSource = .emby
        } else {
            searchSource = .local
        }
        
        // 如果已有搜索查询，则重新搜索
        if !searchQuery.isEmpty {
            search()
        }
    }
}