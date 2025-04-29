# Aurora Music 示例项目

这是一个用于验证IPA打包脚本的简单示例项目。该项目包含基本的SwiftUI应用结构，可用于测试`build_ipa.sh`脚本的功能。

## 项目结构

- `AuroraMusicApp.swift` - 应用入口文件
- `ContentView.swift` - 主界面视图
- `Info.plist` - 应用配置文件
- `build_ipa.sh` - IPA打包脚本

## 使用方法

### 准备工作

1. 确保已安装Xcode和命令行工具
2. 打开项目文件夹中的`AuroraMusic.xcodeproj`
3. 在Xcode中至少构建一次项目，确保所有依赖项已正确配置

### 使用打包脚本

1. 为脚本添加执行权限：
   ```bash
   chmod +x build_ipa.sh
   ```

2. 修改脚本中的`TEAM_ID`变量，替换为您的开发团队ID

3. 执行脚本：
   ```bash
   ./build_ipa.sh
   ```

4. 或者使用高级选项：
   ```bash
   ./build_ipa.sh --method development --team YOUR_TEAM_ID
   ```

### 验证结果

成功执行后，脚本将在`build/IPA`目录中生成IPA文件。您可以检查该文件是否正确生成，以验证打包流程是否有效。

## 注意事项

- 这是一个简化的示例项目，仅用于验证打包脚本的功能
- 在实际项目中，您需要根据项目结构调整脚本参数
- 请确保拥有有效的开发者证书和配置文件

## 相关资源

- 完整的打包指南请参考项目根目录中的`命令行打包IPA指南.md`文件
- 更多关于Xcode命令行工具的信息，请访问[Apple开发者文档](https://developer.apple.com/library/archive/technotes/tn2339/_index.html)