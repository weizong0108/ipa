import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../models/song.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  List<Song>? _searchResults;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = null;
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await context.read<ApiService>().searchSongs(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: '搜索歌曲、歌手',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey),
          ),
          style: Theme.of(context).textTheme.titleLarge,
          onChanged: (value) => _performSearch(value),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }

    if (_searchResults == null) {
      return const Center(child: Text('搜索你喜欢的音乐'));
    }

    if (_searchResults!.isEmpty) {
      return const Center(child: Text('未找到相关结果'));
    }

    return ListView.builder(
      itemCount: _searchResults!.length,
      itemBuilder: (context, index) {
        final song = _searchResults![index];
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              song.coverUrl,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
          ),
          title: Text(song.title),
          subtitle: Text(song.artist),
          onTap: () => context.push('/player', extra: song),
        );
      },
    );
  }
} 