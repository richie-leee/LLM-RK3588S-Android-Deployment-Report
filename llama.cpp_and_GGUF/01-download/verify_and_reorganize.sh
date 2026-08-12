#!/bin/bash
# 下载完成后：1) 校验字节数  2) 重组 V-5B 文件到 v5b/ 子目录
set -e
cd "$(dirname "$0")/models" || exit 1

echo "=========================================="
echo "第 1 步：校验所有模型文件完整性"
echo "=========================================="

verify() {
  local file=$1 want=$2
  local have=0
  [ -f "$file" ] && have=$(stat -c %s "$file")
  if [ "$have" -eq "$want" ]; then
    echo "✓ $file  ($have bytes)"
    return 0
  else
    echo "✗ $file  有 $have bytes，应为 $want bytes"
    return 1
  fi
}

fail=0
verify glm-edge-1.5b-chat.Q4_K_M.gguf 980470144 || fail=1
verify glm-edge-4b-chat.Q4_K_M.gguf 2627489280 || fail=1
verify glm-edge-v-5b-Q4_K_M.gguf 2627488800 || fail=1
verify mmproj-model-f16.gguf 1028670432 || fail=1
verify v2b/ggml-model-Q4_K_M.gguf 980470208 || fail=1
verify v2b/mmproj-model-f16.gguf 933229600 || fail=1

if [ "$fail" -ne 0 ]; then
  echo ""
  echo "❌ 校验失败，有文件不完整，禁止推送到板子"
  exit 1
fi

echo ""
echo "=========================================="
echo "第 2 步：重组 V-5B 文件到 v5b/ 子目录"
echo "=========================================="

mkdir -p v5b

if [ -f "glm-edge-v-5b-Q4_K_M.gguf" ]; then
  echo "移动 glm-edge-v-5b-Q4_K_M.gguf → v5b/ggml-model-Q4_K_M.gguf"
  mv glm-edge-v-5b-Q4_K_M.gguf v5b/ggml-model-Q4_K_M.gguf
fi

if [ -f "mmproj-model-f16.gguf" ]; then
  echo "移动 mmproj-model-f16.gguf → v5b/mmproj-model-f16.gguf"
  mv mmproj-model-f16.gguf v5b/mmproj-model-f16.gguf
fi

echo ""
echo "=========================================="
echo "✓ 全部完成！最终文件结构："
echo "=========================================="
ls -lh glm-edge-*.gguf v2b/*.gguf v5b/*.gguf 2>/dev/null | awk '{printf "  %-40s %8s\n", $9, $5}'

echo ""
echo "现在可以执行："
echo "  bash transfer_and_test.sh"
echo ""
echo "将所有模型推送到板子 /sdcard/models/"
echo "=========================================="
