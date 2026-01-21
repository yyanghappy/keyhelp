#!/bin/bash

# KeyHelp 快速启动脚本 - 仅用于演示和测试

set -e

echo "=========================================="
echo "  KeyHelp - 安卓自动化工具"
echo "=========================================="
echo ""

# 检查项目文件
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ 未找到 pubspec.yaml，请确保在项目根目录运行此脚本"
    exit 1
fi

# 检查Flutter
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter未安装"
    echo ""
    echo "请先安装Flutter："
    echo "  ./scripts/install_flutter.sh"
    echo ""
    exit 1
fi

echo "✓ Flutter已安装"
echo ""

# 创建必要目录
mkdir -p logs docs discuss scripts

echo "项目已准备就绪！"
echo ""
echo "下一步操作："
echo ""
echo "1. 运行应用（开发模式）："
echo "   ./scripts/run.sh"
echo ""
echo "2. 构建Release版本："
echo "   ./scripts/build.sh"
echo ""
echo "3. 查看文档："
echo "   - 使用文档: docs/使用文档.md"
echo "   - 开发指南: docs/开发指南.md"
echo ""
