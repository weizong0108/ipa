import SwiftUI

struct ContentView: View {
    @EnvironmentObject var router: Router

    var body: some View {
        TabView(selection: $router.currentTab) {
            HomeView()
                .tabItem { Label("首页", systemImage: "house") }
                .tag(Router.Tab.home)

            BrowseView()
                .tabItem { Label("浏览", systemImage: "square.grid.2x2") }
                .tag(Router.Tab.browse)

            SearchView()
                .tabItem { Label("搜索", systemImage: "magnifyingglass") }
                .tag(Router.Tab.search)

            NowPlayingView()
                .tabItem { Label("播放", systemImage: "play.circle") }
                .tag(Router.Tab.nowPlaying)

            ProfileView()
                .tabItem { Label("我的", systemImage: "person.crop.circle") }
                .tag(Router.Tab.profile)
        }
    }
}