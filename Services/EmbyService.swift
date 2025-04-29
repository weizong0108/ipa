//
//  EmbyService.swift
//  Aurora Music
//
//  提供与Emby媒体服务器连接的功能
//  包括服务器发现、认证和媒体获取
//

import Foundation

class EmbyService {
    // 单例实例
    static let shared = EmbyService()
    private init() {}
    
    // Emby服务器连接信息
    private var baseUrl: String? = nil
    private var apiKey: String? = nil
    private var userId: String? = nil
    private var deviceId: String = "AuroraMusic_" + UUID().uuidString
    
    // 连接状态
    private(set) var isConnected: Bool = false
    private(set) var serverInfo: [String: Any]? = nil
    
    // 网络错误类型
    enum EmbyError: Error {
        case notConnected
        case authenticationFailed
        case invalidResponse
        case networkError(Error)
        case serverError(String)
        
        var localizedDescription: String {
            switch self {
            case .notConnected:
                return "未连接到Emby服务器"
            case .authenticationFailed:
                return "认证失败"
            case .invalidResponse:
                return "服务器响应无效"
            case .networkError(let error):
                return "网络错误: \(error.localizedDescription)"
            case .serverError(let message):
                return "服务器错误: \(message)"
            }
        }
    }
    
    // MARK: - 连接管理
    
