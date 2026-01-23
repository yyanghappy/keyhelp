import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:keyhelp/core/models/action.dart';
import 'package:keyhelp/core/models/script.dart';
import 'package:keyhelp/core/repositories/script_repository.dart';
import 'package:keyhelp/core/services/accessibility_service.dart';
import 'package:keyhelp/shared/utils/accessibility_platform_service.dart';

class GameRecorderService {
  static final GameRecorderService _instance = GameRecorderService._internal();
  factory GameRecorderService() => _instance;
  GameRecorderService._internal();

  bool _isRecording = false;
  List<ScriptAction> _recordedActions = [];
  DateTime? _startTime;
  DateTime? _lastActionTime;
  StreamSubscription? _accessibilityEventSubscription;
  StreamSubscription? _platformEventSubscription;
  final _recordingStateController = StreamController<bool>.broadcast();
  final _actionCountController = StreamController<int>.broadcast();

  bool get isRecording => _isRecording;
  int get actionCount => _recordedActions.length;
  Stream<bool> get recordingStateStream => _recordingStateController.stream;
  Stream<int> get actionCountStream => _actionCountController.stream;

  /// 开始录制
  Future<void> startRecording() async {
    debugPrint('=== 准备开始录制 ===');
    debugPrint('当前状态: $_isRecording');

    if (_isRecording) {
      debugPrint('录制已开始，无需重复开始');
      return;
    }

    _recordedActions.clear();
    _startTime = DateTime.now();
    _lastActionTime = _startTime;
    _isRecording = true;

    // 通知状态变化
    _recordingStateController.add(true);
    _actionCountController.add(0);

    // 开始监听无障碍事件
    _setupEventListeners();

    // 通知原生层开始录制
    try {
      debugPrint('调用原生层开始录制');
      final result = await AccessibilityPlatformService.startRecording();
      debugPrint('原生层开始录制结果: $result');
    } catch (e) {
      debugPrint('原生层开始录制失败: $e');
    }

    debugPrint('游戏内录制已开始，动作计数: ${_recordedActions.length}');
    debugPrint('=== 开始录制完成 ===');
  }

  /// 停止录制
  Future<void> stopRecording() async {
    debugPrint('=== 准备停止录制 ===');
    debugPrint('当前状态: $_isRecording, 动作计数: ${_recordedActions.length}');

    if (!_isRecording) {
      debugPrint('录制未开始，无需停止');
      return;
    }

    _isRecording = false;

    // 取消事件监听
    _accessibilityEventSubscription?.cancel();
    _platformEventSubscription?.cancel();

    // 通知原生层停止录制
    try {
      debugPrint('调用原生层停止录制');
      final result = await AccessibilityPlatformService.stopRecording();
      debugPrint('原生层停止录制结果: $result');
    } catch (e) {
      debugPrint('原生层停止录制失败: $e');
    }

    // 通知状态变化
    _recordingStateController.add(false);

    debugPrint('游戏内录制已停止，共录制 ${_recordedActions.length} 个动作');
    debugPrint('=== 停止录制完成 ===');
  }

  /// 保存脚本
  Future<Script?> saveScript(String name) async {
    debugPrint('尝试保存脚本，当前动作数量: ${_recordedActions.length}');

    if (_recordedActions.isEmpty) {
      debugPrint('没有录制任何动作，无法保存脚本');
      return null;
    }

    final script = Script(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      actions: List.from(_recordedActions),
      createdAt: DateTime.now(),
      durationMs: _startTime != null
          ? DateTime.now().difference(_startTime!).inMilliseconds
          : 0,
    );

    await ScriptRepository.instance.saveScript(script);
    debugPrint('脚本已保存: ${script.name}，包含 ${script.actions.length} 个动作');
    return script;
  }

  /// 清空录制
  void clearRecording() {
    _recordedActions.clear();
    _actionCountController.add(0);
    debugPrint('清空录制');
  }

  /// 设置事件监听器
  void _setupEventListeners() {
    debugPrint('设置事件监听器，录制状态: $_isRecording');

    // 监听 AccessibilityService 事件
    _accessibilityEventSubscription =
        AccessibilityService().eventStream.listen((event) {
      debugPrint('收到 AccessibilityService 事件，录制状态: $_isRecording');
      if (!_isRecording) {
        debugPrint('录制未开始，忽略 AccessibilityService 事件');
        return;
      }
      _processAccessibilityEvent(event);
    }, onError: (error) {
      debugPrint('AccessibilityService 事件监听错误: $error');
    });

    // 监听原生层平台事件
    _platformEventSubscription =
        AccessibilityPlatformService.eventStream.listen((event) {
      debugPrint('收到平台事件，录制状态: $_isRecording');
      if (!_isRecording) {
        debugPrint('录制未开始，忽略平台事件');
        return;
      }
      _processPlatformEvent(event);
    }, onError: (error) {
      debugPrint('平台事件监听错误: $error');
    });

    debugPrint('事件监听器设置完成');
  }

