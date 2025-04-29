import SwiftUI

// 预览提供者
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        // 创建预览视图
        HomeViewPreview()
    }
}

// 预览专用视图
struct HomeViewPreview: View {
    // 创建一个预览用的ViewModel
    private var viewModel = PreviewHomeViewModel()
    
    var body: some View {
        HomeView(viewModel: viewModel)
    }
}

// 预览专用ViewModel
class PreviewHomeViewModel: HomeViewModel {
    override init() {
        super.init()
        // 添加一些模拟数据
        self.featuredPlaylists = [
            Playlist(name: "华语经典", description: "永恒的华语经典歌曲合集", coverURL: "https://example.com/playlist1.jpg"),
            Playlist(name: "流行热歌", description: "当下最流行的热门歌曲", coverURL: "https://example.com/playlist2.jpg"),
            Playlist(name: "轻音乐", description: "舒缓心情的轻音乐精选", coverURL: "https://example.com/playlist3.jpg")
        ]
        self.recommendedSongs = [
            Song(title: "晴天", artist: "周杰伦", album: "叶惠美", coverURL: "https://example.com/cover1.jpg", duration: 269),
            Song(title: "稻香", artist: "周杰伦", album: "魔杰座", coverURL: "https://example.com/cover2.jpg", duration: 234),
            Song(title: "倒影", artist: "陈奕迅", album: "rice & shine", coverURL: "https://example.com/cover3.jpg", duration: 294),
            Song(title: "光年之外", artist: "邓紫棋", album: "光年之外", coverURL: "https://example.com/cover6.jpg", duration: 235)
        ]
        self.isLoading = false
    }
}