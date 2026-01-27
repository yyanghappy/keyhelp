# 任务完成后应执行的操作

## 代码质量检查
1. 运行 Flutter 静态分析：
   ```bash
   flutter analyze
   ```

2. 检查代码格式：
   ```bash
   flutter format .
   ```

## 测试
1. 运行单元测试（如果有）：
   ```bash
   flutter test
   ```

2. 手动测试功能：
   - 使用 `./scripts/run.sh` 运行应用
   - 验证修改的功能是否正常工作
   - 检查无障碍服务是否正常工作

## 代码生成
如果修改了 Hive 数据模型，需要重新生成适配器：
```bash
dart run build_runner build --delete-conflicting-outputs
```

## 文档更新
1. 如果修改了功能，更新相关文档
2. 如果添加了新功能，在 README.md 中添加说明

## Git 提交
1. 检查修改的文件：
   ```bash
   git status
   ```

2. 添加修改的文件：
   ```bash
   git add .
   ```

3. 提交更改：
   ```bash
   git commit -m "描述你的更改"
   ```

## 构建验证
1. 构建 Release 版本以确保没有编译错误：
   ```bash
   ./scripts/build.sh
   ```