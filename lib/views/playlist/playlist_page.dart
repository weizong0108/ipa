import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/player/player_cubit.dart';
import '../../services/playlist_service.dart';
import '../../models/playlist.dart';
import '../../models/song.dart';

class PlaylistPage extends StatefulWidget {
  final String playlistId;

  const PlaylistPage({super.key, required this.playlistId});

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  late Future<Playlist> _playlistFuture;

  @override
  void initState() {
    super.initState();
    _loadPlaylist();
  }

  void _loadPlaylist() {
    _playlistFuture = context.read<PlaylistService>().getPlaylist(widget.playlistId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Playlist>(
        future: _playlistFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final playlist = snapshot.data;
          if (playlist == null) {
            return const Center(child: Text('播放列表不存在'));
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() => _loadPlaylist()),
            child: CustomScrollView(
              slivers: [
                // 播放列表头部
                SliverAppBar(
                  expandedHeight: 300,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(playlist.name),
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          playlist.coverUrl,
                          fit: BoxFit.cover,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 播放列表信息
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          playlist.description,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              playlist.createdBy,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.play_circle_outline, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${playlist.playCount}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.music_note_outlined, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${playlist.songs.length} 首歌曲',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // 操作按钮
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (playlist.songs.isNotEmpty) {
                                context.read<PlayerCubit>().playSong(playlist.songs.first);
                                context.push('/player', extra: playlist.songs.first);
                              }
                            },
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('播放全部'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.share_outlined),
                          onPressed: () {
                            // TODO: Implement share
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.download_outlined),
                          onPressed: () {
                            // TODO: Implement download
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                // 歌曲列表
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final song = playlist.songs[index];
                      return _SongListTile(
                        song: song,
                        index: index + 1,
                        onRemove: () async {
                          try {
                            await context.read<PlaylistService>()
                                .removeSongFromPlaylist(playlist.id, song.id);
                            setState(() => _loadPlaylist());
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('删除失败：$e')),
                            );
                          }
                        },
                      );
                    },
                    childCount: playlist.songs.length,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SongListTile extends StatelessWidget {
  final Song song;
  final int index;
  final VoidCallback onRemove;

  const _SongListTile({
    required this.song,
    required this.index,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SizedBox(
        width: 40,
        child: Center(
          child: Text(
            index.toString(),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey,
            ),
          ),
        ),
      ),
      title: Text(song.title),
      subtitle: Text(song.artist),
      trailing: PopupMenuButton<String>(
        onSelected: (value) async {
          switch (value) {
            case 'next':
              // TODO: Implement next up
              break;
            case 'remove':
              await onRemove();
              break;
            case 'download':
              // TODO: Implement download
              break;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'next',
            child: Text('下一首播放'),
          ),
          const PopupMenuItem(
            value: 'remove',
            child: Text('从歌单中删除'),
          ),
          const PopupMenuItem(
            value: 'download',
            child: Text('下载'),
          ),
        ],
      ),
      onTap: () => context.push('/player', extra: song),
    );
  }
} 