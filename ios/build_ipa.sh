#!/bin/bash

# Aurora Music应用IPA打包脚本
# 此脚本用于自动化构建和导出Aurora Music应用的IPA文件

# 颜色定义
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
NC="\033[0m" # 无颜色

# 配置变量
APP_NAME="Aurora Music"
SCHEME_NAME="AuroraMusic"
BUNDLE_ID="com.auroramusic.app"
TEAM_ID="SRQNM733R4" # 从描述文件中获取的团队ID

# 证书和描述文件配置
CERTIFICATE_PATH="$(pwd)/Gac企业证书.p12"
PROVISIONING_PROFILE_PATH="$(pwd)/描述文件.mobileprovision"

# 构建目录
BUILD_DIR="./build"
ARCHIVE_PATH="${BUILD_DIR}/${SCHEME_NAME}.xcarchive"
EXPORT_PATH="${BUILD_DIR}/IPA"

# 导出方法 (可选: app-store, ad-hoc, enterprise, development)
EXPORT_METHOD="enterprise" # 使用企业证书打包

# 检查项目类型 (workspace 或 project)
if [ -d "${SCHEME_NAME}.xcworkspace" ]; then
    PROJECT_TYPE="-workspace ${SCHEME_NAME}.xcworkspace"
else
    PROJECT_TYPE="-project ${SCHEME_NAME}.xcodeproj"
fi

# 创建构建目录
mkdir -p "${BUILD_DIR}"
mkdir -p "${EXPORT_PATH}"

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

# 创建导出选项plist文件
create_export_options_plist() {
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
    <key>compileBitcode</key>
    <false/>
    <key>signingStyle</key>
    <string>manual</string>
    <key>signingCertificate</key>
    <string>Apple Distribution</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>${BUNDLE_ID}</key>
        <string>gacmotorApp</string>
    </dict>
</dict>
</plist>
EOF

    log_info "导出选项plist文件已创建: ${BUILD_DIR}/exportOptions.plist"
}

# 主函数
main() {
    log_info "开始构建 ${APP_NAME} IPA 文件..."
    
    # 检查企业证书和描述文件是否存在
    if [ ! -f "${CERTIFICATE_PATH}" ]; then
        log_warning "企业证书文件不存在: ${CERTIFICATE_PATH}"
        log_info "将使用Xcode自动管理签名"
    else
        log_info "使用企业证书: ${CERTIFICATE_PATH}"
    fi
    
    if [ ! -f "${PROVISIONING_PROFILE_PATH}" ]; then
        log_warning "描述文件不存在: ${PROVISIONING_PROFILE_PATH}"
        log_info "将使用Xcode自动管理签名"
    else
        log_info "使用描述文件: ${PROVISIONING_PROFILE_PATH}"
    fi
    
    # 步骤1: 清理项目
    log_info "清理项目..."
    xcodebuild clean ${PROJECT_TYPE} -scheme "${SCHEME_NAME}" -configuration Release
    check_status "清理项目"
    
    # 步骤2: 构建归档
    log_info "构建归档文件..."
    xcodebuild archive ${PROJECT_TYPE} -scheme "${SCHEME_NAME}" -configuration Release -archivePath "${ARCHIVE_PATH}"
    check_status "构建归档"
    
    # 步骤3: 创建导出选项plist
    create_export_options_plist
    
    # 步骤4: 导出IPA
    log_info "导出IPA文件..."
    xcodebuild -exportArchive -archivePath "${ARCHIVE_PATH}" -exportOptionsPlist "${BUILD_DIR}/exportOptions.plist" -exportPath "${EXPORT_PATH}"
    check_status "导出IPA"
    
    # 查找生成的IPA文件
    IPA_FILE=$(find "${EXPORT_PATH}" -name "*.ipa" -type f | head -n 1)
    
    if [ -f "${IPA_FILE}" ]; then
        log_info "IPA文件已成功生成: ${IPA_FILE}"
    else
        log_error "未找到生成的IPA文件"
        exit 1
    fi
    
    log_info "构建完成!"
}

# 显示使用说明
show_usage() {
    echo "使用方法: $0 [选项]"
    echo "选项:"
    echo "  -h, --help          显示此帮助信息"
    echo "  -m, --method METHOD 设置导出方法 (app-store, ad-hoc, enterprise, development)"
    echo "  -t, --team TEAM_ID  设置开发团队ID"
    echo "  -s, --scheme NAME   设置Scheme名称"
    echo "  -b, --bundle BUNDLE 设置Bundle Identifier"
    echo "  -c, --cert PATH     设置企业证书路径"
    echo "  -p, --profile PATH  设置描述文件路径"
}

# 解析命令行参数
while [ "$1" != "" ]; do
    case $1 in
        -h | --help )
            show_usage
            exit 0
            ;;
        -m | --method )
            shift
            EXPORT_METHOD=$1
            ;;
        -t | --team )
            shift
            TEAM_ID=$1
            ;;
        -s | --scheme )
            shift
            SCHEME_NAME=$1
            ;;
        -b | --bundle )
            shift
            BUNDLE_ID=$1
            ;;
        -c | --cert )
            shift
            CERTIFICATE_PATH=$1
            ;;
        -p | --profile )
            shift
            PROVISIONING_PROFILE_PATH=$1
            ;;
        * )
            log_error "未知参数: $1"
            show_usage
            exit 1
            ;;
    esac
    shift
done

# 执行主函数
main