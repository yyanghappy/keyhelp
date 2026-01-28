import 'package:flutter/material.dart';
import 'dart:async';
import 'package:keyhelp/core/models/script.dart';
import 'package:keyhelp/core/repositories/script_repository.dart';
import 'package:keyhelp/core/services/script_executor.dart';
import 'package:keyhelp/shared/services/float_window_service.dart';

/// 全局脚本执行管理器
/// 用于处理来自浮窗的脚本执行事件
class GlobalScriptExecutor {
  static final GlobalScriptExecutor _instance =
      GlobalScriptExecutor._internal();
  factory GlobalScriptExecutor() => _instance;
  GlobalScriptExecutor._internal() {
    _setupEventListeners();
  }

  final ScriptExecutor _executor = ScriptExecutor();
  StreamSubscription<String>? _executeSubscription;
  StreamSubscription<void>? _pauseSubscription;
  StreamSubscription<void>? _stopSubscription;
  StreamSubscription<void>? _playSubscription;

  Script? _currentScript;
  bool _isScriptExecuting = false; // 用于跟踪脚本是否正在执行
  DateTime _lastExecuteTime = DateTime.now(); // 用于防抖处理
  static const int _executeDebounceMs = 1000; // 1秒防抖时间

  void _setupEventListeners() {
    // 监听脚本执行事件
    _executeSubscription = FloatWindowService.executeScriptStream.listen(
      (scriptId) {
        print('=== 全局脚本执行管理器接收到执行事件 ===');
        print('脚本ID: $scriptId');
        // 添加防抖处理，避免重复执行
        _debounceExecuteScript(scriptId);
      },
      onError: (error) {
        print('脚本执行事件监听错误: $error');
      },
    );

    // 监听暂停事件
    _pauseSubscription = FloatWindowService.pauseStream.listen((_) {
      print('=== 全局脚本执行管理器接收到暂停事件 ===');
      _pauseExecution();
    });

    // 监听停止事件
    _stopSubscription = FloatWindowService.stopStream.listen((_) {
      print('=== 全局脚本执行管理器接收到停止事件 ===');
      stopExecution();
    });

    // 监听播放事件（恢复执行）
    _playSubscription = FloatWindowService.playStream.listen((_) {
      print('=== 全局脚本执行管理器接收到播放事件 ===');
      _resumeExecution();
    });
  }

  /// 执行脚本
  Future<void> _executeScript(String scriptId) async {
    // 检查是否已经有脚本在执行
    if (_isScriptExecuting) {
      print('脚本正在执行中，跳过重复执行请求');
      return;
    }

    try {
      print('加载脚本: $scriptId');
      final script =
          await ScriptRepository.instance.getScript(scriptId);

      if (script == null) {
        print('脚本不存在: $scriptId');
        await FloatWindowService.updateExecutionState(
          state: '脚本不存在',
          isPlaying: false,
          isPaused: false,
        );
        return;
      }

      // 设置当前脚本信息
      await FloatWindowService.setCurrentScript(
        scriptId: script.id,
        scriptName: script.name,
      );

      _currentScript = script;
      _isScriptExecuting = true; // 标记脚本开始执行
      print('开始执行脚本: ${script.name}');
      print('脚本包含 ${script.actions.length} 个动作');

      // 更新浮窗状态为"执行中"
      await FloatWindowService.updateExecutionState(
        state: '执行中',
        isPlaying: true,
        isPaused: false,
      );

      print('准备执行脚本...');
      // 执行脚本
      await _executor.executeScript(script);
      print('脚本执行方法返回');

      print('脚本执行完成');
      print('准备更新浮窗状态为完成...');
    } catch (e) {
      print('脚本执行失败: $e');
      print('错误类型: ${e.runtimeType}');
      print('错误详情: $e');
      rethrow; // 重新抛出异常，让外层finally处理状态更新
    } finally {
      print('进入finally块，准备更新浮窗状态');
      // 确保无论脚本执行成功还是失败，都更新浮窗状态
      try {
        if (_isScriptExecuting) {
          // 脚本正常完成
          print('脚本执行完成，更新状态为完成');
          await FloatWindowService.updateExecutionState(
            state: '完成',
            isPlaying: false,
            isPaused: false,
          );
        } else {
          // 脚本被中断
          print('脚本被中断，更新状态为已停止');
          await FloatWindowService.updateExecutionState(
            state: '已停止',
            isPlaying: false,
            isPaused: false,
          );
        }
        _isScriptExecuting = false; // 重置执行标志
        print('浮窗状态更新完成');
      } catch (stateUpdateError) {
        print('更新浮窗状态失败: $stateUpdateError');
        print('错误类型: ${stateUpdateError.runtimeType}');
        _isScriptExecuting = false; // 即使出错也要重置标志
      }
    }
  }

