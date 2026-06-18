#!/bin/bash
set -e

APP_NAME="连接.app"
DMG_APP="$(cd "$(dirname "$0")" && pwd)/$APP_NAME"
TARGET="/Applications/$APP_NAME"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  正在安装「连接」App..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 第一步：复制到 Applications
echo "📦 第一步：安装到 Applications..."
if [ -d "$TARGET" ]; then
    rm -rf "$TARGET"
fi
cp -R "$DMG_APP" "$TARGET"
echo "  ✅ 已复制到 /Applications/"

# 第二步：移除隔离标记并启动
echo ""
echo "🚀 第二步：移除安全限制并启动..."
xattr -cr "$TARGET"
open "$TARGET" 2>/dev/null || "$TARGET/Contents/MacOS/连接" &

sleep 1
echo "  ✅ 已启动！"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  安装完成。以后直接双击「连接」图标即可。"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
