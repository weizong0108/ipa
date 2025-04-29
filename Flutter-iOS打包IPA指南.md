# Flutter-iOS快速打包IPA指南

本文档提供了使用`flutter_ios_build_ipa.sh`脚本快速打包Flutter iOS应用为IPA文件的详细指南。

## 前期准备

### 环境要求

在开始打包前，请确保您的开发环境满足以下要求：

1. **Flutter SDK**：已安装并配置好Flutter SDK
   ```bash
   # 检查Flutter安装
   flutter --version
   ```

2. **Xcode**：已安装最新版本的Xcode
   ```bash
   # 检查Xcode版本
   xcodebuild -version
   ```

3. **Apple开发者账号**：拥有有效的Apple开发者账号
   - 确保已在Xcode中登录您的Apple ID
   - 获取您的开发团队ID (Team ID)

4. **证书和配置文件**：
   - 已创建并安装开发证书
   - 已创建并下载相应的配置文件
   - 已在Xcode中配置好签名设置

### 项目配置检查

在打包前，请确保您的Flutter项目配置正确：

1. **iOS部分配置**：
   - 检查`ios/Runner/Info.plist`中的Bundle Identifier
   - 确保版本号和构建号已更新
   - 检查应用图标和启动屏是否已设置

2. **Flutter配置**：
   - 确保`pubspec.yaml`中的应用信息正确
   - 所有依赖项已更新到最新版本
   - 没有未解决的依赖冲突

## 使用打包脚本

### 基本用法

1. 首先，确保脚本有执行权限：
   ```bash
   chmod +x flutter_ios_build_ipa.sh
   ```

2. 在Flutter项目根目录下运行脚本：
   ```bash
   ./flutter_ios_build_ipa.sh --team YOUR_TEAM_ID
   ```

### 脚本参数说明

脚本支持以下命令行参数：

| 参数 | 说明 | 示例 |
|------|------|------|
| `--help` | 显示帮助信息 | `--help` |
| `--team` | 设置开发团队ID | `--team ABCD1234` |
| `--method` | 设置导出方法 | `--method development` |
| `--scheme` | 设置Scheme名称 | `--scheme Runner` |
| `--name` | 设置应用名称 | `--name "我的应用"` |
| `--flutter-mode` | 设置Flutter构建模式 | `--flutter-mode release` |
| `--clean` | 执行前清理Flutter项目 | `--clean` |

### 导出方法说明

脚本支持以下导出方法：

- `development`: 用于开发和测试，可在已注册的设备上安装
- `ad-hoc`: 用于内部测试，可在已注册的设备上安装
- `enterprise`: 用于企业内部分发，可在企业内任何设备上安装
- `app-store`: 用于提交到App Store审核

### 示例命令

```bash
# 使用开发模式打包
./flutter_ios_build_ipa.sh --team ABCD1234 --method development --clean

# 打包用于App Store提交
./flutter_ios_build_ipa.sh --team ABCD1234 --method app-store --flutter-mode release

# 使用自定义Scheme名称
./flutter_ios_build_ipa.sh --team ABCD1234 --scheme MyCustomScheme --method ad-hoc
```

## 打包流程说明

脚本执行以下步骤来完成打包：

1. **环境检查**：验证Flutter环境和项目结构
2. **清理项目**：如果指定了`--clean`参数，清理Flutter项目
3. **构建Flutter应用**：使用指定的构建模式构建iOS应用
4. **清理Xcode项目**：清理iOS目录中的Xcode项目
5. **创建导出选项**：生成exportOptions.plist文件
6. **构建归档**：创建应用的xcarchive文件
7. **导出IPA**：从归档文件中导出IPA安装包

## 常见问题解决

### 1. 构建失败：Flutter相关错误

**问题**：Flutter构建阶段失败

**解决方法**：
- 运行`flutter doctor`检查环境问题
- 确保所有依赖项都已正确安装：`flutter pub get`
- 尝试清理项目后重新构建：`flutter clean`

### 2. 构建失败：Xcode相关错误

**问题**：Xcode构建或归档阶段失败

**解决方法**：
- 确保Xcode命令行工具已安装：`xcode-select --install`
- 检查证书和配置文件是否有效
- 在Xcode中手动构建项目，查看详细错误信息

### 3. 证书或配置文件问题

**问题**：出现签名相关错误

**解决方法**：
- 在Xcode中刷新证书和配置文件
- 检查Apple Developer账户状态
- 确保Team ID正确
- 确保配置文件包含目标设备的UDID（对于开发和Ad-hoc分发）

### 4. 导出IPA失败

**问题**：归档成功但导出IPA失败

**解决方法**：
- 检查导出方法是否与配置文件匹配
- 验证exportOptions.plist文件内容是否正确
- 检查是否有足够的磁盘空间

## 安装和测试

### 使用TestFlight分发（推荐）

1. 使用`app-store`方法导出IPA
2. 登录[App Store Connect](https://appstoreconnect.apple.com/)
3. 上传IPA文件（可使用Transporter工具）
4. 在TestFlight中添加测试人员
5. 等待Apple审核（通常几小时内完成）
6. 测试人员通过TestFlight应用安装和测试

### 使用Ad-hoc分发

1. 使用`ad-hoc`方法导出IPA
2. 通过以下方式分发IPA文件：
   - 电子邮件
   - 内部网站
   - 第三方分发平台（如Diawi、TestFlight等）
3. 在iOS设备上安装（需要设备UDID已添加到配置文件中）

## 自动化集成

可以将此脚本集成到CI/CD流程中，例如：

- **GitHub Actions**：在工作流文件中调用脚本
- **Jenkins**：创建构建任务执行脚本
- **Fastlane**：在Fastfile中调用脚本

## 注意事项

- 确保在使用脚本前已完成所有必要的配置
- 定期更新证书和配置文件，避免过期导致构建失败
- 对于App Store提交，确保应用符合Apple的审核指南
- 保持Flutter和Xcode更新到最新版本，以获得最佳兼容性