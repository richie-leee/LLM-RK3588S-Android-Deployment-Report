#!/data/data/com.termux/files/usr/bin/bash
cd ~/llama.cpp

# 创建一个 1x1 纯白占位图片（避免图像编码耗时）
# 如果没有 ImageMagick，就复用已有的 test.jpg
if ! command -v convert &> /dev/null; then
  echo "使用已有图片作为占位"
else
  convert -size 1x1 xc:white ~/placeholder.jpg 2>/dev/null || cp ~/test.jpg ~/placeholder.jpg
fi
[ ! -f ~/placeholder.jpg ] && cp ~/test.jpg ~/placeholder.jpg

echo "=========================================="
echo "GLM-Edge-V-2B 纯文本对话测试"
echo "（用占位图片绕过 llama-llava-cli 的图片检查）"
echo "=========================================="

# 测试1：语法讲解
echo ""
echo "[测试1] 中文语法讲解"
echo "------------------------------------------"
./build/bin/llama-llava-cli \
  -m ~/models/v2b/ggml-model-Q4_K_M.gguf \
  --mmproj ~/models/v2b/mmproj-model-f16.gguf \
  --image ~/placeholder.jpg \
  -p "<|user|>
请用中文详细讲解一下英语中的现在进行时，包括结构、用法和例句<|assistant|>
" \
  -n 512 -t 8 -c 2048

echo ""
echo "=========================================="

# 测试2：代码解释
echo ""
echo "[测试2] 代码解释"
echo "------------------------------------------"
./build/bin/llama-llava-cli \
  -m ~/models/v2b/ggml-model-Q4_K_M.gguf \
  --mmproj ~/models/v2b/mmproj-model-f16.gguf \
  --image ~/placeholder.jpg \
  -p "<|user|>
解释这段Python代码的作用：
def fibonacci(n):
    if n <= 1:
        return n
    return fibonacci(n-1) + fibonacci(n-2)
<|assistant|>
" \
  -n 256 -t 8 -c 2048

echo ""
echo "=========================================="

# 测试3：常识问答
echo ""
echo "[测试3] 常识问答"
echo "------------------------------------------"
./build/bin/llama-llava-cli \
  -m ~/models/v2b/ggml-model-Q4_K_M.gguf \
  --mmproj ~/models/v2b/mmproj-model-f16.gguf \
  --image ~/placeholder.jpg \
  -p "<|user|>
为什么天空是蓝色的？请用简单的语言解释<|assistant|>
" \
  -n 256 -t 8 -c 2048

echo ""
echo "全部测试完成"