  /// 处理无障碍事件
  void _processAccessibilityEvent(Map<String, dynamic> event) {
    if (!_isRecording) {
      debugPrint('录制未开始，忽略事件');
      return;
    }

    final eventType = (event['eventType'] as String? ?? '').toLowerCase();
    final bounds = event['bounds'] as Map?;
    final packageName = event['packageName'] as String? ?? '';

    // 过滤掉当前应用的事件
    if (packageName == 'com.keyhelp.app') {
      debugPrint('过滤掉当前应用事件: $packageName');
      return;
    }

    debugPrint('处理无障碍事件: type=$eventType, package=$packageName, hasBounds=${bounds != null}');

    if (eventType == 'click' && bounds != null) {
      _recordTapEvent(bounds);
    } else if (eventType == 'longclick' && bounds != null) {
      _recordLongPressEvent(bounds);
    } else if (eventType == 'scrolled') {
      final scrollY = event['scrollY'] as double?;
      if (scrollY != null && bounds != null) {
        _recordScrollEvent(bounds, scrollY);
      }
    } else {
      debugPrint('未处理的事件类型: $eventType');
    }
  }

  /// 处理平台事件
  void _processPlatformEvent(Map<String, dynamic> event) {
    // 可以处理来自原生层的特殊事件
    debugPrint('处理平台事件: $event');
  }

  /// 记录点击事件
  void _recordTapEvent(Map bounds) {
    final left = bounds['left'] as int? ?? 0;
    final top = bounds['top'] as int? ?? 0;
    final right = bounds['right'] as int? ?? 0;
    final bottom = bounds['bottom'] as int? ?? 0;

    if (left > 0 || top > 0 || right > 0 || bottom > 0) {
      // 计算中心坐标
      final centerX = (left + right) / 2;
      final centerY = (top + bottom) / 2;

      // 使用固定屏幕尺寸进行归一化（避免后台获取不准）
      // 1080x2400 是常见的屏幕分辨率
      const screenWidth = 1080.0;
      const screenHeight = 2400.0;

      // 归一化并限制在 0-1 范围内
      final normalizedX = (centerX / screenWidth).clamp(0.0, 1.0);
      final normalizedY = (centerY / screenHeight).clamp(0.0, 1.0);

      final action = ScriptAction(
        type: ActionType.tap,
        x: normalizedX,
        y: normalizedY,
      );

      _recordActionWithDelay(action);
    }
  }

  /// 记录长按事件
  void _recordLongPressEvent(Map bounds) {
    final left = bounds['left'] as int? ?? 0;
    final top = bounds['top'] as int? ?? 0;
    final right = bounds['right'] as int? ?? 0;
    final bottom = bounds['bottom'] as int? ?? 0;

    if (left > 0 || top > 0 || right > 0 || bottom > 0) {
      // 计算中心坐标
      final centerX = (left + right) / 2;
      final centerY = (top + bottom) / 2;

      // 使用固定屏幕尺寸进行归一化
      const screenWidth = 1080.0;
      const screenHeight = 2400.0;

      final normalizedX = (centerX / screenWidth).clamp(0.0, 1.0);
      final normalizedY = (centerY / screenHeight).clamp(0.0, 1.0);

      final action = ScriptAction(
        type: ActionType.longPress,
        x: normalizedX,
        y: normalizedY,
      );

      _recordActionWithDelay(action);
    }
  }

  /// 记录滑动事件
  void _recordScrollEvent(Map bounds, double scrollY) {
    final left = bounds['left'] as int? ?? 0;
    final top = bounds['top'] as int? ?? 0;
    final right = bounds['right'] as int? ?? 0;
    final bottom = bounds['bottom'] as int? ?? 0;

    if (left > 0 || top > 0 || right > 0 || bottom > 0) {
      // 计算中心坐标
      final centerX = (left + right) / 2;
      final centerY = (top + bottom) / 2;

      // 使用固定屏幕尺寸进行归一化
      const screenWidth = 1080.0;
      const screenHeight = 2400.0;

      final normalizedX = (centerX / screenWidth).clamp(0.0, 1.0);
      final normalizedY = (centerY / screenHeight).clamp(0.0, 1.0);

      final action = ScriptAction(
        type: ActionType.swipe,
        x: normalizedX,
        y: normalizedY,
        endX: normalizedX,
        endY: (normalizedY - scrollY / screenHeight).clamp(0.0, 1.0),
      );

      _recordActionWithDelay(action);
    }
  }

  /// 记录带延迟的动作
  void _recordActionWithDelay(ScriptAction action) {
    if (!_isRecording) return;

    final now = DateTime.now();
    final delay = _lastActionTime != null
        ? now.difference(_lastActionTime!).inMilliseconds
        : 0;

    action.delayMs = delay;
    _recordedActions.add(action);
    _lastActionTime = now;

    // 通知动作计数变化
    _actionCountController.add(_recordedActions.length);

    debugPrint('录制动作: ${action.type}, 延迟: ${delay}ms, 坐标: (${action.x}, ${action.y})');
  }

  /// 释放资源
  void dispose() {
    _accessibilityEventSubscription?.cancel();
    _platformEventSubscription?.cancel();
    _recordingStateController.close();
    _actionCountController.close();
  }
}