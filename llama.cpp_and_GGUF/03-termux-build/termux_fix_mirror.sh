#!/data/data/com.termux/files/usr/bin/bash
# 换成清华 TUNA 镜像（原 mirror.sunred.org 只有 16kB/s）
set -e
PREFIX=/data/data/com.termux/files/usr

echo "[1/3] 备份并写入清华镜像源..."
cp $PREFIX/etc/apt/sources.list $PREFIX/etc/apt/sources.list.bak 2>/dev/null || true
echo "deb https://mirrors.tuna.tsinghua.edu.cn/termux/apt/termux-main stable main" \
  > $PREFIX/etc/apt/sources.list
cat $PREFIX/etc/apt/sources.list

echo "[2/3] 刷新包索引..."
apt update -y

echo "[3/3] 安装编译工具（git clang cmake）..."
DEBIAN_FRONTEND=noninteractive apt install -y -o Dpkg::Options::=--force-confold \
  git clang cmake make

echo ""
echo "=========================================="
echo "工具链安装完成，版本确认："
echo "=========================================="
git --version
clang --version | head -1
cmake --version | head -1
echo ""
echo "下一步：bash /sdcard/termux_build_glm.sh"
