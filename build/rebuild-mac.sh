#!/bin/bash
# ============================================================
# CaseNetwork macOS 一键重新编译 + 安装
# 用法: ./build/rebuild-mac.sh
# ============================================================
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
DERIVED_DATA="$BUILD_DIR/DerivedData"
APP_NAME="CaseNetwork"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🔨 编译 $APP_NAME (macOS)...${NC}"

cd "$PROJECT_DIR"

# 1. Build
xcodebuild \
  -scheme "$APP_NAME" \
  -destination 'platform=macOS' \
  -configuration Debug \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  DEVELOPMENT_TEAM="" \
  -derivedDataPath "$DERIVED_DATA" \
  build 2>&1 | grep -E '(error:|warning:|BUILD|**)' || true

if [ ! -f "$DERIVED_DATA/Build/Products/Debug/$APP_NAME" ]; then
    echo -e "${YELLOW}❌ 编译失败${NC}"
    exit 1
fi

echo -e "${GREEN}✅ 编译成功${NC}"

# 2. Kill running instance
pkill -f "$APP_NAME.app/Contents/MacOS/$APP_NAME" 2>/dev/null || true
sleep 1

# 3. Build .app bundle
echo -e "${YELLOW}📦 组装 App Bundle...${NC}"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

# Binary
cp "$DERIVED_DATA/Build/Products/Debug/$APP_NAME" "$APP_DIR/Contents/MacOS/$APP_NAME"
chmod +x "$APP_DIR/Contents/MacOS/$APP_NAME"

# Resources
rm -rf "$APP_DIR/Contents/Resources/$APP_NAME""_$APP_NAME.bundle"
cp -R "$DERIVED_DATA/Build/Products/Debug/$APP_NAME""_$APP_NAME.bundle" "$APP_DIR/Contents/Resources/"

# App Icon
if [ -f "$APP_DIR/Contents/Resources/AppIcon.icns" ]; then
    echo "  Icon already present"
else
    echo "  Generating icon..."
    ICONSET_DIR="$BUILD_DIR/AppIcon.iconset"
    mkdir -p "$ICONSET_DIR"
    SRC="$PROJECT_DIR/CaseNetwork/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"
    for size in 16 32 128 256 512; do
        half=$((size / 2))
        sips -z $half $half "$SRC" --out "$ICONSET_DIR/icon_${half}x${half}.png" 2>/dev/null
        sips -z $size $size "$SRC" --out "$ICONSET_DIR/icon_${half}x${half}@2x.png" 2>/dev/null
    done
    sips -z 1024 1024 "$SRC" --out "$ICONSET_DIR/icon_512x512@2x.png" 2>/dev/null
    iconutil -c icns "$ICONSET_DIR" -o "$APP_DIR/Contents/Resources/AppIcon.icns" 2>&1
fi

# Info.plist
cat > "$APP_DIR/Contents/Info.plist" << 'PLISTEOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key><string>zh_CN</string>
    <key>CFBundleDisplayName</key><string>连接</string>
    <key>CFBundleExecutable</key><string>连接</string>
    <key>CFBundleIdentifier</key><string>com.zhouyijunlawyer.casenetwork</string>
    <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
    <key>CFBundleName</key><string>连接</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundleIconName</key><string>AppIcon</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>ITSAppUsesNonExemptEncryption</key><false/>
</dict>
</plist>
PLISTEOF

echo -e "${GREEN}✅ App Bundle 已组装${NC}"

# 4. Install to /Applications
echo -e "${YELLOW}📀 安装到 /Applications...${NC}"
rm -rf /Applications/$APP_NAME.app
cp -Rf "$APP_DIR" /Applications/
echo -e "${GREEN}✅ 已安装到 /Applications/$APP_NAME.app${NC}"

# 5. Launch
echo -e "${YELLOW}🚀 启动应用...${NC}"
open /Applications/$APP_NAME.app

sleep 2
if pgrep -f "$APP_NAME.app/Contents/MacOS/$APP_NAME" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ $APP_NAME 已启动运行！${NC}"
else
    echo -e "${YELLOW}⚠️  应用可能未成功启动，检查控制台日志${NC}"
fi
