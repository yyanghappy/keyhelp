# 建议的开发命令

## 常用开发命令
所有开发操作必须通过 `scripts/` 目录下的脚本执行：

### 开发模式运行（带日志输出到 logs/ 目录）
```bash
./scripts/run.sh
```

### 构建 Release APK
```bash
./scripts/build.sh
```

### 测试无障碍服务
```bash
./scripts/test_accessibility.sh
```

### 安装 Flutter SDK（首次使用时）
```bash
./scripts/install_flutter.sh
```

## 日志查看
所有运行日志输出到 `logs/` 目录，文件名格式为 `keyhelp_YYYYMMDD_HHMMSS.log`

查看实时日志：
```bash
tail -f logs/keyhelp_*.log
```

## Android 原生服务调试
查看无障碍服务日志：
```bash
adb logcat | grep KeyHelp
```

## 代码生成
修改数据模型后需要重新生成适配器：
```bash
dart run build_runner build --delete-conflicting-outputs
```