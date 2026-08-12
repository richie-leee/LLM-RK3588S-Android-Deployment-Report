#!/data/data/com.termux/files/usr/bin/bash
cd ~/llama.cpp

echo "=========================================="
echo "GLM-Edge-V-2B 自动问答测试（3个问题）"
echo "=========================================="

ask() {
  local question=$1
  echo ""
  echo "问题: $question"
  echo "------------------------------------------"
  echo "AI: "
  ./build/bin/llama-llava-cli \
    -m ~/models/v2b/ggml-model-Q4_K_M.gguf \
    --mmproj ~/models/v2b/mmproj-model-f16.gguf \
    --image ~/test.jpg \
    -p "<|user|>
${question}<|assistant|>
" \
    -n 512 -t 8 -c 2048 2>&1 | tail -40
  echo ""
  echo "=========================================="
}

ask "请用中文详细讲解英语中的现在进行时，包括结构、用法和例句"
ask "为什么天空是蓝色的？请用简单的语言解释"
ask "解释什么是递归函数，并举一个简单的例子"

echo "全部问题测试完成"
