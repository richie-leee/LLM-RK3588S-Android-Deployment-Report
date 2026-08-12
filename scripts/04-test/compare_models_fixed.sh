#!/data/data/com.termux/files/usr/bin/bash
cd ~/llama.cpp

echo "=========================================="
echo "GLM-Edge 模型对比测试"
echo "V-2B (多模态) vs 1.5B-Chat (纯文本)"
echo "=========================================="

# 拷贝 1.5B 模型到 Termux 目录
echo "准备 1.5B 模型..."
mkdir -p ~/models/1.5b
cp /sdcard/models/glm-edge-1.5b-chat.Q4_K_M.gguf ~/models/1.5b/ 2>/dev/null || echo "1.5B 已存在"

test_model() {
  local name=$1
  local model=$2
  local mmproj=$3
  local question=$4

  echo ""
  echo "=========================================="
  echo "[$name] 测试"
  echo "问题: $question"
  echo "=========================================="

  ./build/bin/llama-llava-cli \
    -m "$model" \
    --mmproj "$mmproj" \
    --image ~/test.jpg \
    -p "<|user|>
${question}<|assistant|>
" \
    -n 256 -t 8 -c 2048 2>&1 | tail -30

  echo ""
}

# 测试同一个问题
QUESTION="请用中文简要讲解什么是递归函数，并举一个简单例子"

test_model "V-2B 多模态" \
  "~/models/v2b/ggml-model-Q4_K_M.gguf" \
  "~/models/v2b/mmproj-model-f16.gguf" \
  "$QUESTION"

test_model "1.5B 纯文本" \
  "~/models/1.5b/glm-edge-1.5b-chat.Q4_K_M.gguf" \
  "~/models/v2b/mmproj-model-f16.gguf" \
  "$QUESTION"

echo "=========================================="
echo "对比测试完成"
echo "=========================================="
