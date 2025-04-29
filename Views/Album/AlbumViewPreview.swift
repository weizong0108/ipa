import SwiftUI

// 预览提供者
struct AlbumView_Previews: PreviewProvider {
    static var previews: some View {
        // 创建预览视图
        AlbumViewPreview()
    }
}

// 预览专用视图
struct AlbumViewPreview: View {
    // 创建一个预览用的ViewModel和专辑ID
    private var viewModel = PreviewAlbumViewModel()
    private var albumId = UUID()
    
    var body: some View {
        NavigationView {
            AlbumView(albumId: albumId, viewModel: viewModel)
        }
    }
}

// 预览专用ViewModel
class PreviewAlbumViewModel: AlbumViewModel {
    override init() {
        super.init()
        // 添加一些模拟数据
        let albumId = UUID()
        let songs = [
            Song(title: "晴天", artist: "周杰伦", album: "叶惠美", albumId: albumId, coverURL: "https://example.com/cover1.jpg", duration: 269),
            Song(title: "东风破", artist: "周杰伦", album: "叶惠美", albumId: albumId, coverURL: "https://example.com/cover1.jpg", duration: 234),
            Song(title: "你听得到", artist: "周杰伦", album: "叶惠美", albumId: albumId, coverURL: "https://example.com/cover1.jpg", duration: 294),
            Song(title: "以父之名", artist: "周杰伦", album: "叶惠美", albumId: albumId, coverURL: "https://example.com/cover1.jpg", duration: 342),
            Song(title: "爱情悬崖", artist: "周杰伦", album: "叶惠美", albumId: albumId, coverURL: "https://example.com/cover1.jpg", duration: 258)
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