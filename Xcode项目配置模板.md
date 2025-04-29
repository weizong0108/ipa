# Xcode项目配置模板

本文档提供了Aurora Music应用在Xcode中的标准配置模板，用于确保打包IPA时的一致性和正确性。

## 基本项目信息

```
项目名称: Aurora Music
Bundle Identifier: com.auroramusic.app
版本号(Version): 1.0.0
构建号(Build): 1
部署目标: iOS 15.0+
设备支持: iPhone, iPad
```

## 签名与证书配置

### 开发环境配置
```
团队(Team): 您的开发团队名称
签名证书: Apple Development
配置文件: Development
```

### 发布环境配置
```
团队(Team): 您的开发团队名称
签名证书: Apple Distribution
配置文件: App Store
```

## 应用能力(Capabilities)配置

以下是Aurora Music应用需要启用的关键能力：

- **Background Modes**
  - Audio, AirPlay, and Picture in Picture
  - 说明：允许应用在后台继续播放音乐

- **App Groups** (如需要)
  - 组标识符: group.com.auroramusic.app
  - 说明：如果有扩展或共享数据需求时配置

## 构建设置(Build Settings)

### Swift编译器设置
```
Swift语言版本: Swift 5
构建库优化: Optimize for Speed (-O)
```

### 资源设置
```
资源打包: 启用资源打包(Enable On Demand Resources)
按需资源标签: music_resources
```

### 代码签名设置
```
代码签名身份(Release): Apple Distribution
代码签名风格: 自动(Automatic)
```

## Info.plist关键配置

以下是需要在Info.plist中配置的关键项：

```xml
<!-- 应用名称 -->
<key>CFBundleDisplayName</key>
<string>Aurora Music</string>

<!-- 隐私权限描述 -->
<key>NSMicrophoneUsageDescription</key>
<string>Aurora Music需要访问麦克风以支持语音搜索功能</string>

<!-- 后台模式配置 -->
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>

<!-- 支持的界面方向 -->
<key>UISupportedInterfaceOrientations</key>
<array>
    <string>UIInterfaceOrientationPortrait</string>
    <string>UIInterfaceOrientationLandscapeLeft</string>
    <string>UIInterfaceOrientationLandscapeRight</string>
</array>
```

## 导出选项配置

在使用Xcode或命令行导出IPA时，可以使用以下exportOptions.plist模板：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadSymbols</key>
    <true/>
    <key>uploadBitcode</key>
    <false/>
</dict>
</plist>
```

## 注意事项

1. 确保所有第三方库和依赖都已正确配置
2. 检查应用图标集是否完整（所有尺寸都已提供）
3. 确保启动屏(Launch Screen)已正确配置
4. 在Archive前，确保选择了"Generic iOS Device"或实际连接的设备
5. 构建配置应设置为"Release"而非"Debug"

按照此配置模板设置项目后，可以按照《打包IPA指南.md》中的步骤进行打包操作。