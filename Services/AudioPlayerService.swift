import Foundation
import AVFoundation
import MediaPlayer

class AudioPlayerService {
    // 单例模式
    static let shared = AudioPlayerService()
    
    // 音频播放器
    private var audioPlayer: AVAudioPlayer?
    
    // 当前播放状态
    private(set) var isPlaying: Bool = false
    
    // 当前播放的歌曲
    private(set) var currentSong: Song?
    
    // 播放队列
    private(set) var queue: [Song] = []
    
    // 播放模式
    enum RepeatMode {
        case off, one, all
    }
    
    // 当前播放模式
    private(set) var repeatMode: RepeatMode = .off
    
    // 是否随机播放
    private(set) var isShuffleOn: Bool = false
    
    private init() {
        setupAudioSession()
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
    
    // 播放歌曲
    func play(song: Song) {
        guard let audioURL = song.audioURL else {
            print("歌曲没有音频URL")
            return
        }
        
        // 实际项目中应从网络或本地加载音频文件
        // 这里仅作为示例，使用本地资源URL
        guard let url = URL(string: audioURL) else {
            print("无效的音频URL")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            
            currentSong = song
            isPlaying = true
            
            // 更新锁屏/控制中心信息
            updateNowPlayingInfo()
            
            // 通知播放状态变化
            NotificationCenter.default.post(name: .audioPlayerStateChanged, object: nil)
        } catch {
            print("播放音频失败: \(error)")
        }
    }
    
    // 暂停播放
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        
        // 更新锁屏/控制中心信息
        updateNowPlayingInfo()
        
        // 通知播放状态变化
        NotificationCenter.default.post(name: .audioPlayerStateChanged, object: nil)
    }
    
    // 继续播放
    func resume() {
        audioPlayer?.play()
        isPlaying = true
        
        // 更新锁屏/控制中心信息
        updateNowPlayingInfo()
        
        // 通知播放状态变化
        NotificationCenter.default.post(name: .audioPlayerStateChanged, object: nil)
    }
    
    // 停止播放
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        currentSong = nil
        isPlaying = false
        
        // 通知播放状态变化
        NotificationCenter.default.post(name: .audioPlayerStateChanged, object: nil)
    }
    
    // 播放下一首
    func playNext() {
        guard !queue.isEmpty else { return }
        
        if let currentIndex = currentSongIndex, currentIndex < queue.count - 1 {
            let nextSong = queue[currentIndex + 1]
            play(song: nextSong)
        } else if repeatMode == .all {
            // 循环播放模式，从头开始
            let firstSong = queue.first!
            play(song: firstSong)
        }
    }
    
    // 播放上一首
    func playPrevious() {
        guard !queue.isEmpty else { return }
        
        if let currentIndex = currentSongIndex, currentIndex > 0 {
            let previousSong = queue[currentIndex - 1]
            play(song: previousSong)
        } else if repeatMode == .all {
            // 循环播放模式，从末尾开始
            let lastSong = queue.last!
            play(song: lastSong)
        }
    }
    
    // 设置播放队列
    func setQueue(songs: [Song], startIndex: Int = 0) {
        guard !songs.isEmpty, startIndex < songs.count else { return }
        
        queue = songs
        play(song: songs[startIndex])
    }
    
    // 添加歌曲到队列
    func addToQueue(song: Song) {
        queue.append(song)
        
        // 如果当前没有播放，则开始播放
        if currentSong == nil {
            play(song: song)
        }
    }
    
    // 切换随机播放
    func toggleShuffle() {
        isShuffleOn.toggle()
        
        if isShuffleOn {
            // 保存当前歌曲
            let current = currentSong
            
            // 随机排序队列
            queue.shuffle()
            
            // 如果有当前歌曲，将其移到队列开头
            if let current = current, let index = queue.firstIndex(where: { $0.id == current.id }) {
                queue.remove(at: index)
                queue.insert(current, at: 0)
            }
        }
        
        // 通知播放状态变化
        NotificationCenter.default.post(name: .audioPlayerStateChanged, object: nil)
    }
    
    // 切换重复模式
    func toggleRepeatMode() {
        switch repeatMode {
        case .off:
            repeatMode = .all
        case .all:
            repeatMode = .one
        case .one:
            repeatMode = .off
        }
        
        // 通知播放状态变化
        NotificationCenter.default.post(name: .audioPlayerStateChanged, object: nil)
    }
    
    // 获取当前播放进度
    var currentProgress: Double {
        guard let player = audioPlayer, player.duration > 0 else { return 0 }
        return player.currentTime / player.duration
    }
    
    // 获取当前播放时间
    var currentTime: TimeInterval {
        return audioPlayer?.currentTime ?? 0
    }
    
    // 获取总时长
    var duration: TimeInterval {
        return audioPlayer?.duration ?? 0
    }
    
    // 设置播放位置
    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = min(max(0, time), duration)
        
        // 更新锁屏/控制中心信息
        updateNowPlayingInfo()
    }
    
    // 获取当前歌曲在队列中的索引
    private var currentSongIndex: Int? {
        guard let currentSong = currentSong else { return nil }
        return queue.firstIndex(where: { $0.id == currentSong.id })
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