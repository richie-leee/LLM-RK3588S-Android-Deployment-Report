#!/bin/bash
# 通过 hf-mirror 断点续传 GLM-Edge 模型（huggingface.co 在本网络不通）
# 已验证：本地残文件前 1MB 与远端一致，可安全续传
MIRROR=https://hf-mirror.com
cd "$(dirname "$0")/models" || exit 1

resume() {
  local file=$1 path=$2 want=$3
  local have=0
  [ -f "$file" ] && have=$(stat -c %s "$file")
  if [ "$have" -eq "$want" ]; then
    echo "[OK] $file 已完整 ($want)"
    return 0
  fi
  echo "[GO] $file  $have / $want"
  curl -L --fail --retry 20 --retry-delay 3 --retry-all-errors \
       -C - -o "$file" "$MIRROR/$path"
  local now=$(stat -c %s "$file")
  if [ "$now" -eq "$want" ]; then echo "[DONE] $file $now"; else echo "[PARTIAL] $file $now / $want"; fi
}

resume glm-edge-4b-chat.Q4_K_M.gguf \
  "mradermacher/glm-edge-4b-chat-GGUF/resolve/main/glm-edge-4b-chat.Q4_K_M.gguf" 2627489280 &
P1=$!
resume glm-edge-v-5b-Q4_K_M.gguf \
  "zai-org/glm-edge-v-5b-gguf/resolve/main/ggml-model-Q4_K_M.gguf" 2627488800 &
P2=$!
resume mmproj-model-f16.gguf \
  "zai-org/glm-edge-v-5b-gguf/resolve/main/mmproj-model-f16.gguf" 1028670432 &
P3=$!

wait $P1 $P2 $P3
echo "=== 最终状态 ==="
stat -c "%n %s" *.gguf
