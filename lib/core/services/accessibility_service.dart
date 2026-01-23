import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:keyhelp/core/models/action.dart';
import 'package:keyhelp/shared/utils/accessibility_platform_service.dart';

class AccessibilityService {
  static final AccessibilityService _instance =
      AccessibilityService._internal();
  factory AccessibilityService() => _instance;
  AccessibilityService._internal() {
    AccessibilityPlatformService.initialize();
    _setupEventListener();
  }

  bool _isRecording = false;
  bool _isExecuting = false;
  bool _autoRecordMode = false; // 自动录制模式
  final List<ScriptAction> _recordedActions = [];
  final _actionStreamController = StreamController<ScriptAction>.broadcast();
  final _statusStreamController = StreamController<String>.broadcast();
  final _eventStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  bool _isServiceEnabled = false;
  StreamSubscription? _eventSubscription;
  String _lastPackageName = '';

  Stream<ScriptAction> get actionStream => _actionStreamController.stream;
  Stream<String> get statusStream => _statusStreamController.stream;
  Stream<Map<String, dynamic>> get eventStream => _eventStreamController.stream;
  bool get isRecording => _isRecording;
  bool get isExecuting => _isExecuting;
  bool get isAutoRecordMode => _autoRecordMode;
  bool get isServiceEnabled => _isServiceEnabled;
  List<ScriptAction> get recordedActions => List.unmodifiable(_recordedActions);

  void _setupEventListener() {
    _eventSubscription =
        AccessibilityPlatformService.eventStream.listen((event) {
      try {
        _eventStreamController.add(event);

        // 处理自动录制
        if (_autoRecordMode) {
          _processAccessibilityEvent(event);
        }

        // 录制模式下也处理 Accessibility 事件（用于跨 app 录制）
        if (_isRecording && !_autoRecordMode) {
          _processAccessibilityEvent(event);
        }

        // 记录当前包名
        final packageName = event['packageName'] as String? ?? '';
        if (packageName != _lastPackageName && packageName.isNotEmpty) {
          debugPrint('切换到应用: $packageName');
          _lastPackageName = packageName;
        }
      } catch (e) {
        debugPrint('处理无障碍事件失败: $e');
      }
    });
  }

  void _processAccessibilityEvent(Map<String, dynamic> event) {
    if (!_isRecording) return;

    final eventType = (event['eventType'] as String? ?? '').toLowerCase();
    final bounds = event['bounds'] as Map?;
    final packageName = event['packageName'] as String? ?? '';

    debugPrint(
        '处理事件: type=$eventType, package=$packageName, hasBounds=${bounds != null}');

    // 计算坐标
    double x = 0, y = 0;
    bool hasCoordinates = false;

    if (bounds != null) {
      final left = bounds['left'] as int? ?? 0;
      final top = bounds['top'] as int? ?? 0;
      final right = bounds['right'] as int? ?? 0;
      final bottom = bounds['bottom'] as int? ?? 0;
      if (left > 0 || top > 0 || right > 0 || bottom > 0) {
        x = (left + right) / 2;
        y = (top + bottom) / 2;
        hasCoordinates = true;
        debugPrint('使用bounds坐标: ($x, $y)');
      }
    }

    // 如果没有 bounds 坐标，记录事件但不录制动作
    if (!hasCoordinates) {
      debugPrint('警告: 事件没有坐标信息 package=$packageName type=$eventType');
      // 对于没有坐标的点击事件，记录为占位符，提示用户需要手动指定位置
      return;
    }

    switch (eventType) {
      case 'click':
        debugPrint('录制点击: ($x, $y)');
        recordTap(x, y);
        break;
      case 'longclick':
        debugPrint('录制长按: ($x, $y)');
        recordLongPress(x, y);
        break;
      case 'scrolled':
        final scrollY = event['scrollY'] as double?;
        if (scrollY != null) {
          final swipeAction = ScriptAction(
            type: ActionType.swipe,
            x: x,
            y: y,
            endX: x,
            endY: y - scrollY,
          );
          _recordedActions.add(swipeAction);
          _actionStreamController.add(swipeAction);
        }
        break;
    }
  }

  Future<void> checkServiceStatus() async {
    _isServiceEnabled = await AccessibilityPlatformService.isServiceEnabled();
    debugPrint('无障碍服务状态: $_isServiceEnabled');
  }

  Future<void> openAccessibilitySettings() async {
    await AccessibilityPlatformService.openAccessibilitySettings();
  }

  void enableAutoRecordMode() {
    _autoRecordMode = true;
    _isRecording = true;
    _recordedActions.clear();
    _statusStreamController.add('auto_recording');
    debugPrint('自动录制模式已开启');
  }

  void disableAutoRecordMode() {
    _autoRecordMode = false;
    _statusStreamController.add('idle');
    debugPrint('自动录制模式已关闭');
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
    debugPrint('停止录制，共录制 ${_recordedActions.length} 个动作');
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
    _eventSubscription?.cancel();
    _actionStreamController.close();
    _statusStreamController.close();
    _eventStreamController.close();
  }
}
