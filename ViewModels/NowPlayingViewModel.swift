import Foundation
import Combine
import AVFoundation

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
    @Published var queue: [Song] = []
    
    private var progressUpdateTimer: Timer?
    
    init() {
        // 初始化播放器
        setupPlayer()
        // 监听播放状态变化
        setupNotifications()
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
        if isPlaying {
            audioPlayerService.pause()
        } else {
            if audioPlayerService.currentSong != nil {
                audioPlayerService.resume()
            } else if let firstSong = queue.first {
                audioPlayerService.play(song: firstSong)
            }
        }
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
    
    deinit {
        stopProgressUpdateTimer()
        NotificationCenter.default.removeObserver(self)
    }
}