#!/bin/bash

# Flutter项目结构检查脚本
# 此脚本用于检查Flutter项目结构是否符合iOS打包要求

# 颜色定义
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
NC="\033[0m" # 无颜色

# 日志函数
log_info() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_title() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

# 检查Flutter环境
check_flutter() {
    log_title "检查Flutter环境"
    
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter未安装或未添加到PATH中"
        echo "请安装Flutter并确保'flutter'命令可用"
        return 1
    else
        flutter_version=$(flutter --version | head -n 1)
        log_info "Flutter已安装: $flutter_version"
    fi
    
    # 检查Flutter doctor
    flutter_issues=$(flutter doctor | grep -i "[!✗]" | wc -l)
    if [ "$flutter_issues" -gt 0 ]; then
        log_warning "Flutter环境存在潜在问题，请运行'flutter doctor'查看详情"
    else
        log_info "Flutter环境检查通过"
    fi
    
    return 0
}

# 检查Xcode环境
check_xcode() {
    log_title "检查Xcode环境"
    
    if ! command -v xcodebuild &> /dev/null; then
        log_error "Xcode未安装或未添加到PATH中"
        echo "请安装Xcode并确保'xcodebuild'命令可用"
        return 1
    else
        xcode_version=$(xcodebuild -version | head -n 1)
        log_info "Xcode已安装: $xcode_version"
    fi
    
    # 检查Xcode命令行工具
    if ! xcode-select -p &> /dev/null; then
        log_warning "Xcode命令行工具可能未安装，请运行'xcode-select --install'"
    else
        log_info "Xcode命令行工具已安装"
    fi
    
    return 0
}

# 检查项目结构
check_project_structure() {
    log_title "检查项目结构"
    
    # 检查是否为Flutter项目
    if [ ! -f "pubspec.yaml" ]; then
        log_error "当前目录不是Flutter项目根目录 (未找到pubspec.yaml)"
        echo "请在Flutter项目根目录运行此脚本"
        return 1
    else
        log_info "找到Flutter项目配置文件 (pubspec.yaml)"
        
        # 检查项目名称
        project_name=$(grep "name:" pubspec.yaml | head -n 1 | cut -d ":" -f 2 | tr -d " \t")
        log_info "项目名称: $project_name"
    fi
    
    # 检查iOS目录
    if [ ! -d "ios" ]; then
        log_error "未找到iOS项目目录"
        echo "请确保Flutter项目包含iOS目录"
        return 1
    else
        log_info "找到iOS项目目录"
        
        # 检查iOS项目结构
        if [ ! -d "ios/Runner" ]; then
            log_warning "iOS项目结构异常 (未找到Runner目录)"
        else
            log_info "iOS项目结构正常"
        fi
        
        # 检查Xcode工作空间
        if [ ! -d "ios/Runner.xcworkspace" ]; then
            if [ ! -d "ios/*.xcworkspace" ]; then
                log_warning "未找到Xcode工作空间 (.xcworkspace)"
            fi
        else
            log_info "找到Xcode工作空间"
        fi
        
        # 检查Info.plist
        if [ ! -f "ios/Runner/Info.plist" ]; then
            log_warning "未找到Info.plist文件"
        else
            log_info "找到Info.plist文件"
            
            # 检查Bundle ID
            if command -v plutil &> /dev/null && command -v grep &> /dev/null; then
                bundle_id=$(plutil -p "ios/Runner/Info.plist" | grep CFBundleIdentifier | cut -d '"' -f 4)
                if [ -n "$bundle_id" ]; then
                    log_info "Bundle ID: $bundle_id"
                fi
            fi
        fi
    fi
    
    return 0
}

# 检查签名配置
check_signing() {
    log_title "检查签名配置"
    
    # 检查项目配置文件
    if [ -f "ios/Runner.xcodeproj/project.pbxproj" ]; then
        # 检查是否配置了自动签名
        auto_signing=$(grep -c "CODE_SIGN_STYLE = Automatic" "ios/Runner.xcodeproj/project.pbxproj")
        if [ "$auto_signing" -gt 0 ]; then
            log_info "项目配置为自动签名"
        else
            log_warning "项目可能配置为手动签名，请确保已配置正确的证书和配置文件"
        fi
        
        # 检查Team ID
        team_id=$(grep -o "DEVELOPMENT_TEAM = [A-Z0-9]*" "ios/Runner.xcodeproj/project.pbxproj" | head -n 1 | cut -d " " -f 3)
        if [ -n "$team_id" ]; then
            log_info "开发团队ID: $team_id"
        else
            log_warning "未找到开发团队ID，请在Xcode中配置或使用打包脚本时指定--team参数"
        fi
    else
        log_warning "未找到Xcode项目配置文件"
    fi
}

# 检查CocoaPods
check_cocoapods() {
    log_title "检查CocoaPods"
    
    if ! command -v pod &> /dev/null; then
        log_warning "CocoaPods未安装，可能影响依赖管理"
        echo "建议安装CocoaPods: sudo gem install cocoapods"
    else
        pod_version=$(pod --version)
        log_info "CocoaPods已安装: v$pod_version"
        
        # 检查Podfile
        if [ -f "ios/Podfile" ]; then
            log_info "找到Podfile"
            
            # 检查是否已执行pod install
            if [ -f "ios/Podfile.lock" ] && [ -d "ios/Pods" ]; then
                log_info "CocoaPods依赖已安装"
            else
                log_warning "CocoaPods依赖可能未安装，请在ios目录中运行'pod install'"
            fi
        else
            log_warning "未找到Podfile，可能影响iOS依赖管理"
        fi
    fi
}

# 检查打包脚本
check_build_script() {
    log_title "检查打包脚本"
    
    script_path="./flutter_ios_build_ipa.sh"
    if [ -f "$script_path" ]; then
        log_info "找到Flutter-iOS打包脚本"
        
        # 检查脚本权限
        if [ -x "$script_path" ]; then
            log_info "打包脚本具有执行权限"
        else
            log_warning "打包脚本没有执行权限，请运行: chmod +x $script_path"
        fi
    else
        log_warning "未找到Flutter-iOS打包脚本，请确保脚本位于项目根目录"
    fi
}

# 主函数
main() {
    echo -e "${BLUE}Flutter-iOS项目结构检查工具${NC}"
    echo -e "${BLUE}=============================${NC}"
    
    # 运行各项检查
    check_flutter
    flutter_status=$?
    
    check_xcode
    xcode_status=$?
    
    check_project_structure
    project_status=$?
    
    check_signing
    check_cocoapods
    check_build_script
    
    # 总结
    echo -e "\n${BLUE}=== 检查结果摘要 ===${NC}"
    if [ $flutter_status -eq 0 ] && [ $xcode_status -eq 0 ] && [ $project_status -eq 0 ]; then
        echo -e "${GREEN}项目基本结构检查通过，可以尝试使用打包脚本构建IPA文件。${NC}"
        echo -e "运行命令: ./flutter_ios_build_ipa.sh --team YOUR_TEAM_ID"
    else
        echo -e "${RED}项目检查发现问题，请解决上述问题后再尝试打包。${NC}"
    fi
}

# 执行主函数
main