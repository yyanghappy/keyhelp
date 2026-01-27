# Android 原生服务集成

## 核心 Android 服务
位于 `android/app/src/main/java/com/keyhelp/app/service/KeyHelpAccessibilityService.java`

这是一个 Android AccessibilityService，负责：
1. 监听系统级别的触控事件
2. 执行触控模拟（点击、滑动、长按）
3. 管理录制过程
4. 提供应用信息（当前包名、Activity名）

### 主要功能方法
- `performClick(float x, float y)`: 执行点击操作
- `performSwipe(float startX, float startY, float endX, float endY, int duration)`: 执行滑动操作
- `performLongPress(float x, float y, int duration)`: 执行长按操作
- `startRecording()`: 开始录制
- `stopRecording()`: 停止录制
- `isRecording()`: 检查录制状态

## Flutter 与 Android 通信
通过 MethodChannel 实现双向通信：

### MethodChannel 方法
位于 `lib/shared/utils/accessibility_platform_service.dart`

调用 Android 方法：
- `isServiceEnabled()`: 检查服务是否启用
- `openAccessibilitySettings()`: 打开无障碍设置
- `performClick()`: 执行点击
- `performSwipe()`: 执行滑动
- `performLongPress()`: 执行长按
- `startRecording()`: 开始录制
- `stopRecording()`: 停止录制
- `isRecording()`: 检查录制状态
- `getCurrentPackageName()`: 获取当前包名
- `getCurrentActivityName()`: 获取当前Activity名

### EventChannel 事件
接收来自 Android 的事件：
- 无障碍事件流，包含事件类型、包名、坐标等信息

## 坐标系统
所有坐标使用归一化形式（0-1 范围），在执行时按当前屏幕尺寸映射，以适配不同屏幕尺寸。