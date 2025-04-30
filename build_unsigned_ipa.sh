#!/bin/bash

# 设置错误时退出
set -e

# 显示当前步骤
show_progress() {
    echo "====================================="
    echo "$1"
    echo "====================================="
}

# 检查 Flutter 环境
show_progress "检查 Flutter 环境..."
if ! command -v flutter &> /dev/null; then
    echo "错误: Flutter 未安装"
    exit 1
fi

# 清理旧的构建文件
show_progress "清理旧的构建文件..."
flutter clean

# 获取依赖
show_progress "获取 Flutter 依赖..."
flutter pub get

# 更新构建号
BUILD_NUMBER=$(date +%Y%m%d%H%M)
show_progress "设置构建号为: $BUILD_NUMBER"

# 构建 iOS Release 包
show_progress "开始构建 iOS Release 包..."
flutter build ios --release --no-codesign

# 检查构建是否成功
if [ ! -d "build/ios/iphoneos/Runner.app" ]; then
    echo "错误: iOS 构建失败"
    exit 1
fi

# 创建输出目录
show_progress "创建输出目录..."
OUTPUT_DIR="build/ios/ipa"
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/Payload"

# 复制 .app 文件到 Payload 目录
show_progress "复制 .app 文件到 Payload 目录..."
cp -r "build/ios/iphoneos/Runner.app" "$OUTPUT_DIR/Payload/"

# 进入输出目录
cd "$OUTPUT_DIR"

# 创建 IPA 文件
show_progress "打包 IPA 文件..."
zip -qr "GAC_Music_$BUILD_NUMBER.ipa" Payload

# 清理临时文件
show_progress "清理临时文件..."
rm -rf Payload

# 完成
show_progress "构建完成!"
echo "未签名的 IPA 文件已生成: $OUTPUT_DIR/GAC_Music_$BUILD_NUMBER.ipa" 