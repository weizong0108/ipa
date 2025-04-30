import 'package:dio/dio.dart';
import '../models/song.dart';
import '../models/playlist.dart';

class ApiService {
  final Dio _dio;
  final String baseUrl;

  ApiService({required this.baseUrl}) : _dio = Dio(BaseOptions(baseUrl: baseUrl));

  // 获取歌曲列表
  Future<List<Song>> getSongs({int page = 1, int limit = 20}) async {
    try {
      final response = await _dio.get('/songs', queryParameters: {
        'page': page,
        'limit': limit,
      });
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => Song(
          id: json['id'],
          title: json['title'],
          artist: json['artist'],
          albumId: json['albumId'],
          albumName: json['albumName'],
          coverUrl: json['coverUrl'],
          audioUrl: json['audioUrl'],
          duration: Duration(milliseconds: json['duration']),
        )).toList();
      }
      throw Exception('Failed to load songs');
    } catch (e) {
      print('Error getting songs: $e');
      rethrow;
    }
  }

  // 获取播放列表
  Future<List<Playlist>> getPlaylists({int page = 1, int limit = 20}) async {
    try {
      final response = await _dio.get('/playlists', queryParameters: {
        'page': page,
        'limit': limit,
      });
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => Playlist(
          id: json['id'],
          name: json['name'],
          description: json['description'],
          coverUrl: json['coverUrl'],
          songs: (json['songs'] as List).map((songJson) => Song(
            id: songJson['id'],
            title: songJson['title'],
            artist: songJson['artist'],
            albumId: songJson['albumId'],
            albumName: songJson['albumName'],
            coverUrl: songJson['coverUrl'],
            audioUrl: songJson['audioUrl'],
            duration: Duration(milliseconds: songJson['duration']),
          )).toList(),
          createdBy: json['createdBy'] ?? '',
          createdAt: DateTime.parse(json['createdAt']),
          playCount: json['playCount'] ?? 0,
        )).toList();
      }
      throw Exception('Failed to load playlists');
    } catch (e) {
      print('Error getting playlists: $e');
      rethrow;
    }
  }

  // 搜索歌曲
  Future<List<Song>> searchSongs(String query) async {
    try {
      final response = await _dio.get('/search/songs', queryParameters: {
        'q': query,
      });
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => Song(
          id: json['id'],
          title: json['title'],
          artist: json['artist'],
          albumId: json['albumId'],
          albumName: json['albumName'],
          coverUrl: json['coverUrl'],
          audioUrl: json['audioUrl'],
          duration: Duration(milliseconds: json['duration']),
        )).toList();
      }
      throw Exception('Failed to search songs');
    } catch (e) {
      print('Error searching songs: $e');
      rethrow;
    }
  }
} 