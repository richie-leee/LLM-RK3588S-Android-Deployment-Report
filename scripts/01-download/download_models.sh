#!/data/data/com.termux/files/usr/bin/bash
# GLM-Edge 模型下载脚本

set -e

echo "======================================"
echo "GLM-Edge 模型下载"
echo "======================================"

cd ~/models

# 模型下载 URL（使用 HuggingFace）
GLM_EDGE_V_5B_URL="https://huggingface.co/Akicou/glm-edge-v-5b-GGUF/resolve/main/glm-edge-v-5b-Q4_K_M.gguf"
GLM_EDGE_4B_CHAT_URL="https://huggingface.co/mradermacher/glm-edge-4b-chat-GGUF/resolve/main/glm-edge-4b-chat.Q4_K_M.gguf"

echo "目标模型："
echo "1. GLM-Edge-V 5B (多模态) - Q4_K_M - 约 3.5GB"
echo "2. GLM-Edge 4B Chat (文本) - Q4_K_M - 约 2.5GB"
echo ""

# 测试网络连接
echo "测试 HuggingFace 连接..."
if curl -I --connect-timeout 10 https://huggingface.co/ > /dev/null 2>&1; then
    echo "✓ HuggingFace 可访问"
else
    echo "✗ HuggingFace 无法访问"
    echo "提示：可能需要配置代理或从 PC 传输模型文件"
    exit 1
fi

# 下载 GLM-Edge-V 5B
echo ""
echo "[1/2] 下载 GLM-Edge-V 5B GGUF..."
if [ -f "glm-edge-v-5b-Q4_K_M.gguf" ]; then
    echo "文件已存在，跳过下载"
else
    wget -c "$GLM_EDGE_V_5B_URL" -O glm-edge-v-5b-Q4_K_M.gguf.tmp
    mv glm-edge-v-5b-Q4_K_M.gguf.tmp glm-edge-v-5b-Q4_K_M.gguf
    echo "✓ GLM-Edge-V 5B 下载完成"
fi

# 下载 GLM-Edge 4B Chat
echo ""
echo "[2/2] 下载 GLM-Edge 4B Chat GGUF..."
if [ -f "glm-edge-4b-chat.Q4_K_M.gguf" ]; then
    echo "文件已存在，跳过下载"
else
    wget -c "$GLM_EDGE_4B_CHAT_URL" -O glm-edge-4b-chat.Q4_K_M.gguf.tmp
    mv glm-edge-4b-chat.Q4_K_M.gguf.tmp glm-edge-4b-chat.Q4_K_M.gguf
    echo "✓ GLM-Edge 4B Chat 下载完成"
fi

# 显示结果
echo ""
echo "======================================"
echo "模型下载完成！"
echo "======================================"
ls -lh ~/models/*.gguf

echo ""
echo "下一步：运行测试"
echo "  cd ~/llama.cpp"
echo "  ./llama-cli -m ~/models/glm-edge-4b-chat.Q4_K_M.gguf -p '你好' -n 50"
echo "======================================"
