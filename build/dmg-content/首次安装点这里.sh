#!/bin/bash
APP="$(dirname "$0")/连接.app"
xattr -cr "$APP" 2>/dev/null
open "$APP" 2>/dev/null || "$APP/Contents/MacOS/连接" &
echo "✅ 连接App 已启动！"
