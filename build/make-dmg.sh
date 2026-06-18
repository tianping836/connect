#!/bin/bash
# ============================================================
# 制作「连接」App DMG 安装包
# 用法: ./build/make-dmg.sh
# ============================================================
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"

# 1. Rebuild the Mac app
echo "🔨 编译..."
"$BUILD_DIR/rebuild-mac.sh" 2>&1 | tail -5

# 2. Create DMG
echo ""
echo "📦 制作 DMG..."
rm -rf "$BUILD_DIR/dmg-content"
mkdir -p "$BUILD_DIR/dmg-content"
cp -R /Applications/连接.app "$BUILD_DIR/dmg-content/连接.app"
ln -s /Applications "$BUILD_DIR/dmg-content/Applications"

DMG="$BUILD_DIR/连接-CaseNetwork-$(date +%Y%m%d).dmg"
rm -f "$DMG"
hdiutil create -volname "连接" -srcfolder "$BUILD_DIR/dmg-content" -ov -format UDZO "$DMG" 2>&1 | tail -1

echo ""
echo "✅ DMG: $DMG"
echo "   大小: $(du -sh "$DMG" | cut -f1)"
echo ""
echo "发送给其他 Mac 用户:"
echo "   AirDrop / U盘 / 微信 都可以"
echo ""
echo "对方安装后首次打开: 右键 App → 打开"
