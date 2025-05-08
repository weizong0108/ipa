import 'dart:async'; // 异步编程支持
import 'dart:io'; // 文件操作支持
import 'dart:math' as math; // 数学计算支持
import 'package:just_audio/just_audio.dart'; // 音频播放核心库
import 'package:audio_service/audio_service.dart'; // 音频服务支持，提供后台播放能力
import 'package:path_provider/path_provider.dart'; // 获取设备存储路径
import 'package:shared_preferences/shared_preferences.dart'; // 本地数据持久化
import 'package:connectivity_plus/connectivity_plus.dart'; // 网络连接状态检测
import '../models/song.dart'; // 歌曲数据模型
import 'package:rxdart/rxdart.dart'; // 响应式编程支持，用于组合多个流

/// 音频播放服务类 - 负责管理音频播放、缓存和状态
/// 提供完整的音乐播放功能，包括：
/// 1. 播放控制（播放、暂停、上一首、下一首等）
/// 2. 播放列表管理
/// 3. 播放模式控制（顺序播放、单曲循环、列表循环、随机播放）
/// 4. 音频缓存管理（自动缓存、LRU清理策略）
/// 5. 播放历史记录
/// 6. 错误恢复机制
class AudioPlayerService {
  // 播放器核心实例 - 负责底层音频播放控制
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // 当前播放的歌曲 - 保存正在播放的歌曲信息
  Song? _currentSong;
  
  // 播放列表管理
  final List<Song> _playlist = []; // 当前播放列表
  int _currentIndex = -1; // 当前播放歌曲在列表中的索引
  
  // 播放模式控制
  bool _isShuffleMode = false; // 随机播放模式标志
  LoopMode _loopMode = LoopMode.off; // 循环模式（不循环、单曲循环、列表循环）
  
  // 缓存管理系统
  final Map<String, String> _songCache = {}; // 歌曲URL到本地缓存路径的映射
  final int _maxCacheSize = 500 * 1024 * 1024; // 500MB 缓存上限，防止占用过多存储空间
  int _currentCacheSize = 0; // 当前已使用的缓存大小（字节）
  
  // 播放历史记录
  final List<String> _playHistory = []; // 按播放时间顺序记录的歌曲URL列表
  final int _maxHistorySize = 50; // 最大历史记录数量
  
  // 音频焦点管理 - 处理与其他应用的音频交互
  final AudioSession _audioSession = AudioSession();
  
  // 智能预缓存系统 - 预加载下一首歌曲，减少切歌等待时间
  bool _isPreCachingEnabled = true; // 是否启用预缓存功能
  Song? _preCachedSong; // 已预缓存的歌曲
  String? _preCachedPath; // 预缓存的本地路径
  
  // 音频淡入淡出效果 - 使歌曲切换更加平滑
  final Duration _fadeInDuration = Duration(milliseconds: 500); // 淡入时长
  final Duration _fadeOutDuration = Duration(milliseconds: 500); // 淡出时长
  bool _isFadeEffectEnabled = true; // 是否启用淡入淡出效果
  
  // 播放统计系统 - 记录每首歌曲的播放次数和时长
  final Map<String, int> _playCount = {}; // 歌曲播放次数统计 {歌曲ID: 播放次数}
  final Map<String, int> _playDuration = {}; // 歌曲播放时长统计 {歌曲ID: 累计播放时长(秒)}
  Timer? _playDurationTimer; // 播放时长计时器
  final int _minPlayDurationForCount = 30; // 最小计入播放次数的时长(秒)
  
  /// 构造函数 - 初始化播放器和加载缓存
  /// 完成三个关键初始化任务：
  /// 1. 初始化音频播放器和事件监听
  /// 2. 从本地存储加载缓存信息
  /// 3. 配置音频会话，处理音频焦点
  AudioPlayerService() {
    _initAudioPlayer(); // 初始化播放器和事件监听
    _loadCacheInfo(); // 加载缓存信息
    _loadPlayStatistics(); // 加载播放统计数据
    _setupAudioSession(); // 设置音频会话
  }
  
