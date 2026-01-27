# 浮窗功能实现

## 核心组件

### FloatWindowService (Flutter层)
位于 `lib/shared/services/float_window_service.dart`

负责与Android原生层通信，通过MethodChannel和EventChannel实现：
1. 浮窗的显示/隐藏
2. 权限检查和申请
3. 脚本状态更新
4. 事件监听（关闭、录制、保存、播放、暂停、停止等）

### FloatWindowService (Android层)
位于 `android/app/src/main/java/com/keyhelp/app/service/FloatWindowService.java`

负责创建和管理Android系统级浮窗：
1. 创建浮窗布局
2. 处理浮窗拖动
3. 管理浮窗按钮事件
4. 保存浮窗位置
5. 与Flutter层通信

### GlobalRecordingManager (全局录制管理器)
位于 `lib/core/services/global_recording_manager.dart`

负责处理来自浮窗的录制相关事件，无论FloatWindowPage是否在前台：
1. 监听录制和保存事件
2. 控制GameRecorderService的录制流程
3. 更新浮窗状态

### GameRecorderService (游戏录制服务)
位于 `lib/core/services/game_recorder_service.dart`

负责具体的录制功能：
1. 开始/停止录制
2. 监听无障碍事件和平台事件
3. 记录点击、滑动、长按等动作
4. 保存脚本到本地存储

## 工作流程

1. 用户在浮窗设置页面启用浮窗功能
2. 检查并申请浮窗权限
3. 显示Android系统级浮窗
4. 用户通过浮窗进行录制操作
5. GlobalRecordingManager接收录制事件
6. GameRecorderService处理具体的录制逻辑
7. 用户通过浮窗保存录制的脚本
8. 脚本保存到Hive本地存储

## 关键特性

1. **跨应用录制**：通过系统级浮窗实现跨应用操作
2. **全局事件处理**：即使FloatWindowPage不在前台也能处理录制事件
3. **状态同步**：Flutter层和Android层状态实时同步
4. **坐标归一化**：使用0-1范围的坐标系统适配不同屏幕尺寸