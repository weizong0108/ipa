import SwiftUI

// 预览提供者
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        // 创建预览视图
        ProfileViewPreview()
    }
}

// 预览专用视图
struct ProfileViewPreview: View {
    // 创建一个预览用的ViewModel
    private var viewModel = PreviewProfileViewModel()
    
    var body: some View {
        ProfileView(viewModel: viewModel)
    }
}

// 预览专用ViewModel
class PreviewProfileViewModel: ProfileViewModel {
    override init() {
        super.init()
        // 添加一些模拟数据
        self.userProfile = UserProfile(id: "1", username: "音乐爱好者", email: "music@example.com")
        // 预览中不显示登录界面
        self.showLoginView = false
    }
}