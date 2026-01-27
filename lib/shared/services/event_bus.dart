import 'dart:async';

/// 全局事件总线
/// 用于在应用的不同部分之间传递事件
class EventBus {
  static final EventBus _instance = EventBus._internal();
  factory EventBus() => _instance;
  EventBus._internal();

  // 脚本列表事件流控制器
  final _scriptListController = StreamController<void>.broadcast();

  // 脚本执行事件流控制器
  final _executeScriptController = StreamController<String>.broadcast();

  /// 脚本列表事件流
  Stream<void> get scriptListStream => _scriptListController.stream;

  /// 脚本执行事件流
  Stream<String> get executeScriptStream => _executeScriptController.stream;

  /// 发送脚本列表事件
  void sendScriptListEvent() {
    _scriptListController.add(null);
  }

  /// 发送脚本执行事件
  void sendExecuteScriptEvent(String scriptId) {
    _executeScriptController.add(scriptId);
  }

  /// 关闭所有流控制器
  void dispose() {
    _scriptListController.close();
    _executeScriptController.close();
  }
}