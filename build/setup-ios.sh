#!/bin/bash
# ============================================================
# CaseNetwork iOS 设备安装 —— 配置向导
# ============================================================
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

clear
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  CaseNetwork iOS 设备安装配置${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Step 0: Check environment
echo -e "${YELLOW}检查当前状态...${NC}"

HAS_ACCOUNT=$(defaults read com.apple.dt.Xcode DVTDeveloperAccountCredentials 2>/dev/null | grep -c 'appleID' || echo "0")
HAS_IOS=$(ls /Applications/Xcode.app/Contents/Developer/Platforms/ 2>/dev/null | grep -c iPhoneOS || echo "0")

echo ""
echo -e "  Apple ID 登录: $([ "$HAS_ACCOUNT" -gt 0 ] && echo "${GREEN}✅ 已登录${NC}" || echo '❌ 未登录')"
echo -e "  iOS 平台: $([ "$HAS_IOS" -gt 0 ] && echo "${GREEN}✅ 已下载${NC}" || echo '❌ 未下载')"
echo ""

# Step 1: Apple ID
if [ "$HAS_ACCOUNT" -eq 0 ]; then
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}  第 1 步: 登录 Apple ID${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  免费 Apple ID 即可！不需要 $99 开发者会员。"
    echo ""
    echo "  操作："
    echo "    1. 打开 Xcode"
    echo "    2. 菜单栏 → Xcode → Settings (⌘,)"
    echo "    3. Accounts 标签 → 点 + → Apple ID"
    echo "    4. 输入你的 Apple ID 和密码"
    echo "    5. 登录后关闭 Settings"
    echo ""
    echo "  (如果已登录请忽略)"
    echo ""
fi

# Step 2: iOS Platform
if [ "$HAS_IOS" -eq 0 ]; then
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}  第 2 步: 下载 iOS 26.5 平台${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  操作："
    echo "    1. Xcode → Settings (⌘,) → Platforms"
    echo "    2. 找到 iOS 26.5 → 点击下载 (约 7GB)"
    echo "    3. 等待下载完成"
    echo ""
    echo "  (可后台下载，先继续下一步)"
    echo ""
fi

# Step 3: Open project
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}  第 3 步: 连接设备并运行${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  你的设备："
echo "    📱 不点 (iPhone 15 Pro)"
echo "    📱 周义军律师的iPhone (iPhone 13)"
echo "    📱 周义军的 iPad mini"
echo ""
echo "  操作："
echo "    1. 用 USB 线连接 iPhone/iPad 到 Mac"
echo "    2. 设备上点「信任此电脑」并输入锁屏密码"
echo "    3. 回到终端，运行: open Package.swift"
echo "    4. Xcode 顶部选择你的设备 (不是 Simulator)"
echo "    5. Signing & Capabilities → Team → 选择你的 Apple ID"
echo "    6. 按 ⌘R 运行 → App 就装到设备上了！"
echo ""

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
echo -e "${BLUE}现在打开 Xcode？${NC}"
read -p "输入 y 打开 Xcode，其他键跳过: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    open "$PROJECT_DIR/Package.swift"
    echo -e "${GREEN}✅ Xcode 已打开${NC}"
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  备忘${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  ⚠️  免费 Apple ID 限制："
echo "     - 最多 3 台设备"
echo "     - App 每 7 天需重新安装 (插线按 ⌘R 即可)"
echo "     - 不影响 Mac 版 (Mac 版无需签名)"
echo ""
echo "  💡 如果后续想上架 App Store 或去掉 7 天限制："
echo "     - 加入 Apple Developer Program ($99/年)"
echo "     - 在 Xcode 中配置相同的 Team"
echo ""
echo "  🔄 更新代码后重新安装 iOS 版："
echo "     - 插线 → Xcode 中按 ⌘R"
echo ""
echo "  🔄 更新代码后重新安装 Mac 版："
echo "     - ./build/rebuild-mac.sh"
echo ""
