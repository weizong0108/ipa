import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/audio_service.dart';
import '../../models/song.dart';
import 'player_state.dart';

class PlayerCubit extends Cubit<PlayerState> {
  final AudioPlayerService _audioService;
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;

  PlayerCubit(this._audioService) : super(const PlayerState()) {
    _initStreams();
  }

  void _initStreams() {
    _playerStateSubscription = _audioService.playerStateStream.listen((playerState) {
      if (playerState.playing) {
        emit(state.copyWith(status: PlayerStatus.playing));
      } else {
        emit(state.copyWith(status: PlayerStatus.paused));
      }
    });

    _positionSubscription = _audioService.positionStream.listen((position) {
      emit(state.copyWith(position: position));
    });

    _durationSubscription = _audioService.durationStream.listen((duration) {
      emit(state.copyWith(duration: duration ?? Duration.zero));
    });
  }

  Future<void> playSong(Song song) async {
    try {
      emit(state.copyWith(status: PlayerStatus.loading));
      await _audioService.playSong(song);
      emit(state.copyWith(
        status: PlayerStatus.playing,
        currentSong: song,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PlayerStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> pause() async {
    try {
      await _audioService.pause();
      emit(state.copyWith(status: PlayerStatus.paused));
    } catch (e) {
      emit(state.copyWith(
        status: PlayerStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> resume() async {
    try {
      await _audioService.resume();
      emit(state.copyWith(status: PlayerStatus.playing));
    } catch (e) {
      emit(state.copyWith(
        status: PlayerStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _audioService.seek(position);
      emit(state.copyWith(position: position));
    } catch (e) {
      emit(state.copyWith(
        status: PlayerStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      await _audioService.setVolume(volume);
      emit(state.copyWith(volume: volume));
    } catch (e) {
      emit(state.copyWith(
        status: PlayerStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  @override
  Future<void> close() {
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    return super.close();
  }
} 