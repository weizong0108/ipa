import 'package:dio/dio.dart';
import '../models/playlist.dart';
import '../utils/api_client.dart';

class PlaylistService {
  final ApiClient _apiClient;

  PlaylistService(this._apiClient);

  Future<Playlist> getPlaylist(String id) async {
    try {
      final response = await _apiClient.get('/playlists/$id');
      return Playlist.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Playlist>> getUserPlaylists() async {
    try {
      final response = await _apiClient.get('/playlists/user');
      return (response.data as List)
          .map((json) => Playlist.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Playlist> createPlaylist(String name, String description) async {
    try {
      final response = await _apiClient.post('/playlists', data: {
        'name': name,
        'description': description,
      });
      return Playlist.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    try {
      await _apiClient.post('/playlists/$playlistId/songs/$songId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    try {
      await _apiClient.delete('/playlists/$playlistId/songs/$songId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    if (e.response?.statusCode == 404) {
      return Exception('播放列表不存在');
    } else if (e.response?.statusCode == 403) {
      return Exception('没有权限访问此播放列表');
    } else {
      return Exception('获取播放列表失败：${e.message}');
    }
  }
} 