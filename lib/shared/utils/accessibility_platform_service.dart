import 'package:flutter/services.dart';

class AccessibilityPlatformService {
  static const MethodChannel _channel =
      MethodChannel('com.keyhelp.app/accessibility');

  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
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
}
