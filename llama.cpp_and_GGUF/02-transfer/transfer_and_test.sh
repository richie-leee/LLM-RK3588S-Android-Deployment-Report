#!/bin/bash
# GLM-Edge 全系列部署脚本（修正版）
# 改动：mv→cp（跨文件系统），v2b/v5b子目录，等待编译后确认二进制名
set -e
echo "=== GLM-Edge 部署：传输+测试 ==="

# 1. 创建设备上的目录结构
echo "[1/7] 在板子上创建目录..."
adb shell "mkdir -p /sdcard/models/v2b /sdcard/models/v5b"

# 2. 传输模型文件
echo "[2/7] 传输 1.5B Chat 模型..."
adb push models/glm-edge-1.5b-chat.Q4_K_M.gguf /sdcard/models/

echo "[3/7] 传输 V-2B 模型（主+mmproj）..."
adb push models/v2b/ggml-model-Q4_K_M.gguf /sdcard/models/v2b/
adb push models/v2b/mmproj-model-f16.gguf /sdcard/models/v2b/

echo "[4/7] 传输 4B Chat 模型..."
adb push models/glm-edge-4b-chat.Q4_K_M.gguf /sdcard/models/

echo "[5/7] 传输 V-5B 模型（主+mmproj）..."
adb push models/v5b/ggml-model-Q4_K_M.gguf /sdcard/models/v5b/
adb push models/v5b/mmproj-model-f16.gguf /sdcard/models/v5b/

echo "[6/7] 传输 Termux 编译脚本..."
adb push termux_setup_glm_edge_final.sh /sdcard/

echo "[7/7] 传输完成！文件列表："
adb shell "find /sdcard/models -name '*.gguf' | sort"

echo ""
echo "=========================================="
echo "下一步：在 Termux 中手动执行"
echo "=========================================="
echo "bash /sdcard/termux_setup_glm_edge_final.sh"
echo ""
echo "编译完成后，务必先执行："
echo "  ls ~/llama.cpp/build/bin/"
echo ""
echo "记录实际存在的二进制名称（llama-llava-cli 或 llama-mtmd-cli）"
echo "然后根据实际二进制运行测试命令（见 test_commands_final.txt）"
echo "=========================================="