  /// 暂停脚本执行
  void _pauseExecution() {
    print('暂停脚本执行');
    _executor.pauseExecution();
    FloatWindowService.updateExecutionState(
      state: '已暂停',
      isPlaying: false,
      isPaused: true,
    );
  }

  /// 恢复脚本执行
  Future<void> _resumeExecution() async {
    if (_currentScript == null) {
      print('没有正在执行的脚本');
      return;
    }

    // 检查是否已经有脚本在执行
    if (_isScriptExecuting) {
      print('脚本正在执行中，跳过重复执行请求');
      return;
    }

    print('恢复执行脚本: ${_currentScript!.name}');

    try {
      _isScriptExecuting = true; // 标记脚本开始执行

      // 更新浮窗状态为"执行中"
      await FloatWindowService.updateExecutionState(
        state: '执行中',
        isPlaying: true,
        isPaused: false,
      );

      print('准备执行脚本...');
      // ScriptExecutor目前不支持恢复执行，这里需要重新执行
      // 等待ScriptExecutor支持恢复功能
      await _executor.executeScript(_currentScript!);
      print('脚本执行方法返回');

      print('脚本执行完成');
      print('准备更新浮窗状态为完成...');
    } catch (e) {
      print('脚本执行失败: $e');
      print('错误类型: ${e.runtimeType}');
      print('错误详情: $e');
      rethrow; // 重新抛出异常，让外层finally处理状态更新
    } finally {
      print('进入finally块，准备更新浮窗状态');
      // 确保无论脚本执行成功还是失败，都更新浮窗状态
      try {
        if (_isScriptExecuting) {
          // 脚本正常完成
          print('脚本执行完成，更新状态为完成');
          await FloatWindowService.updateExecutionState(
            state: '完成',
            isPlaying: false,
            isPaused: false,
          );
        } else {
          // 脚本被中断
          print('脚本被中断，更新状态为已停止');
          await FloatWindowService.updateExecutionState(
            state: '已停止',
            isPlaying: false,
            isPaused: false,
          );
        }
        _isScriptExecuting = false; // 重置执行标志
        print('浮窗状态更新完成');
      } catch (stateUpdateError) {
        print('更新浮窗状态失败: $stateUpdateError');
        print('错误类型: ${stateUpdateError.runtimeType}');
        _isScriptExecuting = false; // 即使出错也要重置标志
      }
    }
  }

  /// 停止脚本执行
  void stopExecution() {
    print('停止脚本执行');
    _executor.stopExecution();
    FloatWindowService.updateExecutionState(
      state: '已停止',
      isPlaying: false,
      isPaused: false,
    );
  }

  void dispose() {
    _executeSubscription?.cancel();
    _pauseSubscription?.cancel();
    _stopSubscription?.cancel();
    _playSubscription?.cancel();
  }

  /// 防抖处理脚本执行请求
  void _debounceExecuteScript(String scriptId) {
    final now = DateTime.now();
    final diff = now.difference(_lastExecuteTime).inMilliseconds;

    if (diff > _executeDebounceMs) {
      // 超过防抖时间，执行脚本
      _lastExecuteTime = now;
      _executeScript(scriptId);
    } else {
      // 在防抖时间内，忽略重复请求
      print('忽略重复的脚本执行请求，距离上次执行: ${diff}ms');
    }
  }
}
