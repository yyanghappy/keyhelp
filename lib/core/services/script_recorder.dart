import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:keyhelp/core/models/action.dart';
import 'package:keyhelp/core/models/script.dart';

class ScriptRecorder {
  List<ScriptAction> _actions = [];
  DateTime? _startTime;
  DateTime? _lastActionTime;
  bool _isRecording = false;
  Timer? _durationTimer;

  bool get isRecording => _isRecording;
  List<ScriptAction> get actions => List.unmodifiable(_actions);
  Duration get duration {
    if (_startTime == null) return Duration.zero;
    return DateTime.now().difference(_startTime!);
  }

  void startRecording() {
    _actions.clear();
    _startTime = DateTime.now();
    _lastActionTime = _startTime;
    _isRecording = true;
    debugPrint('开始录制');

    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final durationVal = DateTime.now().difference(_startTime!);
      debugPrint('录制时长: ${durationVal.inSeconds}秒');
    });
  }

  void stopRecording() {
    _isRecording = false;
    debugPrint('停止录制');
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  void _recordActionWithDelay(ScriptAction action, DateTime timestamp) {
    if (!_isRecording) return;

    final delay = _lastActionTime != null
        ? timestamp.difference(_lastActionTime!).inMilliseconds
        : 0;

    action.delayMs = delay;
    _actions.add(action);
    _lastActionTime = timestamp;
    debugPrint('录制动作: ${action.type}, 延迟: ${delay}ms');
  }

  void recordTap(double x, double y, DateTime timestamp) {
    final action = ScriptAction(
      type: ActionType.tap,
      x: x,
      y: y,
    );
    _recordActionWithDelay(action, timestamp);
  }

  void recordSwipe(double startX, double startY, double endX, double endY,
      DateTime timestamp) {
    final action = ScriptAction(
      type: ActionType.swipe,
      x: startX,
      y: startY,
      endX: endX,
      endY: endY,
    );
    _recordActionWithDelay(action, timestamp);
  }

  void recordLongPress(double x, double y, DateTime timestamp) {
    final action = ScriptAction(
      type: ActionType.longPress,
      x: x,
      y: y,
    );
    _recordActionWithDelay(action, timestamp);
  }

  void addWaitAction(int milliseconds) {
    if (!_isRecording) return;

    final action = ScriptAction(
      type: ActionType.wait,
      delayMs: milliseconds,
    );
    _actions.add(action);
    debugPrint('添加延迟: ${milliseconds}ms');
  }

  void addLoopAction(int count) {
    if (!_isRecording) return;

    final action = ScriptAction(
      type: ActionType.loop,
      loopCount: count,
    );
    _actions.add(action);
    debugPrint('添加循环: $count次');
  }

  void clearRecording() {
    _actions.clear();
    debugPrint('清空录制');
  }

  Script createScript(String name) {
    return Script(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      actions: List.from(_actions),
      createdAt: DateTime.now(),
      durationMs: _startTime != null
          ? DateTime.now().difference(_startTime!).inMilliseconds
          : 0,
    );
  }

  void dispose() {
    _durationTimer?.cancel();
  }
}
