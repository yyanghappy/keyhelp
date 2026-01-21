#!/bin/bash

# KeyHelp 调试脚本 - 构建Release包

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOG_DIR="$PROJECT_DIR/logs"
LOG_FILE="$LOG_DIR/build_$(date +%Y%m%d_%H%M%S).log"

mkdir -p "$LOG_DIR"

echo "=== KeyHelp Release构建 ===" | tee -a "$LOG_FILE"
echo "时间: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$LOG_FILE"
echo ""

cd "$PROJECT_DIR"

echo "正在获取Flutter依赖..." | tee -a "$LOG_FILE"
flutter pub get 2>&1 | tee -a "$LOG_FILE"

echo "正在构建Release APK..." | tee -a "$LOG_FILE"
flutter build apk --release 2>&1 | tee -a "$LOG_FILE"

echo ""
echo "=== 构建完成 ===" | tee -a "$LOG_FILE"
echo "APK位置: $PROJECT_DIR/build/app/outputs/flutter-apk/app-release.apk" | tee -a "$LOG_FILE"
