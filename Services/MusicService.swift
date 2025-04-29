import Foundation

class MusicService {
    // 用于对接音乐服务器和播放控制的服务类
    static let shared = MusicService()
    private init() {}
    
    // 网络状态
    enum NetworkError: Error {
        case connectionFailed
        case invalidResponse
        case notFound
    }
    
    // 模拟网络延迟
    private func simulateNetworkDelay(completion: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completion()
        }
    }
    
    // 获取推荐歌曲
    func fetchRecommendedSongs(completion: @escaping ([Song]) -> Void) {
        simulateNetworkDelay {
            completion(self.mockSongs)
        }
    }
    
    // 获取热门歌单
    func fetchFeaturedPlaylists(completion: @escaping ([Playlist]) -> Void) {
        simulateNetworkDelay {
            completion(self.mockPlaylists)
        }
    }
    
    // 搜索歌曲
    func searchSongs(query: String, completion: @escaping ([Song]) -> Void) {
        simulateNetworkDelay {
            let filteredSongs = self.mockSongs.filter { $0.title.lowercased().contains(query.lowercased()) || 
                                                    $0.artist.lowercased().contains(query.lowercased()) }
            completion(filteredSongs)
        }
    }
    
    // 搜索歌单
    func searchPlaylists(query: String, completion: @escaping ([Playlist]) -> Void) {
        simulateNetworkDelay {
            let filteredPlaylists = self.mockPlaylists.filter { $0.name.lowercased().contains(query.lowercased()) }
            completion(filteredPlaylists)
        }
    }
    
    // 获取分类歌单
    func fetchCategoryPlaylists(category: String, completion: @escaping ([Playlist]) -> Void) {
        simulateNetworkDelay {
            // 简单模拟不同类别的歌单
            let filteredPlaylists = self.mockPlaylists.prefix(3)
            completion(Array(filteredPlaylists))
        }
    }
    
    // 模拟数据 - 歌曲
    private var mockSongs: [Song] = [
        Song(title: "晴天", artist: "周杰伦", album: "叶惠美", coverURL: "https://example.com/cover1.jpg", duration: 269),
        Song(title: "稻香", artist: "周杰伦", album: "魔杰座", coverURL: "https://example.com/cover2.jpg", duration: 234),
        Song(title: "倒影", artist: "陈奕迅", album: "rice & shine", coverURL: "https://example.com/cover3.jpg", duration: 294),
        Song(title: "爱情转移", artist: "陈奕迅", album: "不想放手", coverURL: "https://example.com/cover4.jpg", duration: 282),
        Song(title: "起风了", artist: "买辣椒也用券", album: "起风了", coverURL: "https://example.com/cover5.jpg", duration: 325),
        Song(title: "光年之外", artist: "邓紫棋", album: "光年之外", coverURL: "https://example.com/cover6.jpg", duration: 235),
        Song(title: "平凡之路", artist: "朴树", album: "猎户星座", coverURL: "https://example.com/cover7.jpg", duration: 256),
        Song(title: "我和我的祖国", artist: "王菲", album: "我和我的祖国", coverURL: "https://example.com/cover8.jpg", duration: 240)
    ]
    
    // 模拟数据 - 歌单
    private var mockPlaylists: [Playlist] = [
        Playlist(name: "华语经典", description: "永恒的华语经典歌曲合集", coverURL: "https://example.com/playlist1.jpg"),
        Playlist(name: "流行热歌", description: "当下最流行的热门歌曲", coverURL: "https://example.com/playlist2.jpg"),
        Playlist(name: "轻音乐", description: "舒缓心情的轻音乐精选", coverURL: "https://example.com/playlist3.jpg"),
        Playlist(name: "运动健身", description: "激发活力的运动歌单", coverURL: "https://example.com/playlist4.jpg"),
        Playlist(name: "学习工作", description: "提高效率的背景音乐", coverURL: "https://example.com/playlist5.jpg")
    ]
    
    // 模拟数据 - 专辑
    private var mockAlbums: [Album] = [
        Album(
            title: "叶惠美",
            artist: "周杰伦",
            releaseDate: Calendar.current.date(from: DateComponents(year: 2003, month: 7, day: 31)),
            coverURL: "https://example.com/album1.jpg",
            description: "《叶惠美》是周杰伦发行的第四张专辑，收录了《晴天》、《东风破》等经典歌曲。"
        ),
        Album(
            title: "魔杰座",
            artist: "周杰伦",
            releaseDate: Calendar.current.date(from: DateComponents(year: 2008, month: 10, day: 14)),
            coverURL: "https://example.com/album2.jpg",
            description: "《魔杰座》是周杰伦发行的第九张专辑，收录了《稻香》、《给我一首歌的时间》等歌曲。"
        ),
        Album(
            title: "rice & shine",
            artist: "陈奕迅",
            releaseDate: Calendar.current.date(from: DateComponents(year: 2014, month: 7, day: 11)),
            coverURL: "https://example.com/album3.jpg",
            description: "《rice & shine》是陈奕迅发行的专辑，收录了《倒影》等歌曲。"
        )
    ]
    
    // 获取歌曲详情
    func fetchSongDetails(songId: UUID, completion: @escaping (Result<Song, Error>) -> Void) {
        simulateNetworkDelay {
            if let song = self.mockSongs.first(where: { $0.id == songId }) {
                completion(.success(song))
            } else {
                completion(.failure(NetworkError.notFound))
            }
        }
    }
    
    // 获取专辑详情
    func fetchAlbumDetails(albumId: UUID, completion: @escaping (Result<Album, Error>) -> Void) {
        simulateNetworkDelay {
            if let album = self.mockAlbums.first(where: { $0.id == albumId }) {
                // 为专辑添加歌曲
                var albumWithSongs = album
                albumWithSongs.songs = self.mockSongs.filter { $0.album == album.title }
                completion(.success(albumWithSongs))
            } else {
                completion(.failure(NetworkError.notFound))
            }
        }
    }
    
    // 获取歌词
    func fetchLyrics(songId: UUID, completion: @escaping (Result<String, Error>) -> Void) {
        simulateNetworkDelay {
            // 模拟歌词数据
            let mockLyrics = "[00:00.00] 作词 : 方文山\n[00:01.00] 作曲 : 周杰伦\n[00:02.00] 编曲 : 周杰伦\n[00:03.00]\n[00:04.00] 歌词第一行\n[00:08.00] 歌词第二行\n[00:12.00] 歌词第三行\n[00:16.00] 歌词第四行"
            
            if self.mockSongs.contains(where: { $0.id == songId }) {
                completion(.success(mockLyrics))
            } else {
                completion(.failure(NetworkError.notFound))
            }
        }
    }
    
    // 播放歌曲
    func playSong(song: Song, completion: @escaping (Bool) -> Void) {
        simulateNetworkDelay {
            // 实际项目中应调用音频播放API
            print("播放歌曲: \(song.title)")
            completion(true)
        }
    }
    
    // 播放专辑
    func playAlbum(album: Album, completion: @escaping (Bool) -> Void) {
        simulateNetworkDelay {
            // 实际项目中应调用音频播放API
            print("播放专辑: \(album.title)")
            completion(true)
        }
    }
}