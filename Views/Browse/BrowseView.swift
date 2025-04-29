import SwiftUI

struct BrowseView: View {
    @StateObject private var viewModel = BrowseViewModel()
    
    // 支持预览的初始化方法
    init(viewModel: BrowseViewModel? = nil) {
        if let viewModel = viewModel {
            _viewModel = StateObject(wrappedValue: viewModel)
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                if viewModel.isLoading {
                    ProgressView("加载中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.showingEmbyContent {
                    // 显示Emby内容
                    LazyVStack(alignment: .leading, spacing: 20) {
                        Text("NAS音乐库")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        // 显示Emby音乐库
                        ForEach(viewModel.embyMusicLibraries.indices, id: \.self) { index in
                            if let library = viewModel.embyMusicLibraries[index] as? [String: Any],
                               let name = library["Name"] as? String,
                               let itemId = library["ItemId"] as? String {
                                
                                VStack(alignment: .leading) {
                                    Text(name)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .padding(.bottom, 5)
                                    
                                    // 显示该音乐库的专辑
                                    if let albums = viewModel.embyAlbums[itemId], !albums.isEmpty {
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 15) {
                                                ForEach(albums) { album in
                                                    EmbyAlbumCard(album: album)
                                                }
                                            }
                                        }
                                    } else {
                                        Text("加载专辑中...")
                                            .foregroundColor(.secondary)
                                            .padding(.vertical)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                } else {
                    // 显示本地内容
                    LazyVStack(alignment: .leading, spacing: 20) {
                        ForEach(viewModel.categories, id: \.self) { category in
                            CategorySection(category: category, playlists: viewModel.categoryPlaylists[category] ?? [])
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("浏览")
            .onAppear {
                viewModel.loadBrowseData()
            }
        }
    }
}

// Emby专辑卡片
struct EmbyAlbumCard: View {
    let album: Album
    
    var body: some View {
        VStack(alignment: .leading) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 180, height: 180)
                
                VStack {
                    Text(album.title.prefix(1))
                        .font(.system(size: 50))
                        .fontWeight(.bold)
                    
                    Text(album.artist)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            Text(album.title)
                .font(.headline)
                .lineLimit(1)
                .padding(.top, 5)
        }
        .frame(width: 180)
    }
}

// 分类区块组件
struct CategorySection: View {
    let category: String
    let playlists: [Playlist]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(category)
                .font(.title2)
                .fontWeight(.bold)
                .padding(.bottom, 5)
            
            if playlists.isEmpty {
                Text("暂无歌单")
                    .foregroundColor(.secondary)
                    .padding(.vertical)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(playlists) { playlist in
                            CategoryPlaylistCard(playlist: playlist)
                        }
                    }
                }
            }
        }
    }
}

// 分类歌单卡片
struct CategoryPlaylistCard: View {
    let playlist: Playlist
    
    var body: some View {
        VStack(alignment: .leading) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 180, height: 180)
                
                VStack {
                    Text(playlist.name.prefix(1))
                        .font(.system(size: 50))
                        .fontWeight(.bold)
                    
                    if let description = playlist.description {
                        Text(description.prefix(20))
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
            }
            
            Text(playlist.name)
                .font(.headline)
                .lineLimit(1)
                .padding(.top, 5)
        }
        .frame(width: 180)
    }
}