    /// 连接到Emby服务器
    /// - Parameter serverUrl: 服务器URL
    /// - Returns: 服务器信息
    func connectToServer(serverUrl: String) async throws -> [String: Any] {
        // 确保URL格式正确
        var url = serverUrl
        if !url.lowercased().hasPrefix("http") {
            url = "http://" + url
        }
        
        // 移除URL末尾的斜杠
        if url.hasSuffix("/") {
            url.removeLast()
        }
        
        self.baseUrl = url
        
        // 构建请求URL
        guard let requestUrl = URL(string: "\(url)/System/Info/Public") else {
            throw EmbyError.invalidResponse
        }
        
        do {
            // 创建URLRequest
            var request = URLRequest(url: requestUrl)
            request.httpMethod = "GET"
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            // 发送请求
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // 检查响应状态码
            guard let httpResponse = response as? HTTPURLResponse else {
                throw EmbyError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw EmbyError.serverError("服务器返回错误: \(httpResponse.statusCode)")
            }
            
            // 解析JSON响应
            guard let info = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw EmbyError.invalidResponse
            }
            
            self.serverInfo = info
            return info
        } catch let error as EmbyError {
            throw error
        } catch {
            throw EmbyError.networkError(error)
        }
    }
    
    /// 用户登录
    /// - Parameters:
    ///   - username: 用户名
    ///   - password: 密码
    /// - Returns: 登录结果
    func login(username: String, password: String) async throws -> [String: Any] {
        guard let baseUrl = self.baseUrl else {
            throw EmbyError.notConnected
        }
        
        // 构建请求URL
        guard let requestUrl = URL(string: "\(baseUrl)/Users/AuthenticateByName") else {
            throw EmbyError.invalidResponse
        }
        
        do {
            // 创建请求体
            let body: [String: Any] = [
                "Username": username,
                "Pw": password,
                "DeviceId": deviceId,
                "DeviceName": "Aurora Music App",
                "AppName": "Aurora Music",
                "AppVersion": "1.0"
            ]
            
            // 将请求体转换为JSON数据
            let jsonData = try JSONSerialization.data(withJSONObject: body)
            
            // 创建URLRequest
            var request = URLRequest(url: requestUrl)
            request.httpMethod = "POST"
            request.httpBody = jsonData
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            // 发送请求
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // 检查响应状态码
            guard let httpResponse = response as? HTTPURLResponse else {
                throw EmbyError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                if httpResponse.statusCode == 401 {
                    throw EmbyError.authenticationFailed
                } else {
                    throw EmbyError.serverError("服务器返回错误: \(httpResponse.statusCode)")
                }
            }
            
            // 解析JSON响应
            guard let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let user = responseDict["User"] as? [String: Any],
                  let userId = user["Id"] as? String,
                  let accessToken = responseDict["AccessToken"] as? String else {
                throw EmbyError.invalidResponse
            }
            
            // 保存登录信息
            self.apiKey = accessToken
            self.userId = userId
            self.isConnected = true
            
            return responseDict
        } catch let error as EmbyError {
            throw error
        } catch {
            throw EmbyError.networkError(error)
        }
    }
    
    /// 断开连接
    func disconnect() {
        self.baseUrl = nil
        self.apiKey = nil
        self.userId = nil
        self.isConnected = false
        self.serverInfo = nil
    }
    
    // MARK: - 媒体获取
    
    /// 获取音乐库
    /// - Returns: 音乐库列表
    func getMusicLibraries() async throws -> [[String: Any]] {
        guard isConnected, let _ = self.apiKey else {
            throw EmbyError.notConnected
        }
        
        // 在实际应用中，这里应该使用URLSession发起网络请求
        // 这里使用模拟数据进行演示
        do {
            // 模拟网络延迟
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
            
            // 模拟音乐库数据
            return [
                [
                    "Name": "音乐库",
                    "CollectionType": "music",
                    "ItemId": "music123",
                    "LibraryOptions": [
                        "ContentType": "Audio"
                    ]
                ],
                [
                    "Name": "播客",
                    "CollectionType": "music",
                    "ItemId": "podcast123",
                    "LibraryOptions": [
                        "ContentType": "Audio"
                    ]
                ]
            ]
        } catch {
            throw EmbyError.networkError(error)
        }
    }
    
    /// 获取音乐
    /// - Parameters:
    ///   - libraryId: 音乐库ID
    ///   - options: 查询选项
    /// - Returns: 音乐列表
    func getMusic(libraryId: String, options: [String: Any] = [:]) async throws -> [[String: Any]] {
        guard isConnected, let _ = self.apiKey else {
            throw EmbyError.notConnected
        }
        
        // 在实际应用中，这里应该使用URLSession发起网络请求
        // 这里使用模拟数据进行演示
        do {
            // 模拟网络延迟
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
            
            // 检查是否请求专辑
            if options["IncludeItemTypes"] as? String == "MusicAlbum" {
                // 模拟专辑数据
                return [
                    [
                        "Name": "叶惠美",
                        "Id": "album1",
                        "Type": "MusicAlbum",
                        "Artists": ["周杰伦"]
                    ],
                    [
                        "Name": "魔杰座",
                        "Id": "album2",
                        "Type": "MusicAlbum",
                        "Artists": ["周杰伦"]
                    ]
                ]
            } else if options["IncludeItemTypes"] as? String == "MusicArtist" {
                // 模拟艺术家数据
                return [
                    [
                        "Name": "周杰伦",
                        "Id": "artist1",
                        "Type": "MusicArtist"
                    ],
                    [
                        "Name": "陈奕迅",
                        "Id": "artist2",
                        "Type": "MusicArtist"
                    ]
                ]
            } else {
                // 模拟歌曲数据
                return [
                    [
                        "Name": "晴天",
                        "Id": "song1",
                        "Type": "Audio",
                        "Artists": ["周杰伦"],
                        "Album": "叶惠美"
                    ],
                    [
                        "Name": "稻香",
                        "Id": "song2",
                        "Type": "Audio",
                        "Artists": ["周杰伦"],
                        "Album": "魔杰座"
                    ]
                ]
            }
        } catch {
            throw EmbyError.networkError(error)
        }
    }
    
    /// 获取专辑
    /// - Parameter libraryId: 音乐库ID
    /// - Returns: 专辑列表
    func getAlbums(libraryId: String) async throws -> [[String: Any]] {
        return try await getMusic(libraryId: libraryId, options: ["IncludeItemTypes": "MusicAlbum"])
    }
    
    /// 获取艺术家
    /// - Parameter libraryId: 音乐库ID
    /// - Returns: 艺术家列表
    func getArtists(libraryId: String) async throws -> [[String: Any]] {
        return try await getMusic(libraryId: libraryId, options: ["IncludeItemTypes": "MusicArtist"])
    }
    
    /// 搜索
    /// - Parameter query: 搜索关键词
    /// - Returns: 搜索结果
    func search(query: String) async throws -> [String: Any] {
        guard isConnected, let _ = self.apiKey else {
            throw EmbyError.notConnected
        }
        
        // 在实际应用中，这里应该使用URLSession发起网络请求
        // 这里使用模拟数据进行演示
        do {
            // 模拟网络延迟
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
            
            // 模拟搜索结果
            return [
                "SearchHints": [
                    [
                        "Name": "晴天",
                        "Id": "song1",
                        "Type": "Audio",
                        "Artists": ["周杰伦"],
                        "Album": "叶惠美"
                    ]
                ],
                "TotalRecordCount": 1
            ]
        } catch {
            throw EmbyError.networkError(error)
        }
    }
    
    // MARK: - 辅助方法
    
    /// 获取歌曲播放URL
    /// - Parameter itemId: 歌曲ID
    /// - Returns: 播放URL
    func getPlaybackUrl(itemId: String) -> String? {
        guard let baseUrl = self.baseUrl, let apiKey = self.apiKey else {
            return nil
        }
        
        return "\(baseUrl)/Audio/\(itemId)/stream?api_key=\(apiKey)&DeviceId=\(deviceId)"
    }
    
    /// 获取图片URL
    /// - Parameters:
    ///   - itemId: 项目ID
    ///   - imageType: 图片类型
    /// - Returns: 图片URL
    func getImageUrl(itemId: String, imageType: String = "Primary") -> String? {
        guard let baseUrl = self.baseUrl else {
            return nil
        }
        
        return "\(baseUrl)/Items/\(itemId)/Images/\(imageType)"
    }
    
    // MARK: - 数据转换
    
    /// 将Emby歌曲数据转换为应用内Song模型
    /// - Parameter embyItem: Emby歌曲数据
    /// - Returns: Song模型
    func convertToSong(embyItem: [String: Any]) -> Song? {
        guard let id = embyItem["Id"] as? String,
              let title = embyItem["Name"] as? String else {
            return nil
        }
        
        let artist = (embyItem["Artists"] as? [String])?.first ?? "未知艺术家"
        let album = embyItem["Album"] as? String ?? "未知专辑"
        
        // 获取封面URL
        let coverURL = getImageUrl(itemId: id) ?? "https://example.com/default-cover.jpg"
        
        // 获取时长（秒）
        let duration = embyItem["RunTimeTicks"] as? Int64 ?? 0
        let durationInSeconds = Int(duration / 10000000) // 转换为秒
        
        return Song(
            title: title,
            artist: artist,
            album: album,
            coverURL: coverURL,
            duration: durationInSeconds
        )
    }
    
    /// 将Emby专辑数据转换为应用内Album模型
    /// - Parameter embyItem: Emby专辑数据
    /// - Returns: Album模型
    func convertToAlbum(embyItem: [String: Any]) -> Album? {
        guard let id = embyItem["Id"] as? String,
              let title = embyItem["Name"] as? String else {
            return nil
        }
        
        let artist = (embyItem["Artists"] as? [String])?.first ?? "未知艺术家"
        
        // 获取封面URL
        let coverURL = getImageUrl(itemId: id) ?? "https://example.com/default-cover.jpg"
        
        // 获取发行日期
        let premiereDate = embyItem["PremiereDate"] as? String
        let dateFormatter = ISO8601DateFormatter()
        let releaseDate = premiereDate != nil ? dateFormatter.date(from: premiereDate!) : nil
        
        return Album(
            title: title,
            artist: artist,
            releaseDate: releaseDate,
            coverURL: coverURL,
            description: embyItem["Overview"] as? String ?? ""
        )
    }
    
    /// 将Emby播放列表数据转换为应用内Playlist模型
    /// - Parameter embyItem: Emby播放列表数据
    /// - Returns: Playlist模型
    func convertToPlaylist(embyItem: [String: Any]) -> Playlist? {
        guard let id = embyItem["Id"] as? String,
              let name = embyItem["Name"] as? String else {
            return nil
        }
        
        // 获取封面URL
        let coverURL = getImageUrl(itemId: id) ?? "https://example.com/default-cover.jpg"
        
        return Playlist(
            name: name,
            description: embyItem["Overview"] as? String ?? "",
            coverURL: coverURL
        )
    }
}

