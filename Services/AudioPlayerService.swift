import Foundation
import AVFoundation
import MediaPlayer

enum RepeatMode {
    case off, one, all
}

class AudioPlayerService {
    // 单例模式
    static let shared = AudioPlayerService()
    
    // 播放器
    private var player: AVQueuePlayer?
    private var playerItems: [AVPlayerItem] = []
    private var currentItemObserver: NSKeyValueObservation?
    private var timeObserver: Any?
    
    // 音频引擎
    private let audioEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    
    // 当前播放状态
    private(set) var isPlaying: Bool = false
    
    // 当前播放的歌曲
    private(set) var currentSong: Song?
    
    // 播放队列
    private(set) var queue: [Song] = []
    
    // 播放模式
    private(set) var repeatMode: RepeatMode = .off
    
    // 是否随机播放
    private(set) var isShuffleOn: Bool = false
    
    // 预缓冲配置
    private let prebufferDuration: TimeInterval = 15.0 // 预缓冲15秒
    private var isPreBuffering = false
    
    // 音频格式
    private let outputFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)
    
    private init() {
        setupAudioSession()
        setupAudioEngine()
    }
    
    // 设置音频会话
    private func setupAudioSession() {
        do {
            // 设置为后台播放模式
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetooth])
            try AVAudioSession.sharedInstance().setActive(true)
            
            // 设置远程控制事件接收
            setupRemoteTransportControls()
            
            // 设置锁屏/控制中心信息显示
            setupNowPlaying()
        } catch {
            print("设置音频会话失败: \(error)")
        }
    }
    
    // 设置音频引擎
    private func setupAudioEngine() {
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: outputFormat)
        
        do {
            try audioEngine.start()
        } catch {
            print("启动音频引擎失败: \(error)")
        }
    }
    
    // 设置远程控制事件
    private func setupRemoteTransportControls() {
        // 获取远程控制中心
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // 添加播放/暂停处理
        commandCenter.playCommand.addTarget { [weak self] event in
            guard let self = self else { return .commandFailed }
            if !self.isPlaying {
                self.resume()
                return .success
            }
            return .commandFailed
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] event in
            guard let self = self else { return .commandFailed }
            if self.isPlaying {
                self.pause()
                return .success
            }
            return .commandFailed
        }
        
        // 添加上一首/下一首处理
        commandCenter.previousTrackCommand.addTarget { [weak self] event in
            guard let self = self else { return .commandFailed }
            self.playPrevious()
            return .success
        }
        
        commandCenter.nextTrackCommand.addTarget { [weak self] event in
            guard let self = self else { return .commandFailed }
            self.playNext()
            return .success
        }
        
        // 添加进度控制
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self = self,
                  let event = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            self.seek(to: event.positionTime)
            return .success
        }
    }
    
    // 更新锁屏/控制中心信息
    private func setupNowPlaying() {
        // 初始化为空信息
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [String: Any]()
    }
    
    // 更新当前播放信息
    private func updateNowPlayingInfo() {
        guard let currentSong = currentSong else { return }
        
        var nowPlayingInfo = [String: Any]()
        
        // 设置歌曲信息
        nowPlayingInfo[MPMediaItemPropertyTitle] = currentSong.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = currentSong.artist
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = currentSong.album ?? ""
        
        // 设置播放时间信息
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        
        // 如果有封面图片，设置封面
        if let coverURLString = currentSong.coverURL, let coverURL = URL(string: coverURLString) {
            // 实际项目中应异步加载图片并设置
            // 这里仅作为示例
            // 可以使用URLSession或第三方库加载图片
        }
        
        // 更新播放信息
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    // 播放音频
    func play(_ song: Song) {
        guard let url = URL(string: song.audioURL) else { return }
        
        // 检查缓存
        if let cachedURL = AudioCacheManager.shared.getCachedAudio(for: url) {
            playFromURL(cachedURL)
        } else {
            // 开始下载并缓存
            AudioCacheManager.shared.cacheAudio(from: url) { [weak self] result in
                switch result {
                case .success(let cachedURL):
                    self?.playFromURL(cachedURL)
                case .failure(let error):
                    print("缓存音频失败: \(error)")
                }
            }
        }
        
        currentSong = song
        
        // 预加载队列中的下一首歌
        preloadNextSongs()
    }
    
    // 从URL播放
    private func playFromURL(_ url: URL) {
        guard let asset = try? AVAudioFile(forReading: url) else { return }
        
        // 检查音频格式是否需要转换
        if asset.processingFormat != outputFormat {
            convertAndPlay(asset)
        } else {
            playAudioFile(asset)
        }
    }
    
    // 转换并播放音频
    private func convertAndPlay(_ audioFile: AVAudioFile) {
        let format = audioFile.processingFormat
        let outputFormat = self.outputFormat!
        
        do {
            let frameCount = AVAudioFrameCount(audioFile.length)
            let inputBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
            try audioFile.read(into: inputBuffer)
            
            let converter = AVAudioConverter(from: format, to: outputFormat)!
            let ratio = Float(outputFormat.sampleRate) / Float(format.sampleRate)
            let outputFrameCapacity = AVAudioFrameCount(Float(frameCount) * ratio)
            let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: outputFrameCapacity)!
            
            var error: NSError?
            let status = converter.convert(to: outputBuffer, error: &error) { inNumPackets, outStatus in
                outStatus.pointee = .haveData
                return inputBuffer
            }
            
            if status == .haveData {
                playerNode.scheduleBuffer(outputBuffer) {
                    self.isPlaying = true
                }
                playerNode.play()
            }
        } catch {
            print("转换音频格式失败: \(error)")
        }
    }
    
    // 直接播放音频文件
    private func playAudioFile(_ audioFile: AVAudioFile) {
        do {
            let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: AVAudioFrameCount(audioFile.length))!
            try audioFile.read(into: buffer)
            
            playerNode.scheduleBuffer(buffer) {
                self.isPlaying = true
            }
            playerNode.play()
        } catch {
            print("播放音频文件失败: \(error)")
        }
    }
    
    // 预加载下一首歌
    private func preloadNextSongs() {
        guard let currentIndex = queue.firstIndex(where: { $0.id == currentSong?.id }),
              currentIndex + 1 < queue.count else { return }
        
        let nextSongs = Array(queue[currentIndex + 1..<min(currentIndex + 3, queue.count)])
        let urls = nextSongs.compactMap { URL(string: $0.audioURL) }
        
        AudioCacheManager.shared.preloadAudio(urls: urls)
    }
    
    // 暂停
    func pause() {
        playerNode.pause()
        isPlaying = false
        
        // 更新锁屏/控制中心信息
        updateNowPlayingInfo()
        
        // 通知播放状态变化
        NotificationCenter.default.post(name: .audioPlayerStateChanged, object: nil)
    }
    
    // 继续播放
    func resume() {
        playerNode.play()
        isPlaying = true
        
        // 更新锁屏/控制中心信息
        updateNowPlayingInfo()
        
        // 通知播放状态变化
        NotificationCenter.default.post(name: .audioPlayerStateChanged, object: nil)
    }
    
    // 停止
    func stop() {
        playerNode.stop()
        isPlaying = false
        
        // 通知播放状态变化
        NotificationCenter.default.post(name: .audioPlayerStateChanged, object: nil)
    }
    
    // 跳转到指定时间
    func seek(to time: TimeInterval) {
        // 实现音频跳转逻辑
    }
    
    // 播放下一首
    func playNext() {
        guard let currentIndex = queue.firstIndex(where: { $0.id == currentSong?.id }),
              currentIndex + 1 < queue.count else {
            if repeatMode == .all {
                // 循环播放，从头开始
                if let firstSong = queue.first {
                    play(firstSong)
                }
            }
            return
        }
        
        play(queue[currentIndex + 1])
    }
    
    // 播放上一首
    func playPrevious() {
        guard let currentIndex = queue.firstIndex(where: { $0.id == currentSong?.id }),
              currentIndex > 0 else { return }
        
        play(queue[currentIndex - 1])
    }
    
    // 设置播放队列
    func setQueue(_ songs: [Song], startFrom index: Int = 0) {
        queue = songs
        if index < songs.count {
            play(songs[index])
        }
    }
    
    // 切换随机播放
    func toggleShuffle() {
        isShuffleOn.toggle()
        if isShuffleOn {
            queue.shuffle()
            // 确保当前歌曲在随机后的队列中的位置正确
            if let currentSong = currentSong,
               let currentIndex = queue.firstIndex(where: { $0.id == currentSong.id }) {
                queue.remove(at: currentIndex)
                queue.insert(currentSong, at: 0)
            }
        }
        
        // 通知播放状态变化
        NotificationCenter.default.post(name: .audioPlayerStateChanged, object: nil)
    }
    
    // 切换重复模式
    func toggleRepeatMode() {
        switch repeatMode {
        case .off: repeatMode = .all
        case .all: repeatMode = .one
        case .one: repeatMode = .off
        }
        
        // 通知播放状态变化
        NotificationCenter.default.post(name: .audioPlayerStateChanged, object: nil)
    }
    
    // 获取当前播放进度
    var currentProgress: Double {
        guard let player = player, player.currentItem != nil else { return 0 }
        return player.currentTime() / player.currentItem!.duration
    }
    
    // 获取当前播放时间
    var currentTime: TimeInterval {
        return player?.currentTime() ?? 0
    }
    
    // 获取总时长
    var duration: TimeInterval {
        return player?.currentItem?.duration ?? 0
    }
    
    deinit {
        stop()
        audioEngine.stop()
    }
}

// 扩展AVAudioPlayerDelegate
extension AudioPlayerService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            switch repeatMode {
            case .one:
                // 单曲循环，重新播放当前歌曲
                player.currentTime = 0
                player.play()
            case .all, .off:
                // 播放下一首
                playNext()
            }
        }
    }
}

// 通知名称扩展
extension Notification.Name {
    static let audioPlayerStateChanged = Notification.Name("audioPlayerStateChanged")
}