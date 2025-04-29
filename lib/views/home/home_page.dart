import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../models/song.dart';
import '../../models/playlist.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Song>> _recentSongs;
  late Future<List<Playlist>> _playlists;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final apiService = context.read<ApiService>();
    _recentSongs = apiService.getSongs(limit: 10);
    _playlists = apiService.getPlaylists(limit: 5);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _loadData()),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '最近播放',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: FutureBuilder<List<Song>>(
                future: _recentSongs,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No recent songs'));
                  }
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final song = snapshot.data![index];
                      return SongCard(song: song);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            Text(
              '我的歌单',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Playlist>>(
              future: _playlists,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No playlists'));
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final playlist = snapshot.data![index];
                    return PlaylistCard(playlist: playlist);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class SongCard extends StatelessWidget {
  final Song song;

  const SongCard({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/player', extra: song),
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                song.coverUrl,
                width: 150,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              song.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class PlaylistCard extends StatelessWidget {
  final Playlist playlist;

  const PlaylistCard({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => context.push('/playlist/${playlist.id}'),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          playlist.coverUrl,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
        ),
      ),
      title: Text(playlist.name),
      subtitle: Text('${playlist.songs.length} 首歌曲'),
      trailing: const Icon(Icons.chevron_right),
    );
  }
} 