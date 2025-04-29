import Foundation
import Combine
import AVFoundation
import MediaPlayer

// 使用与AudioPlayerService相同的枚举名称
enum RepeatMode {
    case none
    case all
    case one
    
    // 转换为AudioPlayerService的RepeatMode
    func toAudioPlayerRepeatMode() -> AudioPlayerService.RepeatMode {
        switch self {
        case .none: return .off
        case .all: return .all
        case .one: return .one
        }
    }
    
    // 从AudioPlayerService的RepeatMode转换
    static func fromAudioPlayerRepeatMode(_ mode: AudioPlayerService.RepeatMode) -> RepeatMode {
        switch mode {
        case .off: return .none
        case .all: return .all
        case .one: return .one
        }
    }
}

class NowPlayingViewModel: ObservableObject {
    private var musicService = MusicService.shared
    private var audioPlayerService = AudioPlayerService.shared
    private var cancellables = Set<AnyCancellable>()
    
    @Published var currentSong: Song?
    @Published var isPlaying: Bool = false
    @Published var progress: Double = 0.0
    @Published var currentTime: TimeInterval = 0
    @Published var isSeeking: Bool = false
    @Published var isShuffleOn: Bool = false
    @Published var repeatMode: RepeatMode = .none
    @Published var lyrics: [LyricLine] = []
    @Published var downloadProgress: Double = 0
    @Published var isDownloaded: Bool = false
    @Published var equalizerSettings: EqualizerSettings = .default
    @Published var queue: [Song] = []
    
    private var progressUpdateTimer: Timer?
    private var player: AVPlayer?
    private var timeObserver: Any?
    private var downloadTask: URLSessionDownloadTask?
    private let equalizer: AVAudioEqualizerNode = AVAudioEqualizerNode()
    
    init() {
        // 初始化播放器
        setupPlayer()
        // 监听播放状态变化
        setupNotifications()
        setupAudioSession()
        setupRemoteControls()
    }
    
    private func setupPlayer() {
        // 从AudioPlayerService同步初始状态
        updateStateFromAudioPlayer()
    }
    
    private func setupNotifications() {
        // 监听播放状态变化通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioPlayerStateChanged),
            name: .audioPlayerStateChanged,
            object: nil
        )
    }
    
    @objc private func handleAudioPlayerStateChanged() {
        // 当播放状态变化时，更新ViewModel的状态
        updateStateFromAudioPlayer()
    }
    
    private func updateStateFromAudioPlayer() {
        // 从AudioPlayerService同步状态
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.currentSong = self.audioPlayerService.currentSong
            self.isPlaying = self.audioPlayerService.isPlaying
            self.isShuffleOn = self.audioPlayerService.isShuffleOn
            self.repeatMode = RepeatMode.fromAudioPlayerRepeatMode(self.audioPlayerService.repeatMode)
            self.queue = self.audioPlayerService.queue
            
            // 更新进度和时间
            self.progress = self.audioPlayerService.currentProgress
            self.currentTime = self.audioPlayerService.currentTime
            
            // 如果正在播放，启动进度更新定时器
            if self.isPlaying {
                self.startProgressUpdateTimer()
            } else {
                self.stopProgressUpdateTimer()
            }
        }
    }
    
    func togglePlayPause() {
        isPlaying.toggle()
        if isPlaying {
            player?.play()
        } else {
            player?.pause()
        }
        updateNowPlayingInfo()
    }
    
    func previous() {
        audioPlayerService.playPrevious()
    }
    
    func next() {
        audioPlayerService.playNext()
    }
    
    func toggleShuffle() {
        audioPlayerService.toggleShuffle()
    }
    
    func toggleRepeat() {
        audioPlayerService.toggleRepeatMode()
    }
    
    private func startProgressUpdateTimer() {
        progressUpdateTimer?.invalidate()
        progressUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, !self.isSeeking else { return }
            
            // 更新进度和时间
            self.progress = self.audioPlayerService.currentProgress
            self.currentTime = self.audioPlayerService.currentTime
        }
    }
    
    private func stopProgressUpdateTimer() {
        progressUpdateTimer?.invalidate()
        progressUpdateTimer = nil
    }
    
    // 处理进度条拖动
    func seekToPosition(progress: Double) {
        if let duration = currentSong?.duration {
            let targetTime = duration * progress
            audioPlayerService.seek(to: targetTime)
        }
    }
    
    // 加载歌曲到播放队列
    func loadSongs(_ songs: [Song], startIndex: Int = 0) {
        audioPlayerService.setQueue(songs: songs, startIndex: startIndex)
    }
    
    // 添加歌曲到播放队列
    func addToQueue(song: Song) {
        audioPlayerService.addToQueue(song: song)
    }
    
    // 下载功能
    func downloadSong() {
        guard let song = currentSong,
              let url = URL(string: song.audioURL) else { return }
        
        let session = URLSession(configuration: .default)
        downloadTask = session.downloadTask(with: url) { [weak self] localURL, response, error in
            guard let self = self,
                  let localURL = localURL,
                  error == nil else { return }
            
            // 将文件移动到永久存储位置
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let destinationURL = documentsPath.appendingPathComponent("\(song.id).mp3")
            
            do {
                if FileManager.default.fileExists(at: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                try FileManager.default.moveItem(at: localURL, to: destinationURL)
                DispatchQueue.main.async {
                    self.isDownloaded = true
                }
            } catch {
                print("Error saving file: \(error)")
            }
        }
        
        downloadTask?.resume()
    }
    
    // 均衡器设置
    func updateEqualizerSettings(_ settings: EqualizerSettings) {
        self.equalizerSettings = settings
        equalizer.bands.enumerated().forEach { index, band in
            band.gain = settings.bands[index]
        }
    }
    
    // 歌词加载
    func loadLyrics() {
        guard let song = currentSong else { return }
        // 这里应该从服务器或本地加载歌词
        // 示例数据
        lyrics = [
            LyricLine(timestamp: 0, text: "第一行歌词"),
            LyricLine(timestamp: 3, text: "第二行歌词"),
            // ... 更多歌词
        ]
    }
    
    // 更新正在播放信息
    private func updateNowPlayingInfo() {
        guard let song = currentSong else { return }
        
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = song.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = song.artist
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = song.album
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = song.duration
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    // 设置远程控制
    private func setupRemoteControls() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }
        
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.previous()
            return .success
        }
        
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.next()
            return .success
        }
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    deinit {
        stopProgressUpdateTimer()
        NotificationCenter.default.removeObserver(self)
    }
}

// 均衡器设置模型
struct EqualizerSettings {
    var bands: [Float]
    
    static let `default` = EqualizerSettings(bands: [0, 0, 0, 0, 0])
    
    static let bass = EqualizerSettings(bands: [4, 3, 0, 0, 0])
    static let treble = EqualizerSettings(bands: [0, 0, 0, 3, 4])
    static let vocal = EqualizerSettings(bands: [-2, 3, 4, 3, -2])
}