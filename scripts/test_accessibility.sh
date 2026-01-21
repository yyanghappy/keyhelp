#!/bin/bash

# KeyHelp 无障碍功能测试脚本

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

echo "=== KeyHelp 无障碍功能测试 ==="
echo ""

echo "正在构建应用..."
flutter build apk --debug --no-pub

if [ $? -eq 0 ]; then
    echo "✓ 构建成功"
    echo ""
    echo "正在安装应用..."
    adb install -r build/app/outputs/flutter-apk/app-debug.apk
    
    if [ $? -eq 0 ]; then
        echo "✓ 安装成功"
        echo ""
        echo "正在启动应用..."
        adb shell am start -n com.keyhelp.app/.MainActivity
        
        if [ $? -eq 0 ]; then
            echo "✓ 应用已启动"
            echo ""
            echo "=== 测试步骤 ==="
            echo ""
            echo "1. 在应用首页查看无障碍服务状态"
            echo "2. 如果显示'未启用'，点击右上角图标"
            echo "3. 在系统设置中启用 KeyHelp 无障碍服务"
            echo "4. 返回应用，图标应变绿色"
            echo "5. 尝试录制一个简单脚本"
            echo "6. 执行录制的脚本"
            echo ""
            echo "查看日志："
            echo "  adb logcat | grep KeyHelpAccessibility"
            echo ""
        else
            echo "✗ 应用启动失败"
            exit 1
        fi
    else
        echo "✗ 安装失败"
        exit 1
    fi
else
    echo "✗ 构建失败"
    exit 1
fi
