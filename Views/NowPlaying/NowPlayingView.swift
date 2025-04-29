import SwiftUI

struct NowPlayingView: View {
    @StateObject private var viewModel = NowPlayingViewModel()
    @State private var showingLyrics = false
    @State private var showingEqualizer = false
    @State private var showingShareSheet = false
    
    // 支持预览的初始化方法
    init(viewModel: NowPlayingViewModel? = nil) {
        if let viewModel = viewModel {
            _viewModel = StateObject(wrappedValue: viewModel)
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // 顶部标题和按钮
            HStack {
                Button(action: {
                    // 返回操作
                }) {
                    Image(systemName: "chevron.down")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text("正在播放")
                    .font(.headline)
                
                Spacer()
                
                Menu {
                    Button(action: {
                        showingLyrics.toggle()
                    }) {
                        Label("歌词", systemImage: "text.quote")
                    }
                    
                    Button(action: {
                        showingEqualizer.toggle()
                    }) {
                        Label("均衡器", systemImage: "slider.horizontal.3")
                    }
                    
                    if !viewModel.isDownloaded {
                        Button(action: {
                            viewModel.downloadSong()
                        }) {
                            Label("下载", systemImage: "arrow.down.circle")
                        }
                    }
                    
                    Button(action: {
                        showingShareSheet.toggle()
                    }) {
                        Label("分享", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal)
            
            if showingLyrics {
                LyricsView(viewModel: viewModel)
            } else {
                // 专辑封面
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 280, height: 280)
                    
                    if let currentSong = viewModel.currentSong {
                        Text(currentSong.title.prefix(1))
                            .font(.system(size: 80))
                            .fontWeight(.bold)
                    }
                }
                .padding()
                
                // 歌曲信息
                VStack(spacing: 8) {
                    if let currentSong = viewModel.currentSong {
                        Text(currentSong.title)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(currentSong.artist)
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        if let album = currentSong.album {
                            Text(album)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        // 下载进度指示器
                        if !viewModel.isDownloaded && viewModel.downloadProgress > 0 {
                            ProgressView(value: viewModel.downloadProgress)
                                .progressViewStyle(LinearProgressViewStyle())
                                .frame(width: 200)
                        }
                    } else {
                        Text("未播放任何歌曲")
                            .font(.title)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // 进度条
            VStack(spacing: 8) {
                Slider(value: $viewModel.progress, in: 0...1) { editing in
                    viewModel.isSeeking = editing
                    if !editing {
                        viewModel.seekToPosition(progress: viewModel.progress)
                    }
                }
                .accentColor(.blue)
                
                HStack {
                    Text(formatDuration(viewModel.currentTime))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let duration = viewModel.currentSong?.duration {
                        Text(formatDuration(duration))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("--:--")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)
            
            // 播放控制
            HStack(spacing: 40) {
                Button(action: {
                    viewModel.previous()
                }) {
                    Image(systemName: "backward.fill")
                        .font(.title)
                        .foregroundColor(.primary)
                }
                
                Button(action: {
                    viewModel.togglePlayPause()
                }) {
                    Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 70))
                        .foregroundColor(.blue)
                }
                
                Button(action: {
                    viewModel.next()
                }) {
                    Image(systemName: "forward.fill")
                        .font(.title)
                        .foregroundColor(.primary)
                }
            }
            
            // 底部控制
            HStack(spacing: 40) {
                Button(action: {
                    viewModel.toggleShuffle()
                }) {
                    Image(systemName: viewModel.isShuffleOn ? "shuffle.circle.fill" : "shuffle")
                        .font(.title3)
                        .foregroundColor(viewModel.isShuffleOn ? .blue : .primary)
                }
                
                Spacer()
                
                Button(action: {
                    viewModel.toggleRepeat()
                }) {
                    Image(systemName: viewModel.repeatMode == .none ? "repeat" : (viewModel.repeatMode == .all ? "repeat.circle.fill" : "repeat.1.circle.fill"))
                        .font(.title3)
                        .foregroundColor(viewModel.repeatMode != .none ? .blue : .primary)
                }
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showingEqualizer) {
            EqualizerView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let song = viewModel.currentSong {
                ShareSheet(items: ["\(song.title) - \(song.artist)"])
            }
        }
        .onAppear {
            viewModel.loadLyrics()
        }
    }
    
    // 格式化时长
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// 分享功能
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}