#!/data/data/com.termux/files/usr/bin/bash
cd ~/llama.cpp

echo "=========================================="
echo "GLM-Edge-V-2B 交互式对话"
echo "=========================================="
echo "提示：每次对话会加载图片 ~/test.jpg（占位用）"
echo "输入 'exit' 或 'quit' 退出"
echo ""

while true; do
  echo -n "你: "
  read -r user_input

  # 退出检查
  if [ "$user_input" = "exit" ] || [ "$user_input" = "quit" ]; then
    echo "再见！"
    break
  fi

  # 跳过空输入
  if [ -z "$user_input" ]; then
    continue
  fi

  echo ""
  echo "AI: "

  # 调用模型
  ./build/bin/llama-llava-cli \
    -m ~/models/v2b/ggml-model-Q4_K_M.gguf \
    --mmproj ~/models/v2b/mmproj-model-f16.gguf \
    --image ~/test.jpg \
    -p "<|user|>
${user_input}<|assistant|>
" \
    -n 256 -t 8 -c 2048 2>&1 | grep -v "^clip_model_load" | grep -v "^llama_" | grep -v "^encode_image" | tail -20

  echo ""
  echo "=========================================="
done
