#!/data/data/com.termux/files/usr/bin/bash
cd ~/llama.cpp

echo "=========================================="
echo "GLM-Edge-V-2B 多图测试"
echo "=========================================="

test_image() {
  local img=$1
  local desc=$2
  echo ""
  echo "[$desc] 测试图片: $img"
  echo "------------------------------------------"
  ./build/bin/llama-llava-cli \
    -m ~/models/v2b/ggml-model-Q4_K_M.gguf \
    --mmproj ~/models/v2b/mmproj-model-f16.gguf \
    --image "$img" \
    -p "<|user|>
请详细描述这张图片的内容<|assistant|>
" \
    -n 256 -t 8 2>&1 | tail -30
  echo ""
  echo "=========================================="
}

# 准备测试图片：将待测图片放到板子的 /sdcard/testimg/ 下即可
# 建议覆盖三类：自然场景、含文字的文档图（验 OCR）、多对象复杂场景
IMG_DIR=${IMG_DIR:-/sdcard/testimg}

if [ ! -d "$IMG_DIR" ]; then
  echo "未找到图片目录 $IMG_DIR"
  echo "请先创建并放入测试图片：adb shell mkdir -p $IMG_DIR && adb push <本地图片> $IMG_DIR/"
  exit 1
fi

i=0
for src in "$IMG_DIR"/*.{png,jpg,jpeg}; do
  [ -f "$src" ] || continue
  i=$((i+1))
  cp "$src" ~/test$i.png
  test_image ~/test$i.png "图片$i（$(basename "$src")）"
done

[ $i -eq 0 ] && { echo "$IMG_DIR 下没有可用图片"; exit 1; }

echo "全部测试完成"
