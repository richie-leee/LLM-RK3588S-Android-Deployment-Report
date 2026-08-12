#!/bin/bash
# 模型传输脚本

echo "======================================"
echo "传输模型到板子"
echo "======================================"

cd models

echo "[1/2] 传输 GLM-Edge 4B Chat..."
adb push glm-edge-4b-chat.Q4_K_M.gguf /sdcard/
echo "✓ 4B Chat 传输完成"

echo "[2/2] 传输 GLM-Edge-V 5B..."
adb push glm-edge-v-5b.Q4_K_M.gguf /sdcard/
echo "✓ 5B Vision 传输完成"

echo ""
echo "======================================"
echo "传输完成！"
echo "======================================"
echo "在 Termux 中执行以下命令移动文件："
echo "  mv /sdcard/*.gguf ~/models/"
echo "  ls -lh ~/models/"
echo "======================================"
