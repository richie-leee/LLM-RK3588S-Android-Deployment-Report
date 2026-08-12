#!/data/data/com.termux/files/usr/bin/bash
cd ~/llama.cpp

echo "=========================================="
echo "启动 GLM-Edge-V-2B Web 服务"
echo "=========================================="
echo "模型加载中，请稍候..."
echo "启动后在手机浏览器访问: http://localhost:8080"
echo "按 Ctrl+C 停止服务"
echo ""

./build/bin/llama-server \
  -m ~/models/v2b/ggml-model-Q4_K_M.gguf \
  --port 8080 \
  --host 0.0.0.0 \
  -c 2048 \
  -t 8 \
  --log-disable
