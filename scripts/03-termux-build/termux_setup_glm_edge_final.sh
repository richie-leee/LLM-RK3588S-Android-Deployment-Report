#!/data/data/com.termux/files/usr/bin/bash
# GLM-Edge 专用 llama.cpp 编译脚本（piDack support_glm_edge_model 分支）
set -e

echo "[1/6] 更新 Termux 软件包..."
pkg update -y
pkg upgrade -y

echo "[2/6] 安装编译工具..."
pkg install -y git clang cmake python

echo "[3/6] 克隆 piDack/llama.cpp (support_glm_edge_model 分支)..."
cd ~
rm -rf llama.cpp
git clone --depth 1 -b support_glm_edge_model https://github.com/piDack/llama.cpp

echo "[4/6] 配置构建..."
cd llama.cpp
cmake -B build -DCMAKE_BUILD_TYPE=Release

echo "[5/6] 编译（ARM NEON 优化，8线程）..."
cmake --build build -j8

echo "[6/6] 创建模型目录并拷贝文件..."
mkdir -p ~/models/v2b ~/models/v5b
echo "使用 cp 拷贝（不用 mv，避免跨文件系统问题）："
cp /sdcard/models/glm-edge-1.5b-chat.Q4_K_M.gguf ~/models/
cp /sdcard/models/v2b/*.gguf ~/models/v2b/
cp /sdcard/models/glm-edge-4b-chat.Q4_K_M.gguf ~/models/
cp /sdcard/models/v5b/*.gguf ~/models/v5b/

echo ""
echo "=========================================="
echo "编译完成！"
echo "=========================================="
echo "关键步骤：查看实际生成的二进制文件名"
echo ""
echo "执行："
echo "  ls ~/llama.cpp/build/bin/"
echo ""
echo "记录输出中的多模态二进制名称："
echo "  - 如果是 llama-llava-cli → 测试时用它"
echo "  - 如果是 llama-mtmd-cli → 测试时用它"
echo "  - llama-cli 一定存在（纯文本推理）"
echo ""
echo "然后参考 /sdcard/test_commands_final.txt 运行测试"
echo "=========================================="
