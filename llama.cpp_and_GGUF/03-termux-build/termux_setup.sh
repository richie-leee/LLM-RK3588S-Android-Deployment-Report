#!/data/data/com.termux/files/usr/bin/bash
# Termux 环境配置脚本 - GLM-Edge 部署

set -e

echo "======================================"
echo "GLM-Edge 模型部署 - Termux 配置"
echo "======================================"

# 1. 更新软件包
echo "[1/6] 更新 Termux 软件包..."
yes | pkg update
yes | pkg upgrade

# 2. 安装基础工具
echo "[2/6] 安装基础工具..."
pkg install -y git wget curl clang cmake python vim

# 3. 创建工作目录
echo "[3/6] 创建目录结构..."
mkdir -p ~/models
mkdir -p ~/llama.cpp

# 4. 克隆 llama.cpp
echo "[4/6] 克隆 llama.cpp 仓库..."
cd ~
if [ -d "llama.cpp/.git" ]; then
    echo "llama.cpp 已存在，更新中..."
    cd llama.cpp
    git pull
else
    git clone --depth 1 https://github.com/ggml-org/llama.cpp
    cd llama.cpp
fi

# 5. 编译 llama.cpp
echo "[5/6] 编译 llama.cpp（使用 ARM NEON 优化）..."
make clean
make -j$(nproc)

# 6. 验证编译结果
echo "[6/6] 验证安装..."
if [ -f "./llama-cli" ]; then
    echo "✓ llama-cli 编译成功"
    ./llama-cli --version
else
    echo "✗ llama-cli 编译失败"
    exit 1
fi

if [ -f "./llama-server" ]; then
    echo "✓ llama-server 编译成功"
else
    echo "✗ llama-server 未找到"
fi

echo ""
echo "======================================"
echo "Termux 环境配置完成！"
echo "======================================"
echo "工作目录："
echo "  - llama.cpp: ~/llama.cpp"
echo "  - 模型目录: ~/models"
echo ""
echo "下一步：下载 GLM-Edge 模型"
echo "======================================"
