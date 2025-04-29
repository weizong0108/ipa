# Aurora Music应用打包IPA指南

## 前期准备

### 1. 项目功能检查

在打包前，请确保以下功能正常工作：

- 音乐播放功能（播放、暂停、上一首、下一首）
- 歌曲详情页面显示
- 专辑和歌单浏览
- 搜索功能
- 用户个人页面

### 2. 项目配置检查

- 确保Bundle Identifier设置正确（如：com.auroramusic.app）
- 版本号和构建号已更新
- 应用图标和启动屏已设置
- 确保所有资源文件（图片、音频等）已正确引用

## 使用Xcode打包IPA

### 1. 证书和配置文件设置

1. 打开Xcode，选择项目导航器中的项目
2. 选择正确的Target
3. 在"Signing & Capabilities"选项卡中：
   - 确保"Automatically manage signing"已勾选（推荐新手使用）
   - 或手动选择正确的开发者证书和配置文件
   - 确保Team已正确设置为您的开发者账号

### 2. 构建设置

1. 在Xcode中，选择"Product" > "Scheme" > "Edit Scheme"
2. 在弹出的窗口中，选择"Run"选项卡
3. 确保"Build Configuration"设置为"Release"
4. 关闭窗口保存设置

### 3. 创建Archive

1. 连接iOS设备（可选，也可以不连接设备直接打包）
2. 选择正确的设备目标（如Generic iOS Device）
3. 选择"Product" > "Archive"
4. 等待Xcode完成构建和归档过程

### 4. 导出IPA文件

1. 归档完成后，Xcode会自动打开"Organizer"窗口
2. 选择刚刚创建的归档文件
3. 点击"Distribute App"按钮
4. 选择分发方法：
   - 对于测试：选择"Development"
   - 对于企业内部分发：选择"Enterprise"
   - 对于App Store发布：选择"App Store Connect"
   - 对于临时测试：选择"Ad Hoc"
5. 按照向导完成剩余步骤
6. 选择保存IPA文件的位置
7. 点击"Export"按钮完成导出

## 使用命令行打包（可选）

如果需要自动化打包流程，可以使用以下命令行方法：

```bash
# 1. 清理项目
xcodebuild clean -workspace AuroraMusic.xcworkspace -scheme AuroraMusic -configuration Release

# 2. 构建归档文件
xcodebuild archive -workspace AuroraMusic.xcworkspace -scheme AuroraMusic -configuration Release -archivePath ./build/AuroraMusic.xcarchive

# 3. 导出IPA
xcodebuild -exportArchive -archivePath ./build/AuroraMusic.xcarchive -exportOptionsPlist exportOptions.plist -exportPath ./build
```

注意：需要提前创建exportOptions.plist文件，内容如下：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
</dict>
</plist>
```

## 安装和测试

### 1. 使用iTunes安装（旧方法）

1. 将设备连接到电脑
2. 打开iTunes
3. 选择设备
4. 将IPA文件拖到iTunes窗口中
5. 点击"同步"按钮

### 2. 使用Apple Configurator 2安装（推荐）

1. 从Mac App Store下载并安装Apple Configurator 2
2. 将设备连接到电脑
3. 打开Apple Configurator 2
4. 选择已连接的设备
5. 点击"添加" > "应用程序"
6. 选择IPA文件并安装

### 3. 使用TestFlight分发（App Store测试）

1. 登录App Store Connect
2. 上传构建版本
3. 添加测试人员
4. 测试人员通过TestFlight应用安装和测试

## 常见问题解决

1. **证书问题**：确保开发者证书有效且未过期
2. **配置文件不匹配**：重新生成配置文件或在Apple Developer网站更新设备UDID
3. **构建失败**：检查代码错误和警告，确保所有依赖库正确引用
4. **安装失败**：确认设备UDID已添加到开发者账号并包含在配置文件中

## 注意事项

- IPA文件只能在已注册的设备上安装（除非使用企业证书）
- 开发者证书有效期为一年，需及时续期
- 测试前请在不同设备和iOS版本上验证应用功能
- 确保应用符合Apple的App Store审核指南（如需上架）