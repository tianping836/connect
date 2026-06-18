#!/bin/bash
# ============================================================
# CaseNetwork Xcode 项目初始化
# 运行此脚本以配置和打开项目
# ============================================================
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  CaseNetwork Xcode 项目初始化${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 1. 验证环境
echo -e "${YELLOW}1/5 检查环境...${NC}"
xcode_version=$(xcodebuild -version | head -1)
swift_version=$(swift --version | head -1)
echo -e "   Xcode: ${GREEN}$xcode_version${NC}"
echo -e "   Swift: ${GREEN}$swift_version${NC}"

# 2. 验证文件结构
echo ""
echo -e "${YELLOW}2/5 验证项目文件...${NC}"
swift_files=$(find "$PROJECT_DIR/CaseNetwork" -name "*.swift" | wc -l | tr -d ' ')
test_files=$(find "$PROJECT_DIR/Tests" -name "*.swift" | wc -l | tr -d ' ')
echo -e "   源文件: ${GREEN}$swift_files${NC} 个 .swift"
echo -e "   测试文件: ${GREEN}$test_files${NC} 个 .swift"

# 3. 运行测试
echo ""
echo -e "${YELLOW}3/5 运行单元测试...${NC}"
cd "$PROJECT_DIR"
if swift test 2>&1 | tail -5; then
    echo -e "${GREEN}   ✅ 全部测试通过${NC}"
else
    echo -e "${YELLOW}   ⚠️  测试未全部通过，请检查${NC}"
fi

# 4. 检查资源
echo ""
echo -e "${YELLOW}4/5 检查资源文件...${NC}"
if [ -d "$PROJECT_DIR/CaseNetwork/Resources/Assets.xcassets/AppIcon.appiconset" ]; then
    icon_count=$(ls "$PROJECT_DIR/CaseNetwork/Resources/Assets.xcassets/AppIcon.appiconset"/*.png 2>/dev/null | wc -l | tr -d ' ')
    echo -e "   App Icon: ${GREEN}$icon_count${NC} 个尺寸"
else
    echo -e "   ${YELLOW}⚠️  AppIcon 未配置${NC}"
fi

# 5. 打开 Xcode
echo ""
echo -e "${YELLOW}5/5 在 Xcode 中打开项目...${NC}"
open "$PROJECT_DIR/Package.swift"

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  ✅ 项目已在 Xcode 中打开${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}接下来在 Xcode 中手动完成：${NC}"
echo ""
echo "  1️⃣ 配置 Bundle Identifier:"
echo "     Xcode → CaseNetwork target → General →"
echo "     Bundle Identifier: com.zhouyijunlawyer.casenetwork"
echo ""
echo "  2️⃣ 配置 Team (代码签名):"
echo "     Signing & Capabilities → Team → 选择你的 Apple Developer 账号"
echo "     (需要 Apple Developer Program 会员 $99/年)"
echo ""
echo "  3️⃣ 添加 iCloud / CloudKit 能力:"
echo "     Signing & Capabilities → + Capability → iCloud"
echo "     → 勾选 CloudKit"
echo "     → Container: iCloud.com.zhouyijunlawyer.casenetwork"
echo ""
echo "  4️⃣ 添加 App Groups (CloudKit 同步需要):"
echo "     + Capability → App Groups"
echo "     → group.com.casenetwork.data"
echo ""
echo "  5️⃣ 验证 Info.plist 权限描述:"
echo "     Build Settings → 搜索 INFOPLIST_KEY"
echo "     → 确认 NSContactsUsageDescription 和 NSFaceIDUsageDescription 已填写"
echo ""
echo "  6️⃣ 选择方案并归档:"
echo "     Product → Scheme → CaseNetwork →"
echo "     Product → Destination → Any iOS Device"
echo "     Product → Archive"
echo ""
echo "  7️⃣ 上传 App Store Connect:"
echo "     Organizer → Archives → Distribute App → App Store Connect"
echo ""
echo "  或者使用命令行归档: ${GREEN}./build/archive.sh iOS${NC}"
echo ""
