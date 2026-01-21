import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:keyhelp/core/models/action.dart';
import 'package:keyhelp/core/models/script.dart';
import 'package:keyhelp/core/models/execution_state.dart';
import 'accessibility_service.dart';

class ScriptExecutor {
  final AccessibilityService _accessibilityService;
  bool _isExecuting = false;
  int _currentIndex = 0;
  final StreamController<ExecutionState> _stateController =
      StreamController.broadcast();
  DateTime? _executionStartTime;

  ScriptExecutor() : _accessibilityService = AccessibilityService();

  bool get isExecuting => _isExecuting;
  int get currentIndex => _currentIndex;
  Stream<ExecutionState> get stateStream => _stateController.stream;

  Future<void> executeScript(Script script) async {
    if (_isExecuting) {
      debugPrint('脚本正在执行中');
      return;
    }

    _isExecuting = true;
    _currentIndex = 0;
    _executionStartTime = DateTime.now();
    final List<ExecutionLog> logs = [];

    try {
      _stateController.add(ExecutionState(
        status: ExecutionStatus.running,
        currentIndex: 0,
        totalActions: script.actions.length,
        logs: logs,
      ));

      debugPrint('========================================');
      debugPrint('开始执行脚本: ${script.name}');
      debugPrint('脚本包含 ${script.actions.length} 个动作');
      debugPrint('========================================');

      for (int i = 0; i < script.actions.length; i++) {
        if (!_isExecuting) break;

        _currentIndex = i;
        final action = script.actions[i];

        debugPrint('--- 动作 ${i + 1}/${script.actions.length} ---');
        debugPrint('类型: ${action.type}');
        debugPrint('延迟: ${action.delayMs ?? 0}ms');

        _stateController.add(ExecutionState(
          status: ExecutionStatus.running,
          currentIndex: i + 1,
          totalActions: script.actions.length,
          currentAction: action,
          elapsedTime: DateTime.now().difference(_executionStartTime!),
          logs: List.from(logs),
        ));

        if (action.delayMs != null && action.delayMs! > 0) {
          debugPrint('⏳ 等待 ${action.delayMs}ms...');
          await Future.delayed(Duration(milliseconds: action.delayMs!));
        }

        switch (action.type) {
          case ActionType.tap:
            debugPrint('点击坐标: (${action.x}, ${action.y})');
            await _executeAction(action);
            logs.add(ExecutionLog(
              timestamp: DateTime.now(),
              actionIndex: i,
              action: action,
              message: '点击 (${action.x}, ${action.y})',
              isSuccess: true,
            ));
            break;
          case ActionType.swipe:
            debugPrint(
                '滑动: (${action.x}, ${action.y}) -> (${action.endX}, ${action.endY})');
            await _executeAction(action);
            logs.add(ExecutionLog(
              timestamp: DateTime.now(),
              actionIndex: i,
              action: action,
              message:
                  '滑动 (${action.x}, ${action.y}) -> (${action.endX}, ${action.endY})',
              isSuccess: true,
            ));
            break;
          case ActionType.longPress:
            debugPrint('长按坐标: (${action.x}, ${action.y})');
            await _executeAction(action);
            logs.add(ExecutionLog(
              timestamp: DateTime.now(),
              actionIndex: i,
              action: action,
              message: '长按 (${action.x}, ${action.y})',
              isSuccess: true,
            ));
            break;
          case ActionType.wait:
            debugPrint('等待: ${action.delayMs}ms');
            await _executeAction(action);
            logs.add(ExecutionLog(
              timestamp: DateTime.now(),
              actionIndex: i,
              action: action,
              message: '等待 ${action.delayMs}ms',
              isSuccess: true,
            ));
            break;
          case ActionType.condition:
            debugPrint('条件判断: ${action.condition}');
            logs.add(ExecutionLog(
              timestamp: DateTime.now(),
              actionIndex: i,
              action: action,
              message: '条件判断: ${action.condition}',
              isSuccess: true,
            ));
            break;
          case ActionType.loop:
            debugPrint('循环: ${action.loopCount}次');
            logs.add(ExecutionLog(
              timestamp: DateTime.now(),
              actionIndex: i,
              action: action,
              message: '循环 ${action.loopCount}次',
              isSuccess: true,
            ));
            break;
        }
      }

      debugPrint('========================================');
      debugPrint('脚本执行完成: ${script.name}');
      debugPrint('========================================');

      _stateController.add(ExecutionState(
        status: ExecutionStatus.completed,
        currentIndex: script.actions.length,
        totalActions: script.actions.length,
        elapsedTime: DateTime.now().difference(_executionStartTime!),
        logs: List.from(logs),
      ));
    } catch (e) {
      debugPrint('❌ 脚本执行失败: $e');
      debugPrint('❌ 错误类型: ${e.runtimeType}');
      debugPrint('❌ 堆栈信息: ${e.toString()}');

      _stateController.add(ExecutionState(
        status: ExecutionStatus.failed,
        currentIndex: _currentIndex,
        totalActions: script.actions.length,
        errorMessage: e.toString(),
        elapsedTime: _executionStartTime != null
            ? DateTime.now().difference(_executionStartTime!)
            : Duration.zero,
        logs: List.from(logs),
      ));
    } finally {
      _isExecuting = false;
      _currentIndex = 0;
      debugPrint('执行状态: 已停止');
    }
  }

  Future<void> _executeAction(ScriptAction action) async {
    switch (action.type) {
      case ActionType.tap:
        await _accessibilityService.executeAction(action);
        break;
      case ActionType.swipe:
        await _accessibilityService.executeAction(action);
        break;
      case ActionType.longPress:
        await _accessibilityService.executeAction(action);
        break;
      case ActionType.wait:
        await Future.delayed(Duration(milliseconds: action.delayMs ?? 500));
        break;
      case ActionType.loop:
        if (action.loopCount != null && action.loopCount! > 0) {
          debugPrint('循环执行: ${action.loopCount}次');
        }
        break;
      case ActionType.condition:
        debugPrint('条件判断: ${action.condition}');
        break;
    }
  }

  void stopExecution() {
    if (_isExecuting) {
      _isExecuting = false;
      debugPrint('停止脚本执行');
    }
  }

  void pauseExecution() {
    if (_isExecuting) {
      _isExecuting = false;
      debugPrint('暂停脚本执行');
    }
  }

  void resumeExecution(Script script) async {
    if (!_isExecuting && _currentIndex < script.actions.length) {
      _isExecuting = true;

      for (int i = _currentIndex; i < script.actions.length; i++) {
        if (!_isExecuting) break;

        _currentIndex = i;
        final action = script.actions[i];

        if (action.delayMs != null && action.delayMs! > 0) {
          await Future.delayed(Duration(milliseconds: action.delayMs!));
        }

        await _executeAction(action);
      }
    }
  }

  void dispose() {
    _stateController.close();
  }
}
