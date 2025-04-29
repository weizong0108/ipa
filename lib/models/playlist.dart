import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'song.dart';

part 'playlist.g.dart';

@HiveType(typeId: 1)
class Playlist extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String coverUrl;

  @HiveField(4)
  final List<Song> songs;

  @HiveField(5)
  final String createdBy;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final int playCount;

  const Playlist({
    required this.id,
    required this.name,
    required this.description,
    required this.coverUrl,
    required this.songs,
    required this.createdBy,
    required this.createdAt,
    required this.playCount,
  });

  @override
  List<Object?> get props => [id, name, description, coverUrl, songs, createdBy, createdAt, playCount];

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      coverUrl: json['coverUrl'] as String,
      songs: (json['songs'] as List<dynamic>)
          .map((songJson) => Song.fromJson(songJson as Map<String, dynamic>))
          .toList(),
      createdBy: json['createdBy'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      playCount: json['playCount'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'coverUrl': coverUrl,
      'songs': songs.map((song) => song.toJson()).toList(),
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'playCount': playCount,
    };
  }

  Playlist copyWith({
    String? id,
    String? name,
    String? description,
    String? coverUrl,
    List<Song>? songs,
    String? createdBy,
    DateTime? createdAt,
    int? playCount,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      songs: songs ?? this.songs,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      playCount: playCount ?? this.playCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Playlist &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          coverUrl == other.coverUrl &&
          songs == other.songs &&
          createdBy == other.createdBy &&
          createdAt == other.createdAt &&
          playCount == other.playCount;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      description.hashCode ^
      coverUrl.hashCode ^
      songs.hashCode ^
      createdBy.hashCode ^
      createdAt.hashCode ^
      playCount.hashCode;
} 