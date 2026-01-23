# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

KeyHelp 是一个基于 Flutter 的安卓轻量化自动化工具，通过 Android AccessibilityService 实现脚本录制与回放功能。

**技术栈**：
- Flutter 3.24+ / Dart 3.5+
- 状态管理：Riverpod 2.6+
- 本地存储：Hive 2.2+
- 原生服务：Android AccessibilityService

## 常用命令

所有开发操作必须通过 `scripts/` 目录下的脚本执行：

```bash
# 开发模式运行（带日志输出到 logs/ 目录）
./scripts/run.sh

# 构建 Release APK
./scripts/build.sh

# 测试无障碍服务
./scripts/test_accessibility.sh

# 安装 Flutter SDK（首次使用时）
./scripts/install_flutter.sh
```

**日志位置**：所有运行日志输出到 `logs/` 目录，文件名格式为 `keyhelp_YYYYMMDD_HHMMSS.log`

查看实时日志：
```bash
tail -f logs/keyhelp_*.log
```

## 核心架构

### 分层结构

```
lib/
├── features/       # 功能页面层 - UI 界面和用户交互
├── shared/         # 共享组件层 - 跨功能的组件和服务
├── core/           # 核心业务层 - 服务、模型、仓库
└── config/         # 配置层 - 主题、常量
```

### 数据流架构

```
Android 层
  ├─ KeyHelpAccessibilityService.java    # 主无障碍服务 (触控模拟)
  ├─ TouchRecordingService.java          # 触摸录制服务
  └─ FloatWindowService.java             # 浮窗服务
         ↓
AccessibilityMethodChannel.java         # Flutter 与原生服务的 MethodChannel 桥接
         ↓
AccessibilityPlatformService.dart       # 无障碍平台服务桥接
         ↓
AccessibilityService.dart (单例)        # Dart 层无障碍服务封装
         ↓
┌──────────────────┬──────────────────┐
│ ScriptRecorder   │ ScriptExecutor   │ # 脚本录制/执行服务
└──────────────────┴──────────────────┘
         ↓
Hive 本地存储
```

### 核心服务说明

**lib/core/services/**

| 服务 | 作用 |
|------|------|
| `accessibility_service.dart` | 无障碍服务单例，处理触控监听和模拟 |
| `script_recorder.dart` | 脚本录制服务，通过 AccessibilityService 捕获用户操作 |
| `script_executor.dart` | 脚本执行服务，回放录制的操作 |
| `scheduler.dart` | 定时任务调度服务 |

### 动作类型定义

**lib/core/models/action.dart**

```dart
enum ActionType { tap, swipe, longPress, wait, condition, loop }
```

所有动作通过 AccessibilityService 在 Android 原生层执行，坐标使用归一化形式（0-1 范围）以适配不同屏幕尺寸。

### Hive 存储结构

修改数据模型后需要重新生成适配器：
```bash
dart run build_runner build --delete-conflicting-outputs
```

**现有 typeId 分配**（避免冲突）：
- typeId: 0 - Script
- typeId: 1 - ScheduledTask
- typeId: 2 - ScriptAction (推测，检查实际定义)

### Android 服务配置

**关键文件**：
- `android/app/src/main/AndroidManifest.xml` - 权限和服务声明
- `android/app/src/main/res/xml/accessibility_service_config.xml` - 无障碍服务配置
- `android/app/src/main/java/com/keyhelp/app/service/KeyHelpAccessibilityService.java` - 主无障碍服务实现

**核心权限**：
- `ACCESSIBILITY_SERVICE` - 触控模拟核心权限
- `SYSTEM_ALERT_WINDOW` - 悬浮窗权限
- `FOREGROUND_SERVICE` - 前台服务权限

## 权限处理流程

应用启动时会检查无障碍服务是否启用：
1. 未启用时显示警告
2. 用户点击"去设置"按钮跳转到系统无障碍设置
3. 用户手动启用 KeyHelp 无障碍服务
4. 应用检测到服务启用后图标变绿，功能可用

## 文件大小限制

- Dart 文件建议不超过 300 行
- Java 文件建议不超过 400 行
- 当文件夹内文件超过 8 个时，需要规划子文件夹

## Android 原生服务调试

查看无障碍服务日志：
```bash
adb logcat | grep KeyHelp
```

## 特殊说明

1. **跨 App 触控**：应用使用系统级无障碍服务，可以录制和执行跨应用的操作
2. **屏幕适配**：所有触控坐标使用相对坐标（0-1 范围），执行时按当前屏幕尺寸映射
3. **流程控制**：支持条件判断和循环，增强脚本灵活性