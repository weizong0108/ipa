import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'song.g.dart';

@HiveType(typeId: 0)
class Song extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final String artist;
  
  @HiveField(3)
  final String albumId;
  
  @HiveField(4)
  final String albumName;
  
  @HiveField(5)
  final String coverUrl;
  
  @HiveField(6)
  final String audioUrl;
  
  @HiveField(7)
  final Duration duration;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.albumId,
    required this.albumName,
    required this.coverUrl,
    required this.audioUrl,
    required this.duration,
  });

  @override
  List<Object?> get props => [id, title, artist, albumId, albumName, coverUrl, audioUrl, duration];
} 