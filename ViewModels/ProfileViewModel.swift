import Foundation
import Combine

struct UserProfile {
    var id: String
    var username: String
    var email: String?
    var avatarURL: String?
}

struct MenuOption {
    var title: String
    var icon: String
}

class ProfileViewModel: ObservableObject {
    private var musicService = MusicService.shared
    private var embyService = EmbyService.shared
    private var cancellables = Set<AnyCancellable>()
    
    @Published var userProfile: UserProfile?
    @Published var showLoginView: Bool = false
    @Published var showEmbyConnectView: Bool = false
    
    // Emby服务器连接相关状态
    @Published var serverUrl: String = ""
    @Published var embyUsername: String = ""
    @Published var embyPassword: String = ""
    @Published var isConnecting: Bool = false
    @Published var connectionError: String? = nil
    @Published var isEmbyConnected: Bool = false
    @Published var embyServerInfo: [String: Any]? = nil
    
    // 我的音乐选项
    let myMusicOptions: [MenuOption] = [
        MenuOption(title: "我喜欢的音乐", icon: "heart.fill"),
        MenuOption(title: "最近播放", icon: "clock.fill"),
        MenuOption(title: "我的歌单", icon: "music.note.list"),
        MenuOption(title: "本地音乐", icon: "arrow.down.circle.fill"),
        MenuOption(title: "NAS音乐库", icon: "server.rack")
    ]
    
    // 设置选项
    let settingsOptions: [MenuOption] = [
        MenuOption(title: "账户设置", icon: "person.crop.circle"),
        MenuOption(title: "通知设置", icon: "bell.fill"),
        MenuOption(title: "播放设置", icon: "speaker.wave.2.fill"),
        MenuOption(title: "服务器设置", icon: "network"),
        MenuOption(title: "关于", icon: "info.circle.fill")
    ]
    
    init() {
        // 检查用户登录状态
        checkLoginStatus()
        // 检查Emby服务器连接状态
        checkEmbyConnectionStatus()
    }
    
    func checkLoginStatus() {
        // 在实际应用中，这里会检查用户是否已登录
        // 如果已登录，则获取用户信息
        // 这里仅作为示例
        userProfile = nil
    }
    
    func checkEmbyConnectionStatus() {
        // 检查Emby服务器连接状态
        isEmbyConnected = embyService.isConnected
        embyServerInfo = embyService.serverInfo
    }
    
    func login(username: String, password: String, completion: @escaping (Bool) -> Void) {
        // 在实际应用中，这里会调用登录API
        // 这里仅作为示例
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.userProfile = UserProfile(id: "1", username: username, email: "\(username)@example.com")
            completion(true)
        }
    }
    
    func logout() {
        // 在实际应用中，这里会调用登出API
        // 这里仅作为示例
        userProfile = nil
    }
    
    // MARK: - Emby服务器连接
    
    /// 连接到Emby服务器
    func connectToEmbyServer() async {
        guard !serverUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            connectionError = "请输入服务器地址"
            return
        }
        
        isConnecting = true
        connectionError = nil
        
        do {
            // 连接到服务器
            let serverInfo = try await embyService.connectToServer(serverUrl: serverUrl)
            embyServerInfo = serverInfo
            
            // 如果提供了用户名和密码，则尝试登录
            if !embyUsername.isEmpty && !embyPassword.isEmpty {
                let _ = try await embyService.login(username: embyUsername, password: embyPassword)
            }
            
            isEmbyConnected = embyService.isConnected
            isConnecting = false
        } catch {
            isConnecting = false
            connectionError = error.localizedDescription
        }
    }
    
    /// 断开Emby服务器连接
    func disconnectEmbyServer() {
        embyService.disconnect()
        isEmbyConnected = false
        embyServerInfo = nil
        serverUrl = ""
        embyUsername = ""
        embyPassword = ""
    }
}