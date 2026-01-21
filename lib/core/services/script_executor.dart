import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:keyhelp/core/models/action.dart';
import 'package:keyhelp/core/models/script.dart';
import 'accessibility_service.dart';

class ScriptExecutor {
  final AccessibilityService _accessibilityService;
  bool _isExecuting = false;
  int _currentIndex = 0;

  ScriptExecutor() : _accessibilityService = AccessibilityService();

  bool get isExecuting => _isExecuting;
  int get currentIndex => _currentIndex;

  Future<void> executeScript(Script script) async {
    if (_isExecuting) {
      debugPrint('脚本正在执行中');
      return;
    }

    _isExecuting = true;
    _currentIndex = 0;

    try {
      print('========================================');
      print('开始执行脚本: ${script.name}');
      print('脚本包含 ${script.actions.length} 个动作');
      print('========================================');

      for (int i = 0; i < script.actions.length; i++) {
        if (!_isExecuting) break;

        _currentIndex = i;
        final action = script.actions[i];

        print('--- 动作 ${i + 1}/${script.actions.length} ---');
        print('类型: ${action.type}');
        print('延迟: ${action.delayMs ?? 0}ms');

        if (action.delayMs != null && action.delayMs! > 0) {
          print('⏳ 等待 ${action.delayMs}ms...');
          await Future.delayed(Duration(milliseconds: action.delayMs!));
        }

        switch (action.type) {
          case ActionType.tap:
            print('点击坐标: (${action.x}, ${action.y})');
            await _executeAction(action);
            break;
          case ActionType.swipe:
            print(
                '滑动: (${action.x}, ${action.y}) -> (${action.endX}, ${action.endY})');
            await _executeAction(action);
            break;
          case ActionType.longPress:
            print('长按坐标: (${action.x}, ${action.y})');
            await _executeAction(action);
            break;
          case ActionType.wait:
            print('等待: ${action.delayMs}ms');
            await _executeAction(action);
            break;
          case ActionType.condition:
            print('条件判断: ${action.condition}');
            break;
          case ActionType.loop:
            print('循环: ${action.loopCount}次');
            break;
        }
      }

      print('========================================');
      print('脚本执行完成: ${script.name}');
      print('========================================');
    } catch (e) {
      print('❌ 脚本执行失败: $e');
      print('❌ 错误类型: ${e.runtimeType}');
      print('❌ 堆栈信息: ${e.toString()}');
    } finally {
      _isExecuting = false;
      _currentIndex = 0;
      print('执行状态: 已停止');
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
}
