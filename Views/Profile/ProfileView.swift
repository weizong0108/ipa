import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    
    // 支持预览的初始化方法
    init(viewModel: ProfileViewModel? = nil) {
        if let viewModel = viewModel {
            _viewModel = StateObject(wrappedValue: viewModel)
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 用户信息卡片
                    VStack(spacing: 15) {
                        // 头像
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 100, height: 100)
                            
                            if let username = viewModel.userProfile?.username {
                                Text(String(username.prefix(1)))
                                    .font(.system(size: 40))
                                    .fontWeight(.bold)
                            } else {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        // 用户名
                        Text(viewModel.userProfile?.username ?? "未登录")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        // 登录按钮
                        if viewModel.userProfile == nil {
                            Button(action: {
                                viewModel.showLoginView = true
                            }) {
                                Text("登录/注册")
                                    .fontWeight(.semibold)
                                    .frame(width: 120)
                                    .padding(.vertical, 8)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // NAS服务器连接状态卡片
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text("NAS服务器")
                                .font(.headline)
                            Spacer()
                            if viewModel.isEmbyConnected {
                                Text("已连接")
                                    .foregroundColor(.green)
                                    .font(.subheadline)
                            }
                        }
                        .padding(.horizontal)
                        
                        if viewModel.isEmbyConnected, let serverInfo = viewModel.embyServerInfo {
                            // 显示服务器信息
                            VStack(alignment: .leading, spacing: 8) {
                                Text(serverInfo["ServerName"] as? String ?? "未知服务器")
                                    .font(.headline)
                                Text("版本: \(serverInfo["Version"] as? String ?? "未知")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Button(action: {
                                        viewModel.showEmbyConnectView = true
                                    }) {
                                        Text("重新连接")
                                            .font(.caption)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.blue)
                                            .foregroundColor(.white)
                                            .cornerRadius(15)
                                    }
                                    
                                    Button(action: {
                                        viewModel.disconnectEmbyServer()
                                    }) {
                                        Text("断开连接")
                                            .font(.caption)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.red)
                                            .foregroundColor(.white)
                                            .cornerRadius(15)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        } else {
                            // 显示连接按钮
                            Button(action: {
                                viewModel.showEmbyConnectView = true
                            }) {
                                HStack {
                                    Image(systemName: "link")
                                    Text("连接到NAS服务器")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // 我的音乐
                    VStack(alignment: .leading, spacing: 15) {
                        Text("我的音乐")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(viewModel.myMusicOptions, id: \.title) { option in
                            Button(action: {
                                // 处理点击事件
                            }) {
                                HStack {
                                    Image(systemName: option.icon)
                                        .font(.title3)
                                        .foregroundColor(.blue)
                                        .frame(width: 30)
                                    
                                    Text(option.title)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal)
                            }
                            Divider()
                                .padding(.leading, 60)
                        }
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // 设置选项
                    VStack(alignment: .leading, spacing: 15) {
                        Text("设置")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(viewModel.settingsOptions, id: \.title) { option in
                            Button(action: {
                                // 处理点击事件
                            }) {
                                HStack {
                                    Image(systemName: option.icon)
                                        .font(.title3)
                                        .foregroundColor(.blue)
                                        .frame(width: 30)
                                    
                                    Text(option.title)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal)
                            }
                            Divider()
                                .padding(.leading, 60)
                        }
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("我的")
            .sheet(isPresented: $viewModel.showLoginView) {
                Text("登录/注册界面")
                    .font(.title)
                    .padding()
            }
            .sheet(isPresented: $viewModel.showEmbyConnectView) {
                EmbyConnectView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Emby服务器连接视图
struct EmbyConnectView: View {
    @ObservedObject var viewModel: ProfileViewModel
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("服务器信息")) {
                    TextField("服务器地址", text: $viewModel.serverUrl)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .keyboardType(.URL)
                    
                    TextField("用户名 (可选)", text: $viewModel.embyUsername)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    SecureField("密码 (可选)", text: $viewModel.embyPassword)
                }
                
                Section {
                    Button(action: {
                        // 使用Task执行异步操作
                        Task {
                            await viewModel.connectToEmbyServer()
                            
                            // 如果连接成功，关闭视图
                            if viewModel.isEmbyConnected {
                                viewModel.showEmbyConnectView = false
                            }
                        }
                    }) {
                        HStack {
                            Spacer()
                            if viewModel.isConnecting {
                                ProgressView()
                                    .padding(.trailing, 10)
                            }
                            Text("连接")
                            Spacer()
                        }
                    }
                    .disabled(viewModel.isConnecting)
                }
                
                if let error = viewModel.connectionError {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("连接到NAS服务器")
            .navigationBarItems(trailing: Button("取消") {
                viewModel.showEmbyConnectView = false
            })
        
        }
    }
}