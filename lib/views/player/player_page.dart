import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/player/player_cubit.dart';
import '../../blocs/player/player_state.dart';
import '../../models/song.dart';

class PlayerPage extends StatelessWidget {
  final Song song;

  const PlayerPage({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PlayerCubit(context.read())..playSong(song),
      child: const PlayerView(),
    );
  }
}

class PlayerView extends StatelessWidget {
  const PlayerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('正在播放'),
        centerTitle: true,
      ),
      body: BlocBuilder<PlayerCubit, PlayerState>(
        builder: (context, state) {
          if (state.status == PlayerStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state.status == PlayerStatus.error) {
            return Center(child: Text('Error: ${state.errorMessage}'));
          }

          final song = state.currentSong;
          if (song == null) {
            return const Center(child: Text('No song playing'));
          }

          return Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 封面图片
                    Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          song.coverUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // 歌曲信息
                    Text(
                      song.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      song.artist,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              // 进度条
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Slider(
                      value: state.position.inSeconds.toDouble(),
                      max: state.duration.inSeconds.toDouble(),
                      onChanged: (value) {
                        context.read<PlayerCubit>().seek(
                          Duration(seconds: value.toInt()),
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(state.position)),
                          Text(_formatDuration(state.duration)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // 控制按钮
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shuffle),
                      onPressed: () {
                        // TODO: Implement shuffle
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_previous),
                      onPressed: () {
                        // TODO: Implement previous
                      },
                    ),
                    FloatingActionButton(
                      onPressed: () {
                        if (state.status == PlayerStatus.playing) {
                          context.read<PlayerCubit>().pause();
                        } else {
                          context.read<PlayerCubit>().resume();
                        }
                      },
                      child: Icon(
                        state.status == PlayerStatus.playing
                            ? Icons.pause
                            : Icons.play_arrow,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next),
                      onPressed: () {
                        // TODO: Implement next
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.repeat),
                      onPressed: () {
                        // TODO: Implement repeat
                      },
                    ),
                  ],
                ),
              ),
              // 音量控制
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.volume_down),
                    Expanded(
                      child: Slider(
                        value: state.volume,
                        onChanged: (value) {
                          context.read<PlayerCubit>().setVolume(value);
                        },
                      ),
                    ),
                    const Icon(Icons.volume_up),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
} 