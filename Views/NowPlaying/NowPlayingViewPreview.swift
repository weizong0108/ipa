import SwiftUI

// 预览提供者
struct NowPlayingView_Previews: PreviewProvider {
    static var previews: some View {
        // 创建预览视图
        NowPlayingViewPreview()
    }
}

// 预览专用视图
struct NowPlayingViewPreview: View {
    // 创建一个预览用的ViewModel
    private var viewModel = PreviewNowPlayingViewModel()
    
    var body: some View {
        NowPlayingView(viewModel: viewModel)
    }
}

// 预览专用ViewModel
class PreviewNowPlayingViewModel: NowPlayingViewModel {
    override init() {
        super.init()
        // 添加一些模拟数据
        self.currentSong = Song(title: "晴天", artist: "周杰伦", album: "叶惠美", coverURL: "https://example.com/cover1.jpg", duration: 269)
        self.isPlaying = true
        self.progress = 0.3
        self.currentTime = 80
        self.isShuffleOn = true
        self.repeatMode = .all
        self.queue = [
            Song(title: "晴天", artist: "周杰伦", album: "叶惠美", coverURL: "https://example.com/cover1.jpg", duration: 269),
            Song(title: "稻香", artist: "周杰伦", album: "魔杰座", coverURL: "https://example.com/cover2.jpg", duration: 234),
            Song(title: "倒影", artist: "陈奕迅", album: "rice & shine", coverURL: "https://example.com/cover3.jpg", duration: 294)
        ]
    }
}