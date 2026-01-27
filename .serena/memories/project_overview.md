# KeyHelp 项目概述

## 项目目的
KeyHelp 是一个基于 Flutter 的安卓轻量化自动化工具，通过 Android AccessibilityService 实现脚本录制与回放功能。它是一个个人自用的安卓自动化工具，支持脚本录制、定时执行和流程控制。

## 核心功能
1. 无障碍服务：基于Android AccessibilityService实现真实的触控监听和模拟
2. 脚本录制：录制点击、滑动、长按等操作
3. 脚本执行：精确回放录制的操作
4. 定时任务：设置定时自动执行脚本
5. 流程控制：支持条件和循环逻辑
6. 极简设计：无冗余功能，专注核心需求

## 技术栈
- 框架：Flutter 3.24+ / Dart 3.5+
- 状态管理：Riverpod 2.6+
- 本地存储：Hive 2.2+
- UI框架：Material Design 3
- 原生功能：Android AccessibilityService

## 项目结构
```
keyhelp/
├── lib/                    # 源代码
│   ├── core/              # 核心功能
│   │   ├── services/      # 服务层（录制、执行、调度）
│   │   ├── models/        # 数据模型
│   │   └── repositories/  # 数据仓库
│   ├── features/          # 功能页面
│   └── config/            # 配置文件
├── scripts/               # 运行脚本
├── docs/                  # 文档
└── android/              # Android配置
```