import SwiftUI

struct SongDetailView: View {
    let song: Song
    @StateObject private var viewModel = SongDetailViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    // 支持预览的初始化方法
    init(song: Song, viewModel: SongDetailViewModel? = nil) {
        self.song = song
        if let viewModel = viewModel {
            _viewModel = StateObject(wrappedValue: viewModel)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 封面图
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(1, contentMode: .fit)
                        .frame(maxWidth: 300)
                    
                    if let coverURL = song.coverURL {
                        // 实际项目中应使用异步图片加载
                        Text(song.title.prefix(1))
                            .font(.system(size: 80))
                            .fontWeight(.bold)
                    } else {
                        Text(song.title.prefix(1))
                            .font(.system(size: 80))
                            .fontWeight(.bold)
                    }
                }
                .padding(.top, 20)
                
                // 歌曲信息
                VStack(spacing: 8) {
                    Text(song.title)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(song.artist)
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    if let album = song.album {
                        Button(action: {
                            viewModel.navigateToAlbum(albumId: song.albumId)
                        }) {
                            Text(album)
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        .disabled(song.albumId == nil)
                    }
                }
                .padding(.horizontal)
                
                // 播放控制
                HStack(spacing: 40) {
                    Button(action: {
                        viewModel.addToPlaylist(song: song)
                    }) {
                        VStack {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 30))
                            Text("添加到歌单")
                                .font(.caption)
                        }
                    }
                    
                    Button(action: {
                        viewModel.playSong(song: song)
                    }) {
                        VStack {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 60))
                            Text("播放")
                                .font(.caption)
                        }
                    }
                    
                    Button(action: {
                        viewModel.downloadSong(song: song)
                    }) {
                        VStack {
                            Image(systemName: "arrow.down.circle")
                                .font(.system(size: 30))
                            Text("下载")
                                .font(.caption)
                        }
                    }
                }
                .padding()
                
                // 歌曲详情
                if viewModel.isLoading {
                    ProgressView("加载中...")
                } else if let lyrics = viewModel.lyrics {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("歌词")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Text(lyrics)
                            .font(.body)
                            .padding(.horizontal)
                    }
                }
                
                Spacer()
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
            viewModel.loadSongDetails(song: song)
        }
    }
}

// 歌曲详情ViewModel
class SongDetailViewModel: ObservableObject {
    @Published var lyrics: String? = nil
    @Published var isLoading: Bool = false
    @Published var error: Error? = nil
    @Published var navigateToAlbumView: Bool = false
    @Published var selectedAlbumId: UUID? = nil
    
    func loadSongDetails(song: Song) {
        isLoading = true
        
        // 模拟加载歌词
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.lyrics = "这里是歌词内容...\n第二行歌词...\n第三行歌词..."
            self.isLoading = false
        }
    }
    
    func playSong(song: Song) {
        // 实际项目中应调用音频播放服务
        print("播放歌曲: \(song.title)")
    }
    
    func addToPlaylist(song: Song) {
        // 实际项目中应显示添加到歌单的弹窗
        print("添加到歌单: \(song.title)")
    }
    
    func downloadSong(song: Song) {
        // 实际项目中应实现下载功能
        print("下载歌曲: \(song.title)")
    }
    
    func navigateToAlbum(albumId: UUID?) {
        guard let albumId = albumId else { return }
        self.selectedAlbumId = albumId
        self.navigateToAlbumView = true
    }
}

// 预览
struct SongDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SongDetailView(song: Song(
                title: "晴天",
                artist: "周杰伦",
                album: "叶惠美",
                albumId: UUID(),
                coverURL: "https://example.com/cover1.jpg",
                duration: 269
            ))
        }
    }
}