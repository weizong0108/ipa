import SwiftUI

// 需要先导入自定义视图，以便在HomeView中使用
import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    
    // 支持预览的初始化方法
    init(viewModel: HomeViewModel? = nil) {
        if let viewModel = viewModel {
            _viewModel = StateObject(wrappedValue: viewModel)
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if viewModel.isLoading {
                        ProgressView("加载中...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // 推荐歌单
                        VStack(alignment: .leading) {
                            Text("推荐歌单")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(viewModel.featuredPlaylists) { playlist in
                                        PlaylistCard(playlist: playlist)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // 推荐歌曲
                        VStack(alignment: .leading) {
                            Text("推荐歌曲")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            VStack(spacing: 10) {
                                ForEach(viewModel.recommendedSongs) { song in
                                    SongRow(song: song)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("发现音乐")
            .onAppear {
                viewModel.loadHomeData()
            }
        }
    }
}

// 歌单卡片组件
struct PlaylistCard: View {
    let playlist: Playlist
    
    var body: some View {
        NavigationLink(destination: AlbumView(albumId: playlist.id)) {
            VStack(alignment: .leading) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(1, contentMode: .fit)
                    .frame(width: 150, height: 150)
                
                Text(playlist.name.prefix(1))
                    .font(.system(size: 50))
                    .fontWeight(.bold)
            }
            
            Text(playlist.name)
                .font(.headline)
                .lineLimit(1)
            
            if let description = playlist.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .frame(width: 150)
            }
        }
    }
}

// 歌曲行组件
struct SongRow: View {
    let song: Song
    
    var body: some View {
        NavigationLink(destination: SongDetailView(song: song)) {
        HStack {
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                
                Text(song.title.prefix(1))
                    .font(.headline)
            }
            
            VStack(alignment: .leading) {
                Text(song.title)
                    .font(.headline)
                
                Text(song.artist)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let duration = song.duration {
                Text(formatDuration(duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    }
    
    // 格式化时长
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}