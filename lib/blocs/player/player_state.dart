import 'package:equatable/equatable.dart';
import '../../models/song.dart';

enum PlayerStatus { initial, loading, playing, paused, error }

class PlayerState extends Equatable {
  final PlayerStatus status;
  final Song? currentSong;
  final List<Song> playlist;
  final Duration position;
  final Duration duration;
  final double volume;
  final String? errorMessage;

  const PlayerState({
    this.status = PlayerStatus.initial,
    this.currentSong,
    this.playlist = const [],
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 1.0,
    this.errorMessage,
  });

  PlayerState copyWith({
    PlayerStatus? status,
    Song? currentSong,
    List<Song>? playlist,
    Duration? position,
    Duration? duration,
    double? volume,
    String? errorMessage,
  }) {
    return PlayerState(
      status: status ?? this.status,
      currentSong: currentSong ?? this.currentSong,
      playlist: playlist ?? this.playlist,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    currentSong,
    playlist,
    position,
    duration,
    volume,
    errorMessage,
  ];
} 