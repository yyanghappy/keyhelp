import 'dart:async';
import 'package:flutter/services.dart';

class FloatWindowService {
  static const MethodChannel _channel =
      MethodChannel('com.keyhelp.app/float_window');
  static const EventChannel _eventChannel =
      EventChannel('com.keyhelp.app/float_window_events');

  static bool _isInitialized = false;
  static bool _hasPermission = false;
  static bool _isFloating = false;

  static StreamSubscription? _eventSubscription;
  static final _windowStateController = StreamController<bool>.broadcast();
  static final _scriptListController = StreamController<void>.broadcast();
  static final _recordController = StreamController<void>.broadcast();
  static final _saveController = StreamController<void>.broadcast();
  static final _playController = StreamController<void>.broadcast();
  static final _pauseController = StreamController<void>.broadcast();
  static final _stopController = StreamController<void>.broadcast();
  static final _executeScriptController = StreamController<String>.broadcast();

  static Stream<bool> get windowStateStream => _windowStateController.stream;
  static Stream<void> get scriptListStream => _scriptListController.stream;
  static Stream<void> get recordStream => _recordController.stream;
  static Stream<void> get saveStream => _saveController.stream;
  static Stream<void> get playStream => _playController.stream;
  static Stream<void> get pauseStream => _pauseController.stream;
  static Stream<void> get stopStream => _stopController.stream;
  static Stream<String> get executeScriptStream =>
      _executeScriptController.stream;

  static bool get hasPermission => _hasPermission;
  static bool get isFloatingNow => _isFloating;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    _hasPermission = await checkPermission();
    _startEventListener();
  }

  static void _startEventListener() {
    if (_eventSubscription != null) return;

    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
      (event) {
        if (event is Map && event['event'] != null) {
          switch (event['event']) {
            case 'windowClosed':
              _isFloating = false;
              _windowStateController.add(false);
              break;
            case 'showScriptList':
              _scriptListController.add(null);
              break;
            case 'record':
              _recordController.add(null);
              break;
            case 'save':
              _saveController.add(null);
              break;
            case 'play':
              _playController.add(null);
              break;
            case 'pause':
              _pauseController.add(null);
              break;
            case 'stop':
              _stopController.add(null);
              break;
            case 'executeScript':
              final scriptId = event['scriptId'] as String?;
              if (scriptId != null) {
                _executeScriptController.add(scriptId);
              }
              break;
          }
        }
      },
      onError: (error) {
        print('浮窗事件监听错误: $error');
      },
    );
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
      _windowStateController.add(true);
    } catch (e) {
      print('显示浮窗失败: $e');
      rethrow;
    }
  }

  static Future<void> hideFloatWindow() async {
    try {
      await _channel.invokeMethod('hideFloatWindow');
      _isFloating = false;
      _windowStateController.add(false);
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

  static Future<void> setCurrentScript({
    required String scriptId,
    required String scriptName,
  }) async {
    try {
      await _channel.invokeMethod('setCurrentScript', {
        'scriptId': scriptId,
        'scriptName': scriptName,
      });
    } catch (e) {
      print('设置当前脚本失败: $e');
    }
  }

  static Future<void> updateScriptName({
    required String scriptName,
  }) async {
    try {
      await _channel.invokeMethod('updateScriptName', {
        'scriptName': scriptName,
      });
    } catch (e) {
      print('更新脚本名称失败: $e');
    }
  }

  static Future<void> updateExecutionState({
    required String state,
    required bool isPlaying,
    required bool isPaused,
  }) async {
    try {
      await _channel.invokeMethod('updateExecutionState', {
        'state': state,
        'isPlaying': isPlaying,
        'isPaused': isPaused,
      });
    } catch (e) {
      print('更新执行状态失败: $e');
    }
  }

  static Future<void> updateRecordingState({
    required String state,
    required bool isRecording,
  }) async {
    try {
      await _channel.invokeMethod('updateRecordingState', {
        'state': state,
        'isRecording': isRecording,
      });
    } catch (e) {
      print('更新录制状态失败: $e');
    }
  }

  static void dispose() {
    _eventSubscription?.cancel();
    _windowStateController.close();
    _scriptListController.close();
    _recordController.close();
    _saveController.close();
    _playController.close();
    _pauseController.close();
    _stopController.close();
    _executeScriptController.close();
  }
}
