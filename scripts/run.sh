#!/bin/bash

# KeyHelp 运行脚本 - 开发调试模式

set -e

# 配置
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOG_DIR="$PROJECT_DIR/logs"
LOG_FILE="$LOG_DIR/keyhelp_$(date +%Y%m%d_%H%M%S).log"

# 创建日志目录
mkdir -p "$LOG_DIR"

echo "=== KeyHelp 开发模式启动 ===" | tee -a "$LOG_FILE"
echo "时间: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$LOG_FILE"
echo "日志文件: $LOG_FILE" | tee -a "$LOG_FILE"
echo ""

# 检查Flutter是否安装
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter未安装，请先运行 ./scripts/install_flutter.sh" | tee -a "$LOG_FILE"
    exit 1
fi

echo "✓ Flutter版本: $(flutter --version | head -n 1)" | tee -a "$LOG_FILE"
echo ""

# 获取可用设备
echo "正在检查可用设备..." | tee -a "$LOG_FILE"
flutter devices | tee -a "$LOG_FILE"

# 检查是否有连接的设备
DEVICE_COUNT=$(flutter devices | grep -c "•" || true)

if [ "$DEVICE_COUNT" -eq 0 ]; then
    echo ""
    echo "⚠️  未检测到可用设备" | tee -a "$LOG_FILE"
    echo "请确保已连接Android设备或启动模拟器" | tee -a "$LOG_FILE"
    exit 1
fi

echo ""
echo "✓ 检测到 $DEVICE_COUNT 个可用设备" | tee -a "$LOG_FILE"
echo ""

# 进入项目目录
cd "$PROJECT_DIR"

# 检查pubspec.yaml是否存在
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ 未找到pubspec.yaml文件" | tee -a "$LOG_FILE"
    exit 1
fi

# 获取依赖
echo "正在获取Flutter依赖..." | tee -a "$LOG_FILE"
flutter pub get 2>&1 | tee -a "$LOG_FILE"
echo ""

# 生成Hive适配器
echo "正在生成Hive适配器..." | tee -a "$LOG_FILE"
dart run build_runner build --delete-conflicting-outputs 2>&1 | tee -a "$LOG_FILE"
echo ""

# 运行应用
echo "=== 启动KeyHelp应用 ===" | tee -a "$LOG_FILE"
flutter run 2>&1 | tee -a "$LOG_FILE"