  /// 初始化音频播放器
  /// 设置必要的事件监听器，包括：
  /// 1. 播放完成事件 - 用于自动播放下一首
  /// 2. 错误处理 - 自动恢复播放和错误日志
  /// 3. 播放状态监控 - 用于播放统计和预缓存
  Future<void> _initAudioPlayer() async {
    // 监听播放状态变化，处理播放完成事件
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _onSongComplete(); // 歌曲播放完成时的处理逻辑
      } else if (state.playing) {
        // 播放状态下，启动播放时长统计
        _startPlayDurationTracking();
      } else {
        // 暂停状态下，停止播放时长统计
        _stopPlayDurationTracking();
      }
    });
    
    // 监听播放进度，用于预缓存下一首歌曲
    _audioPlayer.positionStream.listen((position) {
      _checkAndPreCacheNextSong(position);
    });
    
    // 设置错误处理机制，增强应用稳定性
    _audioPlayer.playbackEventStream.listen((event) {}, 
      onError: (Object e, StackTrace st) {
        print('播放器错误: $e'); // 记录错误信息
        // 尝试自动恢复播放，提高用户体验
        _handlePlaybackError();
      });
  }
  
  /// 设置音频会话
  /// 配置音频焦点和交互行为，实现：
  /// 1. 适当的音频焦点处理
  /// 2. 与其他应用的音频交互（如降低其他应用音量）
  /// 3. 针对不同平台(iOS/Android)的优化配置
  Future<void> _setupAudioSession() async {
    try {
      await _audioSession.configure(AudioSessionConfiguration(
        // iOS音频会话配置
        avAudioSessionCategory: AVAudioSessionCategory.playback, // 设置为播放类别，支持后台播放
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers, // 播放时降低其他应用音量
        avAudioSessionMode: AVAudioSessionMode.defaultMode, // 默认模式
        
        // Android音频属性配置
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music, // 内容类型为音乐
          usage: AndroidAudioUsage.media, // 用途为媒体播放
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain, // 获取持久音频焦点
        androidWillPauseWhenDucked: true, // 当失去音频焦点时暂停播放
      ));
      print('音频会话配置成功，已启用音频焦点管理');
    } catch (e) {
      print('设置音频会话失败: $e');
    }
  }
  
  /// 加载缓存信息
  /// 从本地存储中恢复：
  /// 1. 歌曲缓存映射关系
  /// 2. 当前缓存大小统计
  /// 3. 播放历史记录
  /// 同时验证缓存文件是否有效，清理无效缓存记录
  Future<void> _loadCacheInfo() async {
    try {
      // 获取本地存储实例
      final prefs = await SharedPreferences.getInstance();
      // 读取缓存信息列表
      final cacheInfo = prefs.getStringList('song_cache_info') ?? [];
      
      // 解析并验证每条缓存记录
      for (final info in cacheInfo) {
        final parts = info.split('|'); // 格式：URL|本地路径|文件大小
        if (parts.length == 3) {
          final url = parts[0]; // 歌曲URL
          final path = parts[1]; // 本地缓存路径
          final size = int.parse(parts[2]); // 文件大小(字节)
          
          // 验证缓存文件是否存在，防止加载无效缓存
          final file = File(path);
          if (await file.exists()) {
            _songCache[url] = path; // 添加到缓存映射
            _currentCacheSize += size; // 累计缓存大小
          }
        }
      }
      
      // 加载播放历史记录
      _playHistory.addAll(prefs.getStringList('play_history') ?? []);
      
      print('已加载缓存信息: ${_songCache.length} 首歌曲, 总大小: ${_currentCacheSize ~/ (1024 * 1024)}MB');
    } catch (e) {
      print('加载缓存信息失败: $e');
    }
  }
  
  /// 保存缓存信息
  /// 将当前的缓存状态持久化到本地存储：
  /// 1. 保存歌曲URL到本地路径的映射
  /// 2. 保存每个缓存文件的大小信息
  /// 3. 保存播放历史记录
  /// 同时验证缓存文件有效性，避免保存无效记录
  Future<void> _saveCacheInfo() async {
    try {
      // 获取本地存储实例
      final prefs = await SharedPreferences.getInstance();
      final cacheInfo = <String>[];
      
      // 遍历缓存映射，构建持久化数据
      for (final entry in _songCache.entries) {
        final file = File(entry.value);
        // 再次验证文件存在，避免保存无效记录
        if (await file.exists()) {
          final size = await file.length();
          // 格式：URL|本地路径|文件大小
          cacheInfo.add('${entry.key}|${entry.value}|$size');
        }
      }
      
      // 保存缓存信息和播放历史到本地存储
      await prefs.setStringList('song_cache_info', cacheInfo);
      await prefs.setStringList('play_history', _playHistory);
    } catch (e) {
      print('保存缓存信息失败: $e');
    }
  }
  
  /// 处理播放错误
  /// 实现自动错误恢复机制：
  /// 1. 清除可能损坏的缓存文件
  /// 2. 尝试直接从源URL重新加载
  /// 3. 如果重试失败，自动切换到下一首
  /// 提高应用稳定性和用户体验
  Future<void> _handlePlaybackError() async {
    if (_currentSong != null) {
      // 清除可能损坏的缓存文件
      final url = _currentSong!.audioUrl;
      if (_songCache.containsKey(url)) {
        try {
          // 删除可能损坏的缓存文件
          final cachePath = _songCache[url]!;
          final cacheFile = File(cachePath);
          if (await cacheFile.exists()) {
            await cacheFile.delete();
            print('已删除可能损坏的缓存文件: $cachePath');
          }
          // 从缓存映射中移除
          _songCache.remove(url);
          // 更新缓存信息
          await _saveCacheInfo();
        } catch (e) {
          print('清除损坏的缓存失败: $e');
        }
      }
      
      // 尝试直接从源URL重新加载并播放
      try {
        print('尝试从源URL重新加载歌曲: ${_currentSong!.audioUrl}');
        await _audioPlayer.setUrl(_currentSong!.audioUrl);
        await _audioPlayer.play();
      } catch (e) {
        print('重新加载歌曲失败: $e');
        // 如果重试失败，自动切换到下一首歌曲
        print('切换到下一首歌曲');
        playNext();
      }
    }
  }
  
  /// 歌曲播放完成处理
  /// 根据当前循环模式决定下一步操作：
  /// 1. 单曲循环：重新播放当前歌曲
  /// 2. 列表循环/不循环：播放下一首
  /// 实现无缝的播放体验
  void _onSongComplete() {
    switch (_loopMode) {
      case LoopMode.one:
        // 单曲循环模式：重新从头播放当前歌曲
        _audioPlayer.seek(Duration.zero);
        _audioPlayer.play();
        print('单曲循环：重新播放 ${_currentSong?.title ?? "未知歌曲"}');
        break;
      case LoopMode.all:
        // 列表循环模式：播放下一首（到列表末尾会回到开头）
        playNext();
        print('列表循环：播放下一首歌曲');
        break;
      case LoopMode.off:
        // 不循环模式：播放下一首（到列表末尾会停止）
        playNext();
        print('顺序播放：播放下一首歌曲');
        break;
    }
  }
  
  // 缓存歌曲
  Future<String?> _cacheSong(Song song) async {
    if (_songCache.containsKey(song.audioUrl)) {
      return _songCache[song.audioUrl];
    }
    
    try {
      // 获取缓存目录
      final cacheDir = await getTemporaryDirectory();
      final songDir = Directory('${cacheDir.path}/song_cache');
      if (!await songDir.exists()) {
        await songDir.create(recursive: true);
      }
      
      // 生成缓存文件路径
      final fileName = '${song.id}_${DateTime.now().millisecondsSinceEpoch}.mp3';
      final cachePath = '${songDir.path}/$fileName';
      
      // 下载歌曲到缓存
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(song.audioUrl));
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final file = File(cachePath);
        await response.pipe(file.openWrite());
        
        // 更新缓存信息
        final fileSize = await file.length();
        
        // 检查缓存大小是否超过限制
        if (_currentCacheSize + fileSize > _maxCacheSize) {
          await _cleanCache(fileSize);
        }
        
        _songCache[song.audioUrl] = cachePath;
        _currentCacheSize += fileSize;
        await _saveCacheInfo();
        
        return cachePath;
      }
    } catch (e) {
      print('缓存歌曲失败: $e');
    }
    
    return null;
  }
  
  // 清理缓存
  Future<void> _cleanCache(int neededSpace) async {
    // 按最近最少使用原则清理缓存
    final urlsToRemove = <String>[];
    
    // 从播放历史中找出最少使用的歌曲
    for (int i = _playHistory.length - 1; i >= 0; i--) {
      final url = _playHistory[i];
      if (_songCache.containsKey(url)) {
        urlsToRemove.add(url);
      }
    }
    
    // 添加未在历史记录中的缓存
    for (final url in _songCache.keys) {
      if (!urlsToRemove.contains(url)) {
        urlsToRemove.add(url);
      }
    }
    
    // 清理缓存直到释放足够空间
    int freedSpace = 0;
    for (final url in urlsToRemove) {
      if (freedSpace >= neededSpace) break;
      
      try {
        final cachePath = _songCache[url]!;
        final file = File(cachePath);
        if (await file.exists()) {
          final fileSize = await file.length();
          await file.delete();
          freedSpace += fileSize;
          _currentCacheSize -= fileSize;
        }
        _songCache.remove(url);
      } catch (e) {
        print('清理缓存文件失败: $e');
      }
    }
    
    await _saveCacheInfo();
  }
  
  // 更新播放历史
  void _updatePlayHistory(String url) {
    // 从历史记录中移除该URL（如果存在）
    _playHistory.remove(url);
    
    // 添加到历史记录开头
    _playHistory.insert(0, url);
    
    // 限制历史记录大小
    if (_playHistory.length > _maxHistorySize) {
      _playHistory.removeLast();
    }
    
    // 保存历史记录
    _saveCacheInfo();
  }
  
  /// 智能预缓存系统 - 预加载下一首歌曲
  /// 根据当前播放列表和播放模式，预测并缓存下一首可能播放的歌曲
  /// 减少切歌时的等待时间，提升用户体验
  Future<void> _startPreCachingNextSong() async {
    // 如果预缓存功能未启用或播放列表为空，则不执行预缓存
    if (!_isPreCachingEnabled || _playlist.isEmpty || _currentIndex < 0) {
      return;
    }
    
    // 预测下一首歌曲
    Song? nextSong;
    if (_isShuffleMode) {
      // 随机模式下，随机选择一首不同的歌曲作为下一首
      if (_playlist.length > 1) {
        final random = math.Random();
        int nextIndex;
        do {
          nextIndex = random.nextInt(_playlist.length);
        } while (nextIndex == _currentIndex);
        nextSong = _playlist[nextIndex];
      }
    } else {
      // 顺序模式下，选择列表中的下一首
      final nextIndex = (_currentIndex + 1) % _playlist.length;
      nextSong = _playlist[nextIndex];
    }
    
    // 如果找到了下一首歌曲且与当前预缓存的不同，则开始预缓存
    if (nextSong != null && (_preCachedSong == null || nextSong.id != _preCachedSong!.id)) {
      _preCachedSong = nextSong;
      
      // 检查网络状态，仅在WiFi环境下预缓存
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.wifi) {
        print('开始预缓存下一首歌曲: ${nextSong.title}');
        _preCachedPath = await _cacheSong(nextSong);
        if (_preCachedPath != null) {
          print('预缓存完成: ${nextSong.title}');
        }
      } else {
        print('非WiFi环境，跳过预缓存');
      }
    }
  }
  
  /// 检查并预缓存下一首歌曲
  /// 根据当前播放进度决定是否开始预缓存
  /// 通常在歌曲播放到70%位置时开始预缓存下一首
  void _checkAndPreCacheNextSong(Duration position) async {
    if (!_isPreCachingEnabled || _currentSong == null) return;
    
    final duration = _audioPlayer.duration;
    if (duration != null) {
      // 当播放进度达到70%时，开始预缓存下一首
      if (position.inMilliseconds > duration.inMilliseconds * 0.7 && 
          _preCachedSong == null) {
        await _startPreCachingNextSong();
      }
    }
  }
  
  /// 音频淡入效果
  /// 逐渐增加音量，创造平滑的过渡效果
  Future<void> _fadeInCurrentSong() async {
    if (!_isFadeEffectEnabled) return;
    
    // 从0逐渐增加到1.0的音量
    const fadeSteps = 20; // 淡入的步骤数
    final stepDuration = _fadeInDuration.inMilliseconds ~/ fadeSteps; // 每步持续时间
    
    for (int i = 1; i <= fadeSteps; i++) {
      final volume = i / fadeSteps; // 0.05, 0.1, 0.15, ..., 1.0
      await _audioPlayer.setVolume(volume);
      await Future.delayed(Duration(milliseconds: stepDuration));
    }
    
    // 确保最终音量为1.0
    await _audioPlayer.setVolume(1.0);
  }
  
  /// 音频淡出效果
  /// 逐渐降低音量，创造平滑的过渡效果
  Future<void> _fadeOutCurrentSong() async {
    if (!_isFadeEffectEnabled || !_audioPlayer.playing) return;
    
    // 从1.0逐渐降低到0的音量
    const fadeSteps = 20; // 淡出的步骤数
    final stepDuration = _fadeOutDuration.inMilliseconds ~/ fadeSteps; // 每步持续时间
    final initialVolume = _audioPlayer.volume;
    
    for (int i = 1; i <= fadeSteps; i++) {
      final volume = initialVolume * (fadeSteps - i) / fadeSteps; // 0.95, 0.9, ..., 0
      await _audioPlayer.setVolume(volume);
      await Future.delayed(Duration(milliseconds: stepDuration));
    }
    
    // 确保最终音量为0
    await _audioPlayer.setVolume(0.0);
  }
  
  /// 更新播放统计信息
  /// 记录歌曲播放次数
  void _updatePlayStatistics(String songId) {
    // 更新播放次数
    _playCount[songId] = (_playCount[songId] ?? 0) + 1;
    print('歌曲播放次数更新: $songId, 总次数: ${_playCount[songId]}');
    
    // 保存播放统计数据
    _savePlayStatistics();
  }
  
  /// 开始播放时长统计
  /// 启动计时器，定期更新播放时长
  void _startPlayDurationTracking() {
    if (_currentSong == null) return;
    
    // 取消可能存在的旧计时器
    _stopPlayDurationTracking();
    
    // 创建新计时器，每秒更新一次播放时长
    _playDurationTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_currentSong != null) {
        final songId = _currentSong!.id;
        _playDuration[songId] = (_playDuration[songId] ?? 0) + 1;
      }
    });
  }
  
  /// 停止播放时长统计
  /// 取消计时器，保存当前统计数据
  void _stopPlayDurationTracking() {
    _playDurationTimer?.cancel();
    _playDurationTimer = null;
    
    // 保存播放统计数据
    _savePlayStatistics();
  }
  
  /// 保存播放统计数据到本地存储
  Future<void> _savePlayStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 转换播放次数为字符串列表
      final playCountList = _playCount.entries.map((e) => '${e.key}|${e.value}').toList();
      await prefs.setStringList('play_count', playCountList);
      
      // 转换播放时长为字符串列表
      final playDurationList = _playDuration.entries.map((e) => '${e.key}|${e.value}').toList();
      await prefs.setStringList('play_duration', playDurationList);
      
    } catch (e) {
      print('保存播放统计数据失败: $e');
    }
  }
  
  /// 加载播放统计数据
  Future<void> _loadPlayStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 加载播放次数
      final playCountList = prefs.getStringList('play_count') ?? [];
      for (final item in playCountList) {
        final parts = item.split('|');
        if (parts.length == 2) {
          final songId = parts[0];
          final count = int.parse(parts[1]);
          _playCount[songId] = count;
        }
      }
      
      // 加载播放时长
      final playDurationList = prefs.getStringList('play_duration') ?? [];
      for (final item in playDurationList) {
        final parts = item.split('|');
        if (parts.length == 2) {
          final songId = parts[0];
          final duration = int.parse(parts[1]);
          _playDuration[songId] = duration;
        }
      }
      
      print('已加载播放统计数据: ${_playCount.length} 首歌曲的播放记录');
    } catch (e) {
      print('加载播放统计数据失败: $e');
    }
  }
  
  // 公开API
  
  // 获取当前播放的歌曲
  Song? get currentSong => _currentSong;
  
  // 获取当前播放状态
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  
  // 获取当前播放进度
  Stream<Duration?> get positionStream => _audioPlayer.positionStream;
  
  // 获取当前缓冲进度
  Stream<Duration?> get bufferedPositionStream => _audioPlayer.bufferedPositionStream;
  
  // 获取当前音频总时长
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  
  // 获取当前播放列表
  List<Song> get playlist => List.unmodifiable(_playlist);
  
  // 获取当前播放模式
  bool get isShuffleMode => _isShuffleMode;
  LoopMode get loopMode => _loopMode;
  
  // 获取播放统计数据
  Map<String, int> get playCount => Map.unmodifiable(_playCount);
  Map<String, int> get playDuration => Map.unmodifiable(_playDuration);
  
  // 设置预缓存功能
  void setPreCachingEnabled(bool enabled) {
    _isPreCachingEnabled = enabled;
    print('预缓存功能已${enabled ? "启用" : "禁用"}');
  }
  
  // 设置淡入淡出效果
  void setFadeEffectEnabled(bool enabled) {
    _isFadeEffectEnabled = enabled;
    print('淡入淡出效果已${enabled ? "启用" : "禁用"}');
  }
  
  // 设置播放列表
  Future<void> setPlaylist(List<Song> songs, {int initialIndex = 0}) async {
    _playlist.clear();
    _playlist.addAll(songs);
    _currentIndex = initialIndex.clamp(0, songs.length - 1);
    
    if (_playlist.isNotEmpty) {
      await playSong(_playlist[_currentIndex]);
    }
  }
  
  // 播放歌曲
  Future<void> playSong(Song song) async {
    try {
      // 如果启用了淡出效果且当前正在播放，先执行淡出
      if (_isFadeEffectEnabled && _audioPlayer.playing) {
        await _fadeOutCurrentSong();
      }
      
      _currentSong = song;
      _updatePlayHistory(song.audioUrl);
      
      // 检查是否已预缓存该歌曲
      String? audioPath;
      if (_isPreCachingEnabled && _preCachedSong?.id == song.id && _preCachedPath != null) {
        print('使用预缓存播放: ${song.title}');
        audioPath = _preCachedPath;
        // 清除预缓存引用，避免内存泄漏
        _preCachedSong = null;
        _preCachedPath = null;
      } else {
        // 尝试从缓存播放
        audioPath = await _cacheSong(song);
      }
      
      // 设置音频源
      if (audioPath != null) {
        await _audioPlayer.setFilePath(audioPath);
      } else {
        await _audioPlayer.setUrl(song.audioUrl);
      }
      
      // 如果启用了淡入效果，设置音量为0并逐渐增加
      if (_isFadeEffectEnabled) {
        await _audioPlayer.setVolume(0.0);
        await _audioPlayer.play();
        await _fadeInCurrentSong();
      } else {
        await _audioPlayer.play();
      }
      
      // 更新播放统计
      _updatePlayStatistics(song.id);
      
      // 预缓存下一首歌曲
      _startPreCachingNextSong();
    } catch (e) {
      print('播放歌曲失败: $e');
      // 尝试直接从URL播放
      try {
        await _audioPlayer.setUrl(song.audioUrl);
        await _audioPlayer.play();
      } catch (e) {
        print('从URL播放歌曲失败: $e');
        rethrow;
      }
    }
  }
  
  // 暂停播放
  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      print('暂停播放失败: $e');
      rethrow;
    }
  }
  
  // 继续播放
  Future<void> resume() async {
    try {
      await _audioPlayer.play();
    } catch (e) {
      print('继续播放失败: $e');
      rethrow;
    }
  }
  
  // 停止播放
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _currentSong = null;
    } catch (e) {
      print('停止播放失败: $e');
      rethrow;
    }
  }
  
  // 跳转到指定位置
  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      print('跳转播放位置失败: $e');
      rethrow;
    }
  }
  
  // 设置音量
  Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      print('设置音量失败: $e');
      rethrow;
    }
  }
  
  // 播放下一首
  Future<void> playNext() async {
    if (_playlist.isEmpty || _currentIndex < 0) return;
    
    int nextIndex;
    if (_isShuffleMode) {
      // 随机模式下随机选择一首（避免重复播放当前歌曲）
      if (_playlist.length > 1) {
        final random = math.Random();
        do {
          nextIndex = random.nextInt(_playlist.length);
        } while (nextIndex == _currentIndex);
      } else {
        nextIndex = 0;
      }
    } else {
      // 顺序模式
      nextIndex = (_currentIndex + 1) % _playlist.length;
    }
    
    _currentIndex = nextIndex;
    
    // 使用预缓存的歌曲（如果可用）
    if (_isPreCachingEnabled && _preCachedSong?.id == _playlist[_currentIndex].id) {
      print('播放下一首: 使用预缓存的歌曲 ${_playlist[_currentIndex].title}');
    } else {
      print('播放下一首: ${_playlist[_currentIndex].title}');
    }
    
    await playSong(_playlist[_currentIndex]);
  }
  
  // 播放上一首
  Future<void> playPrevious() async {
    if (_playlist.isEmpty || _currentIndex < 0) return;
    
    int prevIndex;
    if (_isShuffleMode) {
      // 随机模式下随机选择一首
      if (_playlist.length > 1) {
        final random = math.Random();
        do {
          prevIndex = random.nextInt(_playlist.length);
        } while (prevIndex == _currentIndex);
      } else {
        prevIndex = 0;
      }
    } else {
      // 顺序模式
      prevIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    }
    
    _currentIndex = prevIndex;
    print('播放上一首: ${_playlist[_currentIndex].title}');
    
    // 如果启用了淡出效果且当前正在播放，先执行淡出
    if (_isFadeEffectEnabled && _audioPlayer.playing) {
      await _fadeOutCurrentSong();
    }
    
    await playSong(_playlist[_currentIndex]);
    
    // 播放后重新启动预缓存系统
    _startPreCachingNextSong();
  }
  
  // 设置循环模式
  void setLoopMode(LoopMode mode) {
    _loopMode = mode;
  }
  
  // 设置随机播放模式
  void setShuffleMode(bool enabled) {
    _isShuffleMode = enabled;
  }
  
  // 清除缓存
  Future<void> clearCache() async {
    try {
      for (final cachePath in _songCache.values) {
        final file = File(cachePath);
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      _songCache.clear();
      _currentCacheSize = 0;
      await _saveCacheInfo();
      
      print('缓存已清除');
    } catch (e) {
      print('清除缓存失败: $e');
      rethrow;
    }
  }
  
  // 释放资源
  Future<void> dispose() async {
    try {
      await _saveCacheInfo();
      await _audioPlayer.dispose();
    } catch (e) {
      print('释放资源失败: $e');
      rethrow;
    }
  }
}

// 循环播放模式
enum LoopMode {
  off,  // 不循环
  one,  // 单曲循环
  all   // 列表循环
}