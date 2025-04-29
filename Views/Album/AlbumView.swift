import SwiftUI

struct AlbumView: View {
    let albumId: UUID
    @StateObject private var viewModel = AlbumViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    // 支持预览的初始化方法
    init(albumId: UUID, viewModel: AlbumViewModel? = nil) {
        self.albumId = albumId
        if let viewModel = viewModel {
            _viewModel = StateObject(wrappedValue: viewModel)
        }
    }
    
    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView("加载中...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
            } else if let album = viewModel.album {
                VStack(alignment: .leading, spacing: 20) {
                    // 专辑封面和信息
                    HStack(alignment: .top, spacing: 15) {
                        // 封面图
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.3))
                                .aspectRatio(1, contentMode: .fit)
                                .frame(width: 120, height: 120)
                            
                            if let coverURL = album.coverURL {
                                // 实际项目中应使用异步图片加载
                                Text(album.title.prefix(1))
                                    .font(.system(size: 40))
                                    .fontWeight(.bold)
                            } else {
                                Text(album.title.prefix(1))
                                    .font(.system(size: 40))
                                    .fontWeight(.bold)
                            }
                        }
                        
                        // 专辑信息
                        VStack(alignment: .leading, spacing: 8) {
                            Text(album.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .lineLimit(2)
                            
                            Text(album.artist)
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            if let releaseDate = album.releaseDate {
                                Text(formatDate(releaseDate))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("\(album.songCount) 首歌曲")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text(formatDuration(album.totalDuration))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 5)
                    }
                    .padding(.horizontal)
                    
                    // 专辑描述
                    if let description = album.description {
                        Text(description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                    
                    // 播放控制
                    HStack(spacing: 30) {
                        Button(action: {
                            viewModel.playAlbum(album: album)
                        }) {
                            VStack {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 40))
                                Text("播放")
                                    .font(.caption)
                            }
                        }
                        
                        Button(action: {
                            viewModel.shufflePlay(album: album)
                        }) {
                            VStack {
                                Image(systemName: "shuffle.circle.fill")
                                    .font(.system(size: 40))
                                Text("随机播放")
                                    .font(.caption)
                            }
                        }
                        
                        Button(action: {
                            viewModel.downloadAlbum(album: album)
                        }) {
                            VStack {
                                Image(systemName: "arrow.down.circle")
                                    .font(.system(size: 40))
                                Text("下载")
                                    .font(.caption)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    
                    // 歌曲列表
                    VStack(alignment: .leading, spacing: 5) {
                        Text("歌曲")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        ForEach(album.songs) { song in
                            NavigationLink(destination: SongDetailView(song: song)) {
                                AlbumSongRow(song: song, index: album.songs.firstIndex(where: { $0.id == song.id }) ?? 0)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Divider()
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.top, 20)
            } else if viewModel.error != nil {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                        .padding()
                    
                    Text("加载专辑信息失败")
                        .font(.headline)
                    
                    Button("重试") {
                        viewModel.loadAlbum(albumId: albumId)
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 100)
            }
        }
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            HStack {
                Image(systemName: "chevron.left")
                Text("返回")
            }
        })
        .onAppear {
            viewModel.loadAlbum(albumId: albumId)
        }
    }
    
    // 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // 格式化时长
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes) 分钟"
    }
}

// 专辑中的歌曲行
struct AlbumSongRow: View {
    let song: Song
    let index: Int
    
    var body: some View {
        HStack(spacing: 15) {
            // 序号
            Text("\(index + 1)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 25, alignment: .center)
            
            // 歌曲信息
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.body)
                    .lineLimit(1)
                
                Text(song.artist)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // 时长
            if let duration = song.duration {
                Text(formatSongDuration(duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 更多按钮
            Button(action: {}) {
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // 格式化歌曲时长
    private func formatSongDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// 专辑ViewModel
class AlbumViewModel: ObservableObject {
    @Published var album: Album? = nil
    @Published var isLoading: Bool = false
    @Published var error: Error? = nil
    
    func loadAlbum(albumId: UUID) {
        isLoading = true
        error = nil
        
        // 模拟加载专辑数据
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // 创建模拟数据
            let songs = [
                Song(title: "专辑歌曲1", artist: "周杰伦", album: "叶惠美", albumId: albumId, coverURL: "https://example.com/cover1.jpg", duration: 269),
                Song(title: "专辑歌曲2", artist: "周杰伦", album: "叶惠美", albumId: albumId, coverURL: "https://example.com/cover1.jpg", duration: 234),
                Song(title: "专辑歌曲3", artist: "周杰伦", album: "叶惠美", albumId: albumId, coverURL: "https://example.com/cover1.jpg", duration: 294),
                Song(title: "专辑歌曲4", artist: "周杰伦", album: "叶惠美", albumId: albumId, coverURL: "https://example.com/cover1.jpg", duration: 282),
                Song(title: "专辑歌曲5", artist: "周杰伦", album: "叶惠美", albumId: albumId, coverURL: "https://example.com/cover1.jpg", duration: 325)
            ]
            
            let releaseDate = Calendar.current.date(from: DateComponents(year: 2003, month: 7, day: 31))
            
            self.album = Album(
                id: albumId,
                title: "叶惠美",
                artist: "周杰伦",
                releaseDate: releaseDate,
                coverURL: "https://example.com/album1.jpg",
                description: "《叶惠美》是周杰伦发行的第四张专辑，收录了《晴天》、《东风破》等经典歌曲。",
                songs: songs
            )
            
            self.isLoading = false
        }
    }
    
    func playAlbum(album: Album) {
        // 实际项目中应调用音频播放服务
        print("播放专辑: \(album.title)")
    }
    
    func shufflePlay(album: Album) {
        // 实际项目中应调用音频播放服务，并启用随机播放
        print("随机播放专辑: \(album.title)")
    }
    
    func downloadAlbum(album: Album) {
        // 实际项目中应实现下载功能
        print("下载专辑: \(album.title)")
    }
}

// 预览
struct AlbumView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AlbumView(albumId: UUID())
        }
    }
}