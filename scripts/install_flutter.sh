#!/bin/bash

# Flutter环境安装脚本
# 支持 macOS/Linux

set -e

echo "=== KeyHelp - Flutter 环境安装 ==="
echo ""

# 检测操作系统
OS="$(uname -s)"
case "${OS}" in
    Darwin*)    PLATFORM=macos;;
    Linux*)     PLATFORM=linux;;
    *)          echo "不支持的操作系统: ${OS}"; exit 1;;
esac

echo "检测到平台: ${PLATFORM}"
echo ""

# 1. 安装Flutter SDK
if command -v flutter &> /dev/null; then
    echo "✓ Flutter 已安装: $(flutter --version | head -n 1)"
else
    echo "正在安装 Flutter SDK..."

    # 创建安装目录
    FLUTTER_DIR="$HOME/development"
    mkdir -p "$FLUTTER_DIR"

    # 下载Flutter
    case "${PLATFORM}" in
        macos)
            cd "$FLUTTER_DIR"
            curl -LO https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_3.27.3-stable.zip
            unzip flutter_macos_arm64_3.27.3-stable.zip
            rm flutter_macos_arm64_3.27.3-stable.zip
            ;;
        linux)
            cd "$FLUTTER_DIR"
            wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.27.3-stable.tar.xz
            tar xf flutter_linux_3.27.3-stable.tar.xz
            rm flutter_linux_3.27.3-stable.tar.xz
            ;;
    esac

    # 添加到PATH
    FLUTTER_BIN="$FLUTTER_DIR/flutter/bin"
    case "${SHELL}" in
        */zsh)
            if ! grep -q "$FLUTTER_BIN" "$HOME/.zshrc"; then
                echo "export PATH=\"\$PATH:$FLUTTER_BIN\"" >> "$HOME/.zshrc"
            fi
            ;;
        */bash)
            if ! grep -q "$FLUTTER_BIN" "$HOME/.bashrc"; then
                echo "export PATH=\"\$PATH:$FLUTTER_BIN\"" >> "$HOME/.bashrc"
            fi
            ;;
    esac

    export PATH="$PATH:$FLUTTER_BIN"
    echo "✓ Flutter 安装完成"
fi

# 2. 配置Flutter
echo ""
echo "正在配置 Flutter..."
flutter config --no-analytics
flutter precache

# 3. 检查依赖
echo ""
echo "正在检查 Flutter 依赖..."
flutter doctor -v

echo ""
echo "=== 安装完成 ==="
echo ""
echo "请重启终端以使 PATH 生效"
echo "如果 macOS 提示安装 Xcode，请运行: sudo xcode-select --switch /Applications/Xcode.app"
