import SwiftUI

// 预览提供者
struct SongDetailView_Previews: PreviewProvider {
    static var previews: some View {
        // 创建预览视图
        SongDetailViewPreview()
    }
}

// 预览专用视图
struct SongDetailViewPreview: View {
    // 创建一个预览用的ViewModel和歌曲
    private var viewModel = PreviewSongDetailViewModel()
    private var song = Song(
        title: "晴天",
        artist: "周杰伦",
        album: "叶惠美",
        albumId: UUID(),
        coverURL: "https://example.com/cover1.jpg",
        duration: 269
    )
    
    var body: some View {
        NavigationView {
            SongDetailView(song: song, viewModel: viewModel)
        }
    }
}

// 预览专用ViewModel
class PreviewSongDetailViewModel: SongDetailViewModel {
    override init() {
        super.init()
        // 添加一些模拟数据
        self.lyrics = "[00:00.00] 作词 : 方文山\n[00:01.00] 作曲 : 周杰伦\n[00:02.00] 编曲 : 周杰伦\n[00:03.00]\n[00:04.00] 故事的小黄花\n[00:08.00] 从出生那年就飘着\n[00:12.00] 童年的荡秋千\n[00:16.00] 随记忆一直晃到现在"
        self.isLoading = false
    }
}