// MARK: - 扩展MusicService以支持Emby
extension MusicService {
    // 音乐来源类型
    enum MusicSource {
        case local // 本地/模拟数据
        case emby  // Emby服务器
    }
    
    // 当前音乐来源
    private(set) var currentSource: MusicSource = .local
    
    // 切换到Emby音乐源
    func switchToEmbySource() {
        self.currentSource = .emby
    }
    
    // 切换到本地音乐源
    func switchToLocalSource() {
        self.currentSource = .local
    }
    
    // 从Emby获取推荐歌曲
    func fetchRecommendedSongsFromEmby(completion: @escaping ([Song]) -> Void) {
        Task {
            do {
                // 获取音乐库
                let libraries = try await EmbyService.shared.getMusicLibraries()
                guard let firstLibrary = libraries.first, let libraryId = firstLibrary["ItemId"] as? String else {
                    completion([])
                    return
                }
                
                // 获取最近添加的音乐
                let embyItems = try await EmbyService.shared.getMusic(libraryId: libraryId, options: [
                    "SortBy": "DateCreated,SortName",
                    "SortOrder": "Descending",
                    "Limit": 10
                ])
                
                // 转换为Song模型
                let songs = embyItems.compactMap { EmbyService.shared.convertToSong(embyItem: $0) }
                
                // 在主线程返回结果
                DispatchQueue.main.async {
                    completion(songs)
                }
            } catch {
                print("从Emby获取推荐歌曲失败: \(error)")
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }
    }
    
    // 从Emby获取热门歌单/专辑
    func fetchFeaturedPlaylistsFromEmby(completion: @escaping ([Playlist]) -> Void) {
        Task {
            do {
                // 获取音乐库
                let libraries = try await EmbyService.shared.getMusicLibraries()
                guard let firstLibrary = libraries.first, let libraryId = firstLibrary["ItemId"] as? String else {
                    completion([])
                    return
                }
                
                // 获取专辑
                let embyAlbums = try await EmbyService.shared.getAlbums(libraryId: libraryId)
                
                // 将专辑转换为播放列表
                let playlists = embyAlbums.compactMap { album -> Playlist? in
                    guard let id = album["Id"] as? String,
                          let name = album["Name"] as? String else {
                        return nil
                    }
                    
                    let artist = (album["Artists"] as? [String])?.first ?? "未知艺术家"
                    let coverURL = EmbyService.shared.getImageUrl(itemId: id) ?? "https://example.com/default-cover.jpg"
                    
                    return Playlist(
                        name: name,
                        description: "\(artist)的专辑",
                        coverURL: coverURL
                    )
                }
                
                // 在主线程返回结果
                DispatchQueue.main.async {
                    completion(playlists)
                }
            } catch {
                print("从Emby获取热门歌单失败: \(error)")
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }
    }
    
    // 重写获取推荐歌曲方法，支持多音乐源
    func fetchRecommendedSongs(completion: @escaping ([Song]) -> Void) {
        switch currentSource {
        case .local:
            // 使用原有的模拟数据
            simulateNetworkDelay {
                completion(self.mockSongs)
            }
        case .emby:
            // 从Emby获取数据
            fetchRecommendedSongsFromEmby(completion: completion)
        }
    }
    
    // 重写获取热门歌单方法，支持多音乐源
    func fetchFeaturedPlaylists(completion: @escaping ([Playlist]) -> Void) {
        switch currentSource {
        case .local:
            // 使用原有的模拟数据
            simulateNetworkDelay {
                completion(self.mockPlaylists)
            }
        case .emby:
            // 从Emby获取数据
            fetchFeaturedPlaylistsFromEmby(completion: completion)
        }
    }
}