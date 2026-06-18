#!/bin/bash
# ============================================================
# 「连接」全平台一键更新
# 用法: ./build/rebuild-all.sh
# ============================================================
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

cd "$PROJECT_DIR"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  连接 App — 全平台更新${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# ── 0. 同步源码到 Xcode 项目 ──
echo -e "${YELLOW}📋 同步源码到 Xcode 项目...${NC}"
if [ -d "连接/连接" ]; then
    rsync -a --include='*/' --include='*.swift' --exclude='*' \
        CaseNetwork/ 连接/连接/ 2>/dev/null
    rsync -a CaseNetwork/Resources/Assets.xcassets/ \
        连接/连接/Assets.xcassets/ 2>/dev/null
    echo "  ✅ 源码已同步"
else
    echo "  ⚠️ Xcode 项目 (连接/连接/) 不存在，跳过"
fi

# ── 1. Mac ──
echo ""
echo -e "${YELLOW}🖥  编译 Mac 版...${NC}"
swift build 2>&1 | tail -1

if [ -f ".build/arm64-apple-macosx/debug/CaseNetwork" ]; then
    pkill -f "连接" 2>/dev/null || true
    sleep 1
    cp .build/arm64-apple-macosx/debug/CaseNetwork /Applications/连接.app/Contents/MacOS/连接
    chmod +x /Applications/连接.app/Contents/MacOS/连接
    xattr -cr /Applications/连接.app 2>/dev/null || true
    open /Applications/连接.app
    echo -e "  ${GREEN}✅ Mac 已更新并启动${NC}"
else
    echo -e "  ❌ Mac 编译失败"
fi

# ── 2. iOS 设备 ──
echo ""
echo -e "${YELLOW}📱 编译 iOS 版...${NC}"

if [ ! -d "连接/连接.xcodeproj" ]; then
    echo "  ⚠️ Xcode 项目不存在，跳过 iOS"
    exit 0
fi

cd 连接
xcodebuild \
    -project 连接.xcodeproj \
    -scheme 连接 \
    -destination 'generic/platform=iOS' \
    -configuration Debug \
    -allowProvisioningUpdates \
    -quiet \
    build 2>&1 | tail -1

APP="$HOME/Library/Developer/Xcode/DerivedData/连接-hbsthgjnuvakxqffgyabpacpzbci/Build/Products/Debug-iphoneos/连接.app"

if [ ! -f "$APP/连接" ]; then
    echo -e "  ❌ iOS 编译失败"
    cd "$PROJECT_DIR"
    exit 1
fi

echo -e "  ${GREEN}✅ iOS 编译成功${NC}"

# 安装到所有已连接设备
echo ""
echo -e "${YELLOW}📲 安装到设备...${NC}"

# Get connected iOS device UDIDs
DEVICE_IDS=$(xcrun xctrace list devices 2>/dev/null | grep -E 'iPhone|iPad' | grep -v 'Simulator' | grep -oE '\([0-9A-F]{24,40}\)' | tr -d '()' || true)

if [ -z "$DEVICES" ]; then
    echo "  ⚠️ 未检测到已连接的 iOS 设备"
else
    echo "$DEVICE_IDS" | while read -r UDID; do
        [ -z "$UDID" ] && continue
        echo "  安装到 $UDID..."
        xcrun devicectl device install app --device "$UDID" "$APP" 2>&1 | grep -E 'installed|error' && echo -e "    ${GREEN}✅${NC}" || echo -e "    ${YELLOW}⚠️ 失败${NC}"
    done
fi

cd "$PROJECT_DIR"
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  更新完成${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "  Mac:     /Applications/连接.app"
echo "  DMG:     ./build/make-dmg.sh"
echo "  iOS手动: Xcode 打开 连接/连接.xcodeproj → ⌘R"
