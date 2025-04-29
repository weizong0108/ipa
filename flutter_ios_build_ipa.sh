#!/bin/bash

# Flutter-iOS应用快速打包IPA脚本
# 此脚本用于自动化构建Flutter应用并导出iOS的IPA文件

# 颜色定义
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
NC="\033[0m" # 无颜色

# 默认配置变量
APP_NAME="Flutter应用"
SCHEME_NAME="Runner"
EXPORT_METHOD="development" # 可选: app-store, ad-hoc, enterprise, development
TEAM_ID="" # 开发团队ID
FLUTTER_BUILD_MODE="release" # 可选: debug, profile, release

# 构建目录
BUILD_DIR="./build"
ARCHIVE_PATH="${BUILD_DIR}/${SCHEME_NAME}.xcarchive"
EXPORT_PATH="${BUILD_DIR}/IPA"

# 帮助信息
show_help() {
    echo -e "${BLUE}Flutter-iOS应用快速打包IPA脚本${NC}"
    echo -e "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --help                显示此帮助信息"
    echo "  --team ID             设置开发团队ID"
    echo "  --method 方法         设置导出方法 (app-store, ad-hoc, enterprise, development)"
    echo "  --scheme 名称         设置Scheme名称 (默认: Runner)"
    echo "  --name 名称           设置应用名称"
    echo "  --flutter-mode 模式   设置Flutter构建模式 (debug, profile, release)"
    echo "  --clean               执行前清理Flutter项目"
    echo ""
    echo "示例:"
    echo "  $0 --team ABCD1234 --method development --clean"
    exit 0
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --help)
            show_help
            ;;
        --team)
            TEAM_ID="$2"
            shift 2
            ;;
        --method)
            EXPORT_METHOD="$2"
            shift 2
            ;;
        --scheme)
            SCHEME_NAME="$2"
            shift 2
            ;;
        --name)
            APP_NAME="$2"
            shift 2
            ;;
        --flutter-mode)
            FLUTTER_BUILD_MODE="$2"
            shift 2
            ;;
        --clean)
            DO_CLEAN=true
            shift
            ;;
        *)
            echo -e "${RED}未知选项: $1${NC}"
            show_help
            ;;
    esac
done

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查命令执行状态
check_status() {
    if [ $? -ne 0 ]; then
        log_error "$1 失败"
        exit 1
    else
        log_info "$1 成功"
    fi
}

# 检查Flutter环境
check_flutter() {
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter未安装或未添加到PATH中"
        echo "请安装Flutter并确保'flutter'命令可用"
        exit 1
    fi
    
    log_info "Flutter环境检查通过"
    flutter --version
}

# 检查项目结构
check_project() {
    # 检查是否为Flutter项目
    if [ ! -f "pubspec.yaml" ]; then
        log_error "当前目录不是Flutter项目根目录"
        echo "请在Flutter项目根目录运行此脚本"
        exit 1
    fi
    
    # 检查iOS目录
    if [ ! -d "ios" ]; then
        log_error "未找到iOS项目目录"
        echo "请确保Flutter项目包含iOS目录"
        exit 1
    fi
    
    log_info "项目结构检查通过"
}

# 创建导出选项plist文件
create_export_options_plist() {
    mkdir -p "${BUILD_DIR}"
    
    cat > "${BUILD_DIR}/exportOptions.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>${EXPORT_METHOD}</string>
    <key>teamID</key>
    <string>${TEAM_ID}</string>
    <key>uploadSymbols</key>
    <true/>
    <key>uploadBitcode</key>
    <false/>
</dict>
</plist>
EOF

    log_info "导出选项plist文件已创建: ${BUILD_DIR}/exportOptions.plist"
}

# 主函数
main() {
    log_info "开始构建 ${APP_NAME} Flutter-iOS IPA 文件..."
    
    # 检查环境和项目
    check_flutter
    check_project
    
    # 创建构建目录
    mkdir -p "${BUILD_DIR}"
    mkdir -p "${EXPORT_PATH}"
    
    # 步骤1: 清理项目(如果需要)
    if [ "$DO_CLEAN" = true ]; then
        log_info "清理Flutter项目..."
        flutter clean
        check_status "清理Flutter项目"
    fi
    
    # 步骤2: 构建Flutter应用
    log_info "构建Flutter应用(iOS)..."
    flutter build ios --${FLUTTER_BUILD_MODE} --no-codesign
    check_status "构建Flutter应用"
    
    # 步骤3: 进入iOS目录
    cd ios
    
    # 步骤4: 清理Xcode项目
    log_info "清理Xcode项目..."
    xcodebuild clean -workspace Runner.xcworkspace -scheme "${SCHEME_NAME}" -configuration Release
    check_status "清理Xcode项目"
    
    # 步骤5: 创建导出选项plist
    create_export_options_plist
    
    # 步骤6: 构建归档
    log_info "构建归档文件..."
    xcodebuild archive -workspace Runner.xcworkspace -scheme "${SCHEME_NAME}" -configuration Release -archivePath "${ARCHIVE_PATH}"
    check_status "构建归档"
    
    # 步骤7: 导出IPA
    log_info "导出IPA文件..."
    xcodebuild -exportArchive -archivePath "${ARCHIVE_PATH}" -exportOptionsPlist "${BUILD_DIR}/exportOptions.plist" -exportPath "${EXPORT_PATH}"
    check_status "导出IPA"
    
    # 返回项目根目录
    cd ..
    
    # 完成
    IPA_FILE=$(find "${EXPORT_PATH}" -name "*.ipa" | head -n 1)
    if [ -f "$IPA_FILE" ]; then
        log_info "IPA文件已成功创建: ${IPA_FILE}"
        echo -e "${GREEN}===============================================${NC}"
        echo -e "${GREEN}构建成功!${NC}"
        echo -e "${GREEN}IPA文件路径: ${IPA_FILE}${NC}"
        echo -e "${GREEN}===============================================${NC}"
    else
        log_error "未找到生成的IPA文件"
        exit 1
    fi
}

# 执行主函数
main