import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @Environment(\.colorScheme) private var colorScheme
    
    // 支持预览的初始化方法
    init(viewModel: SearchViewModel? = nil) {
        if let viewModel = viewModel {
            _viewModel = StateObject(wrappedValue: viewModel)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // 搜索框
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("搜索歌曲、歌单", text: $viewModel.searchQuery)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    if !viewModel.searchQuery.isEmpty {
                        Button(action: {
                            viewModel.searchQuery = ""
                            viewModel.searchResults = SearchViewModel.SearchResults()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // 搜索源切换和搜索按钮
                HStack {
                    // 搜索源切换
                    if let embyService = EmbyService.shared, embyService.isConnected {
                        Button(action: {
                            viewModel.toggleSearchSource()
                        }) {
                            HStack {
                                Image(systemName: viewModel.searchSource == .emby ? "server.rack" : "iphone")
                                Text(viewModel.searchSource == .emby ? "NAS" : "本地")
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                        }
                    }
                    
                    // 搜索按钮
                    Button(action: {
                        viewModel.search()
                    }) {
                        Text("搜索")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(viewModel.searchQuery.isEmpty)
                    .opacity(viewModel.searchQuery.isEmpty ? 0.6 : 1)
                }
                .padding(.horizontal)
                
                // 搜索结果
                if viewModel.isSearching {
                    Spacer()
                    ProgressView("搜索中...")
                    Spacer()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // 显示搜索源信息
                            if !viewModel.searchQuery.isEmpty {
                                HStack {
                                    Text("搜索源: \(viewModel.searchSource == .emby ? "NAS服务器" : "本地")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                            
                            // Emby搜索结果
                            if viewModel.searchSource == .emby && !viewModel.searchResults.embyItems.isEmpty {
                                VStack(alignment: .leading) {
                                    Text("NAS搜索结果")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .padding(.horizontal)
                                    
                                    ForEach(viewModel.searchResults.embyItems.indices, id: \.self) { index in
                                        if let item = viewModel.searchResults.embyItems[index] as? [String: Any],
                                           let name = item["Name"] as? String,
                                           let type = item["Type"] as? String {
                                            
                                            EmbyItemRow(name: name, type: type, item: item)
                                                .padding(.horizontal)
                                        }
                                    }
                                }
                            }
                            
                            // 本地歌曲结果
                            if viewModel.searchSource == .local && !viewModel.searchResults.songs.isEmpty {
                                VStack(alignment: .leading) {
                                    Text("歌曲")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .padding(.horizontal)
                                    
                                    ForEach(viewModel.searchResults.songs) { song in
                                        NavigationLink(destination: SongDetailView(song: song)) {
                                            SearchSongRow(song: song)
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                            
                            // 本地歌单结果
                            if viewModel.searchSource == .local && !viewModel.searchResults.playlists.isEmpty {
                                VStack(alignment: .leading) {
                                    Text("歌单")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .padding(.horizontal)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 15) {
                                            ForEach(viewModel.searchResults.playlists) { playlist in
                                                NavigationLink(destination: AlbumView(albumId: playlist.id)) {
                                                    SearchPlaylistCard(playlist: playlist)
                                                }
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                            
                            // 无结果提示
                            if viewModel.searchResults.songs.isEmpty && viewModel.searchResults.playlists.isEmpty && !viewModel.searchQuery.isEmpty && !viewModel.isSearching {
                                VStack {
                                    Spacer()
                                    Text("未找到相关结果")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity, minHeight: 200)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("搜索")
        }
    }
}

// Emby项目行
struct EmbyItemRow: View {
    let name: String
    let type: String
    let item: [String: Any]
    
    var body: some View {
        HStack(spacing: 15) {
            // 图标
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: iconForType(type))
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            // 信息
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack {
                    Text(displayType(type))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let artist = item["AlbumArtist"] as? String ?? item["Artist"] as? String {
                        Text("• \(artist)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // 播放按钮
            Button(action: {
                // 播放功能将在后续实现
            }) {
                Image(systemName: "play.circle")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
    
    // 根据类型返回图标
    private func iconForType(_ type: String) -> String {
        switch type.lowercased() {
        case "audio":
            return "music.note"
        case "musicalbum":
            return "square.stack"
        case "musicartist":
            return "person.crop.circle"
        default:
            return "doc"
        }
    }
    
    // 显示类型名称
    private func displayType(_ type: String) -> String {
        switch type.lowercased() {
        case "audio":
            return "歌曲"
        case "musicalbum":
            return "专辑"
        case "musicartist":
            return "艺术家"
        default:
            return type
        }
    }
}

// 搜索结果歌曲行
struct SearchSongRow: View {
    let song: Song
    
    var body: some View {
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
        }
        .padding(.vertical, 4)
    }
}

// 搜索结果歌单卡片
struct SearchPlaylistCard: View {
    let playlist: Playlist
    
    var body: some View {
        VStack(alignment: .leading) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(1, contentMode: .fit)
                    .frame(width: 150, height: 150)
                
                Text(playlist.name.prefix(1))
                    .font(.system(size: 40))
                    .fontWeight(.bold)
            }
            
            Text(playlist.name)
                .font(.headline)
                .lineLimit(1)
        }
        .frame(width: 150)
    }
}

// 预览提供者
struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        // 创建预览视图
        SearchViewPreview()
    }
}

// 预览专用视图
struct SearchViewPreview: View {
    // 创建一个预览用的ViewModel
    private var viewModel = PreviewSearchViewModel()
    
    var body: some View {
        SearchView(viewModel: viewModel)
    }
}

// 预览专用ViewModel
class PreviewSearchViewModel: SearchViewModel {
    override init() {
        super.init()
        // 添加一些模拟数据
        self.searchQuery = "流行"
        self.searchResults.songs = [
            Song(title: "晴天", artist: "周杰伦", album: "叶惠美", duration: 269),
            Song(title: "稻香", artist: "周杰伦", album: "魔杰座", duration: 223),
            Song(title: "倒影", artist: "陈奕迅", album: "rice & shine", duration: 294)
        ]
        self.searchResults.playlists = [
            Playlist(name: "华语流行经典", description: "经典华语流行歌曲合集"),
            Playlist(name: "2023年度热门", description: "年度流行歌曲精选")
        ]
        self.isSearching = false
    }
}
}