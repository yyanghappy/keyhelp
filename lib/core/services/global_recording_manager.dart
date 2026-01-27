import 'package:flutter/material.dart';
import 'dart:async';
import 'package:keyhelp/core/services/game_recorder_service.dart';
import 'package:keyhelp/shared/services/float_window_service.dart';
import 'package:keyhelp/core/models/script.dart';
import 'package:keyhelp/core/repositories/script_repository.dart';

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
      // 通过浮窗状态更新来提示用户
      FloatWindowService.updateRecordingState(
        state: '无动作',
        isRecording: false,
      );
      return;
    }

    // 自动生成脚本名称并直接保存
    final scriptName = '脚本_${DateTime.now().millisecondsSinceEpoch}';
    print('自动生成脚本名称: $scriptName');

    final script = await _recorder.saveScript(scriptName);
    if (script != null) {
      print('脚本保存成功: ${script.name}');
      // 保存后清空录制
      _recorder.clearRecording();
      // 更新浮窗状态
      FloatWindowService.updateRecordingState(
        state: '已保存',
        isRecording: false,
      );
    } else {
      print('脚本保存失败');
      FloatWindowService.updateRecordingState(
        state: '保存失败',
        isRecording: false,
      );
    }
  }

  void dispose() {
    _saveSubscription?.cancel();
  }
}