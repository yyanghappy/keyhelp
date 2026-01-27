# 项目架构总结

## 整体架构

KeyHelp采用分层架构设计，分为以下几个层次：

### 1. 表示层 (Presentation Layer)
- 位置：`lib/features/`
- 职责：UI界面和用户交互
- 组件：
  - HomePage: 主页，提供功能入口
  - RecordPage: 脚本录制页面
  - ScriptsPage: 脚本列表和管理页面
  - SchedulePage: 定时任务管理页面
  - FloatWindowPage: 浮窗设置页面
  - ExecutePage: 脚本执行页面

### 2. 共享层 (Shared Layer)
- 位置：`lib/shared/`
- 职责：跨功能的组件和服务
- 组件：
  - Widgets: 可复用的UI组件（TouchRecorder、RecordingOverlay等）
  - Services: 跨平台服务（FloatWindowService）
  - Utils: 工具类（AccessibilityPlatformService）

### 3. 核心业务层 (Core Business Layer)
- 位置：`lib/core/`
- 职责：核心业务逻辑和服务
- 组件：
  - Services: 核心服务（AccessibilityService、ScriptRecorder、ScriptExecutor、Scheduler、GameRecorderService、GlobalRecordingManager）
  - Models: 数据模型（Script、ScriptAction、ScheduledTask、ExecutionState）
  - Repositories: 数据访问层（ScriptRepository、TaskRepository）

### 4. 配置层 (Configuration Layer)
- 位置：`lib/config/`
- 职责：应用配置和常量
- 组件：
  - Constants: 应用常量
  - Theme: 应用主题

## 数据流向

```
用户操作 → Features/UI → Core Services → Repositories → Hive存储
                ↑              ↓
           Riverpod状态管理    ↓
                ↑              ↓
           Android原生服务 ← Platform Services
```

## 核心服务关系

### AccessibilityService (核心无障碍服务)
- 作为单例存在
- 与Android原生AccessibilityService通信
- 提供触控模拟和事件监听功能
- 被ScriptExecutor和GameRecorderService使用

### GameRecorderService (游戏录制服务)
- 处理具体的录制逻辑
- 监听无障碍事件并记录动作
- 与AccessibilityService协作

### GlobalRecordingManager (全局录制管理器)
- 处理来自浮窗的录制事件
- 控制GameRecorderService的录制流程

### ScriptExecutor (脚本执行服务)
- 执行录制的脚本
- 与AccessibilityService协作执行触控动作

### TaskScheduler (定时任务调度器)
- 管理和执行定时任务
- 与本地通知集成

## 技术特点

1. **状态管理**：使用Riverpod进行状态管理
2. **本地存储**：使用Hive进行数据持久化
3. **跨平台通信**：使用MethodChannel和EventChannel与Android原生层通信
4. **系统级功能**：通过Android AccessibilityService和系统浮窗实现核心功能
5. **事件驱动**：大量使用Stream进行事件处理