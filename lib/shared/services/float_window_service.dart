import 'package:flutter/services.dart';

class FloatWindowService {
  static const MethodChannel _channel =
      MethodChannel('com.keyhelp.app/float_window');

  static bool _isInitialized = false;
  static bool _hasPermission = false;
  static bool _isFloating = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    _hasPermission = await checkPermission();
  }

  static Future<bool> checkPermission() async {
    try {
      final bool result = await _channel.invokeMethod('checkPermission');
      _hasPermission = result;
      return result;
    } catch (e) {
      print('检查浮窗权限失败: $e');
      return false;
    }
  }

  static Future<void> requestPermission() async {
    try {
      await _channel.invokeMethod('openPermissionSettings');
    } catch (e) {
      print('打开浮窗权限设置失败: $e');
      rethrow;
    }
  }

  static Future<void> showFloatWindow() async {
    try {
      await _channel.invokeMethod('showFloatWindow');
      _isFloating = true;
    } catch (e) {
      print('显示浮窗失败: $e');
      rethrow;
    }
  }

  static Future<void> hideFloatWindow() async {
    try {
      await _channel.invokeMethod('hideFloatWindow');
      _isFloating = false;
    } catch (e) {
      print('隐藏浮窗失败: $e');
      rethrow;
    }
  }

  static Future<bool> isFloating() async {
    try {
      final bool result = await _channel.invokeMethod('isFloating');
      _isFloating = result;
      return result;
    } catch (e) {
      print('检查浮窗状态失败: $e');
      return false;
    }
  }

  static bool get hasPermission => _hasPermission;
  static bool get isFloatingNow => _isFloating;
}
