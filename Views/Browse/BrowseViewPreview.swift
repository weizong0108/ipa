import SwiftUI

// 预览提供者
struct BrowseView_Previews: PreviewProvider {
    static var previews: some View {
        // 创建预览视图
        BrowseViewPreview()
    }
}

// 预览专用视图
struct BrowseViewPreview: View {
    // 创建一个预览用的ViewModel
    private var viewModel = PreviewBrowseViewModel()
    
    var body: some View {
        BrowseView(viewModel: viewModel)
    }
}

// 预览专用ViewModel
class PreviewBrowseViewModel: BrowseViewModel {
    override init() {
        super.init()
        // 添加一些模拟数据
        self.categories = ["流行", "摇滚", "民谣"]
        self.categoryPlaylists = [
            "流行": [
                Playlist(name: "流行热歌", description: "当下最流行的热门歌曲", coverURL: "https://example.com/playlist2.jpg"),
                Playlist(name: "华语流行", description: "华语流行音乐精选", coverURL: "https://example.com/playlist1.jpg")
            ],
            "摇滚": [
                Playlist(name: "经典摇滚", description: "经典摇滚音乐合集", coverURL: "https://example.com/playlist3.jpg"),
                Playlist(name: "摇滚现场", description: "震撼现场演出精选", coverURL: "https://example.com/playlist4.jpg")
            ],
            "民谣": [
                Playlist(name: "民谣小调", description: "轻松惬意的民谣小调", coverURL: "https://example.com/playlist5.jpg")
            ]
        ]
        self.isLoading = false
    }
}