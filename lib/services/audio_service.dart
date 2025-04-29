import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import '../models/song.dart';

class AudioPlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Song? _currentSong;
  
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

  // 播放歌曲
  Future<void> playSong(Song song) async {
    try {
      _currentSong = song;
      await _audioPlayer.setUrl(song.audioUrl);
      await _audioPlayer.play();
    } catch (e) {
      print('Error playing song: $e');
      rethrow;
    }
  }

  // 暂停播放
  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      print('Error pausing song: $e');
      rethrow;
    }
  }

  // 继续播放
  Future<void> resume() async {
    try {
      await _audioPlayer.play();
    } catch (e) {
      print('Error resuming song: $e');
      rethrow;
    }
  }

  // 停止播放
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _currentSong = null;
    } catch (e) {
      print('Error stopping song: $e');
      rethrow;
    }
  }

  // 跳转到指定位置
  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      print('Error seeking: $e');
      rethrow;
    }
  }

  // 设置音量
  Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume);
    } catch (e) {
      print('Error setting volume: $e');
      rethrow;
    }
  }

  // 释放资源
  Future<void> dispose() async {
    try {
      await _audioPlayer.dispose();
    } catch (e) {
      print('Error disposing audio player: $e');
      rethrow;
    }
  }
} 