import 'dart:async';
import 'package:flutter/services.dart';

class AccessibilityPlatformService {
  static const MethodChannel _channel =
      MethodChannel('com.keyhelp.app/accessibility');
  static const EventChannel _eventChannel =
      EventChannel('com.keyhelp.app/accessibility_events');

  static bool _isInitialized = false;
  static StreamSubscription? _eventSubscription;
  static final _eventStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  static Stream<Map<String, dynamic>> get eventStream =>
      _eventStreamController.stream;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
      (event) {
        if (event is Map) {
          final eventMap = Map<String, dynamic>.from(event);
          _eventStreamController.add(eventMap);
        }
      },
      onError: (error) {
        print('无障碍事件监听错误: $error');
      },
    );
  }

  static Future<bool> isServiceEnabled() async {
    try {
      final bool result = await _channel.invokeMethod('isServiceEnabled');
      return result;
    } catch (e) {
      print('检查无障碍服务失败: $e');
      return false;
    }
  }

  static Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } catch (e) {
      print('打开无障碍设置失败: $e');
      rethrow;
    }
  }

  static Future<bool> performClick(double x, double y) async {
    try {
      final bool result = await _channel.invokeMethod('performClick', {
        'x': x,
        'y': y,
      });
      return result;
    } catch (e) {
      print('执行点击失败: $e');
      return false;
    }
  }

  static Future<bool> performSwipe(
    double startX,
    double startY,
    double endX,
    double endY, {
    int duration = 300,
  }) async {
    try {
      final bool result = await _channel.invokeMethod('performSwipe', {
        'startX': startX,
        'startY': startY,
        'endX': endX,
        'endY': endY,
        'duration': duration,
      });
      return result;
    } catch (e) {
      print('执行滑动失败: $e');
      return false;
    }
  }

  static Future<bool> performLongPress(
    double x,
    double y, {
    int duration = 800,
  }) async {
    try {
      final bool result = await _channel.invokeMethod('performLongPress', {
        'x': x,
        'y': y,
        'duration': duration,
      });
      return result;
    } catch (e) {
      print('执行长按失败: $e');
      return false;
    }
  }

  static Future<bool> startRecording() async {
    try {
      final bool result = await _channel.invokeMethod('startRecording');
      return result;
    } catch (e) {
      print('开始录制失败: $e');
      return false;
    }
  }

  static Future<bool> stopRecording() async {
    try {
      final bool result = await _channel.invokeMethod('stopRecording');
      return result;
    } catch (e) {
      print('停止录制失败: $e');
      return false;
    }
  }

  static Future<bool> isRecording() async {
    try {
      final bool result = await _channel.invokeMethod('isRecording');
      return result;
    } catch (e) {
      print('检查录制状态失败: $e');
      return false;
    }
  }

  static Future<String> getCurrentPackageName() async {
    try {
      final String result =
          await _channel.invokeMethod('getCurrentPackageName');
      return result;
    } catch (e) {
      print('获取当前包名失败: $e');
      return '';
    }
  }

  static Future<String> getCurrentActivityName() async {
    try {
      final String result =
          await _channel.invokeMethod('getCurrentActivityName');
      return result;
    } catch (e) {
      print('获取当前Activity失败: $e');
      return '';
    }
  }

  static void dispose() {
    _eventSubscription?.cancel();
    _eventStreamController.close();
  }
}
