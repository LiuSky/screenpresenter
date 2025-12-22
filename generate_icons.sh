#!/bin/bash
# 
# App Icon 生成脚本
# 将 SVG 转换为 macOS App Icon 所需的各种尺寸
#
# 使用方法：
# 1. 安装依赖: brew install librsvg
# 2. 运行脚本: ./generate_icons.sh
#

SVG_FILE="AppIcon.svg"
OUTPUT_DIR="DemoConsole/Resources/Assets.xcassets/AppIcon.appiconset"
SIDEBAR_DIR="DemoConsole/Resources/Assets.xcassets/SidebarIcon.imageset"

# 确保输出目录存在
mkdir -p "$OUTPUT_DIR"
mkdir -p "$SIDEBAR_DIR"

# macOS App Icon 所需尺寸
SIZES=(
    "16:1"
    "16:2"
    "32:1"
    "32:2"
    "128:1"
    "128:2"
    "256:1"
    "256:2"
    "512:1"
    "512:2"
)

echo "🎨 正在生成 App Icon..."

for SIZE_SCALE in "${SIZES[@]}"; do
    SIZE="${SIZE_SCALE%%:*}"
    SCALE="${SIZE_SCALE##*:}"
    
    ACTUAL_SIZE=$((SIZE * SCALE))
    
    if [ "$SCALE" -eq 1 ]; then
        FILENAME="icon_${SIZE}x${SIZE}.png"
    else
        FILENAME="icon_${SIZE}x${SIZE}@${SCALE}x.png"
    fi
    
    echo "  生成 $FILENAME ($ACTUAL_SIZE x $ACTUAL_SIZE)"
    
    # 使用 rsvg-convert 转换
    if command -v rsvg-convert &> /dev/null; then
        rsvg-convert -w "$ACTUAL_SIZE" -h "$ACTUAL_SIZE" "$SVG_FILE" -o "$OUTPUT_DIR/$FILENAME"
    # 备选：使用 sips (macOS 自带)
    elif command -v sips &> /dev/null; then
        # sips 不支持 SVG，需要先用其他工具转换
        echo "  ⚠️ 需要安装 librsvg: brew install librsvg"
        exit 1
    fi
done

echo "🎨 正在生成 Sidebar Icon..."

# Sidebar Icon 尺寸: 52x52 @1x, @2x, @3x
SIDEBAR_SIZES=("1" "2" "3")
for SCALE in "${SIDEBAR_SIZES[@]}"; do
    ACTUAL_SIZE=$((52 * SCALE))
    if [ "$SCALE" -eq 1 ]; then
        FILENAME="sidebar_icon.png"
    else
        FILENAME="sidebar_icon@${SCALE}x.png"
    fi
    echo "  生成 $FILENAME ($ACTUAL_SIZE x $ACTUAL_SIZE)"
    rsvg-convert -w "$ACTUAL_SIZE" -h "$ACTUAL_SIZE" "$SVG_FILE" -o "$SIDEBAR_DIR/$FILENAME"
done

# 更新 Contents.json
cat > "$OUTPUT_DIR/Contents.json" << 'EOF'
{
  "images" : [
    {
      "filename" : "icon_16x16.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_16x16@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_32x32.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_32x32@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_128x128.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_128x128@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_256x256.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_256x256@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_512x512.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "filename" : "icon_512x512@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

echo ""
echo "✅ App Icon 生成完成！"
echo "   图标位置: $OUTPUT_DIR"
