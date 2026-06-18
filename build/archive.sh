#!/bin/bash
# ============================================================
# CaseNetwork Archive Script
# 用于归档 iOS / macOS 版本并上传 App Store Connect
# ============================================================
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
SCHEME="CaseNetwork"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

usage() {
    cat << EOF
用法: archive.sh [iOS|macOS|both]

  iOS    - 归档 iOS 版本 (iPhone + iPad)
  macOS  - 归档 macOS 版本
  both   - 同时归档两个平台

环境变量:
  APPLE_TEAM_ID     - Apple Developer Team ID (用于签名)

示例:
  APPLE_TEAM_ID=XXXXXXXXXX ./archive.sh iOS
EOF
    exit 1
}

PLATFORM="${1:-}"
if [ -z "$PLATFORM" ] || [ "$PLATFORM" != "iOS" ] && [ "$PLATFORM" != "macOS" ] && [ "$PLATFORM" != "both" ]; then
    usage
fi

TEAM_ID="${APPLE_TEAM_ID:-}"
BUNDLE_ID="com.zhouyijunlawyer.casenetwork"

# --- 前置检查 ---
check_prereqs() {
    echo -e "${YELLOW}🔍 检查前置条件...${NC}"
    
    if ! command -v xcodebuild &> /dev/null; then
        echo -e "${RED}❌ 未找到 xcodebuild。请安装 Xcode。${NC}"
        exit 1
    fi
    
    local xcode_ver=$(xcodebuild -version | head -1)
    echo -e "   Xcode: ${GREEN}$xcode_ver${NC}"
    
    if [ -n "$TEAM_ID" ]; then
        echo -e "   Team ID: ${GREEN}$TEAM_ID${NC}"
    else
        echo -e "   ${YELLOW}⚠️  未设置 APPLE_TEAM_ID — 将使用自动签名${NC}"
    fi
    
    # Check that source exists
    if [ ! -f "$PROJECT_DIR/Package.swift" ]; then
        echo -e "${RED}❌ 未找到 Package.swift。在项目根目录运行。${NC}"
        exit 1
    fi
}

# --- 归档 iOS ---
archive_ios() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  归档 iOS (iPhone + iPad)${NC}"
    echo -e "${GREEN}========================================${NC}"
    
    local ARCHIVE_PATH="$BUILD_DIR/CaseNetwork-iOS.xcarchive"
    
    # Clean
    swift package clean 2>/dev/null || true
    
    # Build settings
    local SETTINGS=(
        "CODE_SIGN_STYLE=Automatic"
        "SWIFT_OPTIMIZATION_LEVEL=-O"
        "SWIFT_COMPILATION_MODE=wholemodule"
    )
    if [ -n "$TEAM_ID" ]; then
        SETTINGS+=("DEVELOPMENT_TEAM=$TEAM_ID")
    fi
    
    echo "🔨 编译 iOS..."
    xcodebuild \
        -scheme "$SCHEME" \
        -destination 'generic/platform=iOS' \
        -configuration Release \
        -archivePath "$ARCHIVE_PATH" \
        "${SETTINGS[@]/#/-}" \
        archive 2>&1 | grep -E '(error:|warning:|Compiling|Linking|Build succeeded|BUILD SUCCEEDED|** ARCHIVE|FAILED)' || true
    
    if [ -d "$ARCHIVE_PATH" ]; then
        echo -e "${GREEN}✅ iOS 归档成功: $ARCHIVE_PATH${NC}"
    else
        echo -e "${RED}❌ iOS 归档失败。检查上方输出。${NC}"
        return 1
    fi
}

# --- 归档 macOS ---
archive_macos() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  归档 macOS${NC}"
    echo -e "${GREEN}========================================${NC}"
    
    local ARCHIVE_PATH="$BUILD_DIR/CaseNetwork-macOS.xcarchive"
    
    # Clean
    swift package clean 2>/dev/null || true
    
    local SETTINGS=(
        "CODE_SIGN_STYLE=Automatic"
        "SWIFT_OPTIMIZATION_LEVEL=-O"
        "SWIFT_COMPILATION_MODE=wholemodule"
    )
    if [ -n "$TEAM_ID" ]; then
        SETTINGS+=("DEVELOPMENT_TEAM=$TEAM_ID")
    fi
    
    echo "🔨 编译 macOS..."
    xcodebuild \
        -scheme "$SCHEME" \
        -destination 'generic/platform=macOS' \
        -configuration Release \
        -archivePath "$ARCHIVE_PATH" \
        "${SETTINGS[@]/#/-}" \
        archive 2>&1 | grep -E '(error:|warning:|Compiling|Linking|Build succeeded|BUILD SUCCEEDED|** ARCHIVE|FAILED)' || true
    
    if [ -d "$ARCHIVE_PATH" ]; then
        echo -e "${GREEN}✅ macOS 归档成功: $ARCHIVE_PATH${NC}"
    else
        echo -e "${RED}❌ macOS 归档失败。检查上方输出。${NC}"
        return 1
    fi
}

# --- 主流程 ---
check_prereqs

case "$PLATFORM" in
    iOS)
        archive_ios
        ;;
    macOS)
        archive_macos
        ;;
    both)
        archive_ios
        archive_macos
        ;;
esac

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  归档完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "下一步："
echo "  1. 打开 Xcode → Organizer → Archives"
echo "  2. 选择最新 Archive → Distribute App"
echo "  3. 选择 App Store Connect → Upload"
echo "  4. 在 App Store Connect 中完成上架"
echo ""
echo "或使用命令行上传（需配置 notarytool）："
echo "  xcrun notarytool submit <archive> --apple-id <your-id> --team-id <team> --wait"
