# 核心服务说明

## AccessibilityService (无障碍服务)
位于 `lib/core/services/accessibility_service.dart`

这是应用的核心服务，负责：
1. 与 Android 原生无障碍服务通信
2. 处理触控监听和模拟
3. 管理录制和执行状态
4. 提供事件流和状态流

主要功能：
- 检查无障碍服务状态
- 打开无障碍设置
- 开始/停止录制
- 执行点击、滑动、长按等操作
- 管理录制的动作列表

## ScriptRecorder (脚本录制服务)
位于 `lib/core/services/script_recorder.dart`

负责：
1. 管理录制过程中的动作
2. 记录动作的时间间隔
3. 创建最终的脚本对象

主要功能：
- 开始/停止录制
- 记录各种类型的动作（点击、滑动、长按等）
- 添加等待和循环动作
- 创建脚本对象

## ScriptExecutor (脚本执行服务)
需要查找具体实现文件。

## Scheduler (定时任务调度服务)
需要查找具体实现文件。

## GlobalRecordingManager (全局录制管理器)
需要查找具体实现文件。

## 数据模型

### ActionType (动作类型)
定义在 `lib/core/models/action.dart`
```dart
enum ActionType { tap, swipe, longPress, wait, condition, loop }
```

### ScriptAction (脚本动作)
定义在 `lib/core/models/action.dart`
包含动作类型和相关参数（坐标、延迟时间等）

### Script (脚本)
定义在 `lib/core/models/script.dart`
包含脚本的元数据和动作列表