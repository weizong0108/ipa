# Aurora Music 命令行打包IPA指南

本文档提供了使用命令行工具打包Aurora Music应用IPA文件的详细指南，适用于需要自动化构建流程的开发人员。

## 前期准备

在使用命令行打包前，请确保：

1. 已安装最新版本的Xcode命令行工具
   ```bash
   xcode-select --install
   ```

2. 拥有有效的开发者证书和配置文件
3. 已在Xcode中至少成功构建过一次项目
4. 知道您的开发团队ID (可在Apple Developer网站或Xcode中查看)

## 打包脚本使用说明

我们提供了一个名为`build_ipa.sh`的脚本，用于自动化构建和导出IPA文件。

### 基本用法

```bash
# 赋予脚本执行权限
chmod +x build_ipa.sh

# 使用默认设置运行脚本
./build_ipa.sh
```

### 高级选项

脚本支持以下命令行参数：

```bash
# 显示帮助信息
./build_ipa.sh --help

# 指定导出方法
./build_ipa.sh --method development

# 指定开发团队ID
./build_ipa.sh --team YOUR_TEAM_ID

# 指定Scheme名称
./build_ipa.sh --scheme AuroraMusic

# 指定Bundle Identifier
./build_ipa.sh --bundle com.auroramusic.app

# 组合使用多个参数
./build_ipa.sh --method app-store --team YOUR_TEAM_ID --scheme AuroraMusic
```

### 导出方法说明

脚本支持以下导出方法：

- `development`: 用于开发和测试，可在已注册的设备上安装
- `ad-hoc`: 用于内部测试，可在已注册的设备上安装
- `enterprise`: 用于企业内部分发，可在企业内任何设备上安装
- `app-store`: 用于提交到App Store审核

## 脚本工作流程

1. **清理项目**：移除之前的构建文件
2. **构建归档**：创建应用的xcarchive文件
3. **创建导出选项**：生成exportOptions.plist文件
4. **导出IPA**：从归档文件中导出IPA安装包

## 常见问题解决

### 1. 证书或配置文件问题

错误信息：`No signing certificate "iOS Distribution" found`

解决方法：
- 确保已安装有效的证书
- 在Xcode中刷新证书和配置文件
- 检查Apple Developer账户状态

### 2. 构建失败

错误信息：`xcodebuild: error: The workspace AuroraMusic.xcworkspace doesn't exist.`

解决方法：
- 确认项目结构（是否使用workspace或project）
- 使用正确的scheme名称
- 检查项目路径是否正确

### 3. 导出IPA失败

错误信息：`Error Domain=IDEDistributionErrorDomain Code=1 "No applicable devices found."`

解决方法：
- 确保配置文件包含目标设备的UDID
- 检查导出方法是否与配置文件匹配
- 验证teamID是否正确

## 自动化集成

此脚本可以轻松集成到CI/CD流程中，例如：

### Jenkins集成

```bash
# Jenkins构建步骤示例
chmod +x build_ipa.sh
./build_ipa.sh --method ad-hoc --team YOUR_TEAM_ID
```

### GitHub Actions集成

```yaml
# .github/workflows/build.yml 示例
name: Build IPA
on: [push]
jobs:
  build:
    runs-on: macos-latest
    steps:
    - uses: actions/checkout@v2
    - name: Build IPA
      run: |
        chmod +x build_ipa.sh
        ./build_ipa.sh --method development --team YOUR_TEAM_ID
```

## 注意事项

1. 首次运行脚本前，请在Xcode中手动构建项目至少一次，以确保所有依赖项已正确配置
2. 请根据实际项目结构修改脚本中的项目名称、Scheme名称等参数
3. 对于使用CocoaPods或Carthage的项目，确保已安装所有依赖
4. 脚本默认在项目根目录下创建`build`文件夹存放构建产物
5. 生成的IPA文件将位于`build/IPA`目录中

## 相关资源

- [Xcode命令行工具文档](https://developer.apple.com/library/archive/technotes/tn2339/_index.html)
- [Apple Developer Program](https://developer.apple.com/programs/)
- [App Store Connect](https://appstoreconnect.apple.com/)

按照本指南操作，您应该能够成功使用命令行工具构建和导出Aurora Music应用的IPA文件。如有任何问题，请参考上述常见问题解决方案或联系开发团队。