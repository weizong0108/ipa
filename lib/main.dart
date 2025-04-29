import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'services/audio_service.dart';
import 'services/api_service.dart';
import 'models/song.dart';
import 'models/playlist.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化Hive
  await Hive.initFlutter();
  Hive.registerAdapter(SongAdapter());
  Hive.registerAdapter(PlaylistAdapter());
  
  // 打开Hive盒子
  await Hive.openBox<Song>('songs');
  await Hive.openBox<Playlist>('playlists');

  runApp(const MyApp());
}

final GoRouter _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/player',
      builder: (context, state) => const PlayerPage(),
    ),
    GoRoute(
      path: '/playlist/:id',
      builder: (context, state) => PlaylistPage(
        playlistId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchPage(),
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>(
          create: (context) => ApiService(baseUrl: 'YOUR_API_BASE_URL'),
        ),
        Provider<AudioPlayerService>(
          create: (context) => AudioPlayerService(),
          dispose: (context, service) => service.dispose(),
        ),
      ],
      child: MaterialApp.router(
        title: 'Music App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        routerConfig: _router,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('zh'),
        ],
      ),
    );
  }
}

// 临时的页面占位符
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: const Center(child: Text('Home Page')),
    );
  }
}

class PlayerPage extends StatelessWidget {
  const PlayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Player')),
      body: const Center(child: Text('Player Page')),
    );
  }
}

class PlaylistPage extends StatelessWidget {
  final String playlistId;
  
  const PlaylistPage({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Playlist')),
      body: Center(child: Text('Playlist: $playlistId')),
    );
  }
}

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: const Center(child: Text('Search Page')),
    );
  }
} 