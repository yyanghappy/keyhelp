import 'package:flutter/material.dart';
import 'package:keyhelp/core/services/game_recorder_service.dart';
import 'package:keyhelp/shared/services/float_window_service.dart';
import 'package:keyhelp/core/models/script.dart';

/// 全局录制管理器
/// 用于处理来自浮窗的录制相关事件，无论FloatWindowPage是否在前台
class GlobalRecordingManager {
  static final GlobalRecordingManager _instance = GlobalRecordingManager._internal();
  factory GlobalRecordingManager() => _instance;
  GlobalRecordingManager._internal() {
    _setupEventListeners();
  }

  final GameRecorderService _recorder = GameRecorderService();
  StreamSubscription<void>? _saveSubscription;

  void _setupEventListeners() {
    // 监听保存事件
    _saveSubscription = FloatWindowService.saveStream.listen((_) {
      print('=== 全局录制管理器接收到保存事件 ===');
      _handleSave();
    });
  }

  Future<void> _handleSave() async {
    print('=== 全局录制管理器开始处理保存 ===');
    print('当前录制动作数量: ${_recorder.actionCount}');

    if (_recorder.actionCount == 0) {
      print('没有录制任何动作');
      // 显示提示信息（通过通知或其他方式）
      return;
    }

    // 这里我们需要一个上下文来显示对话框
    // 由于这是全局服务，我们无法直接显示对话框
    // 可以考虑使用其他方式，如通知或直接保存
    print('需要上下文来显示保存对话框');
  }

  void dispose() {
    _saveSubscription?.cancel();
  }
}