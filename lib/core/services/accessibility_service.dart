import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:keyhelp/core/models/action.dart';
import 'package:keyhelp/shared/utils/accessibility_platform_service.dart';

class AccessibilityService {
  static final AccessibilityService _instance =
      AccessibilityService._internal();
  factory AccessibilityService() => _instance;
  AccessibilityService._internal() {
    AccessibilityPlatformService.initialize();
  }

  bool _isRecording = false;
  bool _isExecuting = false;
  final List<ScriptAction> _recordedActions = [];
  final _actionStreamController = StreamController<ScriptAction>.broadcast();
  final _statusStreamController = StreamController<String>.broadcast();
  bool _isServiceEnabled = false;

  Stream<ScriptAction> get actionStream => _actionStreamController.stream;
  Stream<String> get statusStream => _statusStreamController.stream;
  bool get isRecording => _isRecording;
  bool get isExecuting => _isExecuting;
  bool get isServiceEnabled => _isServiceEnabled;
  List<ScriptAction> get recordedActions => List.unmodifiable(_recordedActions);

  Future<void> checkServiceStatus() async {
    _isServiceEnabled = await AccessibilityPlatformService.isServiceEnabled();
    debugPrint('无障碍服务状态: $_isServiceEnabled');
  }

  Future<void> openAccessibilitySettings() async {
    await AccessibilityPlatformService.openAccessibilitySettings();
  }

  void startRecording() {
    _isRecording = true;
    _recordedActions.clear();
    _statusStreamController.add('recording');
    debugPrint('开始录制');
  }

  void stopRecording() {
    _isRecording = false;
    _statusStreamController.add('idle');
    debugPrint('停止录制');
  }

  void recordTap(double x, double y) {
    if (!_isRecording) return;

    final action = ScriptAction(
      type: ActionType.tap,
      x: x,
      y: y,
    );
    _recordedActions.add(action);
    _actionStreamController.add(action);
    debugPrint('录制点击: ($x, $y)');
  }

  void recordSwipe(double startX, double startY, double endX, double endY) {
    if (!_isRecording) return;

    final action = ScriptAction(
      type: ActionType.swipe,
      x: startX,
      y: startY,
      endX: endX,
      endY: endY,
    );
    _recordedActions.add(action);
    _actionStreamController.add(action);
    debugPrint('录制滑动: ($startX, $startY) -> ($endX, $endY)');
  }

  void recordLongPress(double x, double y) {
    if (!_isRecording) return;

    final action = ScriptAction(
      type: ActionType.longPress,
      x: x,
      y: y,
    );
    _recordedActions.add(action);
    _actionStreamController.add(action);
    debugPrint('录制长按: ($x, $y)');
  }

  void clearRecording() {
    _recordedActions.clear();
    debugPrint('清空录制');
  }

  Future<void> executeAction(ScriptAction action) async {
    _isExecuting = true;

    try {
      switch (action.type) {
        case ActionType.tap:
          await _performTap(action.x!, action.y!);
          break;
        case ActionType.swipe:
          await _performSwipe(action.x!, action.y!, action.endX!, action.endY!);
          break;
        case ActionType.longPress:
          await _performLongPress(action.x!, action.y!);
          break;
        case ActionType.wait:
          await Future.delayed(Duration(milliseconds: action.delayMs ?? 500));
          break;
        case ActionType.condition:
        case ActionType.loop:
          break;
      }
    } catch (e) {
      debugPrint('执行动作失败: $e');
    }
  }

  Future<void> _performTap(double x, double y) async {
    if (!_isServiceEnabled) {
      debugPrint('无障碍服务未启用，无法执行点击');
      return;
    }

    debugPrint('执行点击: ($x, $y)');
    final success = await AccessibilityPlatformService.performClick(x, y);
    if (!success) {
      debugPrint('点击执行失败');
    }
    await Future.delayed(const Duration(milliseconds: 100));
  }

  Future<void> _performSwipe(
      double startX, double startY, double endX, double endY) async {
    if (!_isServiceEnabled) {
      debugPrint('无障碍服务未启用，无法执行滑动');
      return;
    }

    debugPrint('执行滑动: ($startX, $startY) -> ($endX, $endY)');
    final success = await AccessibilityPlatformService.performSwipe(
        startX, startY, endX, endY);
    if (!success) {
      debugPrint('滑动执行失败');
    }
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _performLongPress(double x, double y) async {
    if (!_isServiceEnabled) {
      debugPrint('无障碍服务未启用，无法执行长按');
      return;
    }

    debugPrint('执行长按: ($x, $y)');
    final success = await AccessibilityPlatformService.performLongPress(x, y);
    if (!success) {
      debugPrint('长按执行失败');
    }
    await Future.delayed(const Duration(milliseconds: 800));
  }

  void stopExecution() {
    _isExecuting = false;
    debugPrint('停止执行');
  }

  void dispose() {
    _actionStreamController.close();
    _statusStreamController.close();
  }
}
