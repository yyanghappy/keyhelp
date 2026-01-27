# 代码风格和约定

## 文件大小限制
- Dart 文件建议不超过 300 行
- Java 文件建议不超过 400 行
- 当文件夹内文件超过 8 个时，需要规划子文件夹

## 代码架构原则
1. 僵化 (Rigidity): 系统难以变更，任何微小的改动都会引发一连串的连锁修改。
2. 冗余 (Redundancy): 同样的代码逻辑在多处重复出现，导致维护困难且容易产生不一致。
3. 循环依赖 (Circular Dependency): 两个或多个模块互相纠缠，形成无法解耦的"死结"，导致难以测试与复用。
4. 脆弱性 (Fragility): 对代码一处的修改，导致了系统中其他看似无关部分功能的意外损坏。
5. 晦涩性 (Obscurity): 代码意图不明，结构混乱，导致阅读者难以理解其功能和设计。
6. 数据泥团 (Data Clump): 多个数据项总是一起出现在不同方法的参数中，暗示着它们应该被组合成一个独立的对象。
7. 不必要的复杂性 (Needless Complexity): 用"杀牛刀"去解决"杀鸡"的问题，过度设计使系统变得臃肿且难以理解。

## 技术栈规范
- Flutter 3.24+ / Dart 3.5+
- 状态管理：Riverpod 2.6+
- 本地存储：Hive 2.2+
- 原生服务：Android AccessibilityService

## 命名约定
- 使用有意义的变量和函数名
- 遵循 Dart 和 Flutter 的命名规范
- 类名使用 PascalCase
- 函数和变量名使用 camelCase
- 常量使用 UPPER_SNAKE_CASE

## 数据结构
- 数据结构尽可能全部定义成强类型
- 使用 Hive 进行本地数据存储
- 为 Hive 模型生成适配器

## 无障碍服务集成
- 通过 MethodChannel 实现 Flutter 与 Android 原生服务的通信
- 使用 AccessibilityService 实现触控监听和模拟
- 坐标使用归一化形式（0-1 范围）以适配不同屏幕尺寸