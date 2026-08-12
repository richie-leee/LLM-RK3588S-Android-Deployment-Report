#!/data/data/com.termux/files/usr/bin/bash
cd ~/llama.cpp
./build/bin/llama-llava-cli \
  -m ~/models/v2b/ggml-model-Q4_K_M.gguf \
  --mmproj ~/models/v2b/mmproj-model-f16.gguf \
  --image ~/test.jpg \
  -p "<|user|>
描述这张图片<|assistant|>
" \
  -n 256 -t 8
