#!/bin/bash
# curl 单线程顺序下载，移除 --retry-all-errors 避免覆写
set -e
MIRROR=https://hf-mirror.com
cd "$(dirname "$0")/models" || exit 1
mkdir -p v2b v5b

get_curl() {
  local out=$1 path=$2 want=$3
  local have=0
  [ -f "$out" ] && have=$(stat -c %s "$out")
  if [ "$have" -eq "$want" ]; then
    echo "✓ $out 已完整 ($want 字节)"
    return 0
  fi
  echo "[下载] $out (已有 $have, 目标 $want)"
  # 移除 --retry-all-errors，只重试超时/DNS失败等安全错误
  curl -sL --fail -C - -o "$out" "$MIRROR/$path" \
    --retry 10 --retry-delay 3 --connect-timeout 30 --max-time 0
  local now=0; [ -f "$out" ] && now=$(stat -c %s "$out")
  if [ "$now" -eq "$want" ]; then
    echo "✓ $out 完成"
  else
    echo "⚠ $out 部分完成: $now/$want，可重新运行此脚本继续"
    return 1
  fi
}

echo "=========================================="
echo "GLM-Edge 模型下载 - curl 单线程顺序模式"
echo "开始时间: $(date '+%H:%M:%S')"
echo "=========================================="

# 顺序下载：1.5B → V-2B 主 → 4B → V-5B 主
get_curl glm-edge-1.5b-chat.Q4_K_M.gguf \
  "zai-org/glm-edge-1.5b-chat-gguf/resolve/main/ggml-model-Q4_K_M.gguf" 980470144

get_curl v2b/ggml-model-Q4_K_M.gguf \
  "zai-org/glm-edge-v-2b-gguf/resolve/main/ggml-model-Q4_K_M.gguf" 980470208

get_curl glm-edge-4b-chat.Q4_K_M.gguf \
  "mradermacher/glm-edge-4b-chat-GGUF/resolve/main/glm-edge-4b-chat.Q4_K_M.gguf" 2627489280

get_curl v5b/ggml-model-Q4_K_M.gguf \
  "zai-org/glm-edge-v-5b-gguf/resolve/main/ggml-model-Q4_K_M.gguf" 2627488800

echo ""
echo "=========================================="
echo "全部下载完成！结束时间: $(date '+%H:%M:%S')"
echo "=========================================="
ls -lh glm-edge-*.gguf v2b/*.gguf v5b/*.gguf 2>/dev/null | awk '{printf "%-45s %8s\n", $9, $5}'
