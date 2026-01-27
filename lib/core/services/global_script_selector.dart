import 'dart:async';
import 'package:flutter/material.dart';
import 'package:keyhelp/core/models/script.dart';
import 'package:keyhelp/core/repositories/script_repository.dart';
import 'package:keyhelp/shared/services/float_window_service.dart';
import 'package:keyhelp/shared/services/global_dialog_service.dart';
import 'package:keyhelp/shared/services/event_bus.dart';

/// 全局脚本选择服务
/// 用于在任何应用界面中显示脚本选择对话框
class GlobalScriptSelector {
  static final GlobalScriptSelector _instance = GlobalScriptSelector._internal();
  factory GlobalScriptSelector() => _instance;
  GlobalScriptSelector._internal() {
    _setupEventListeners();
  }

  List<Script> _scripts = [];
  StreamSubscription<void>? _scriptListSubscription;

  void _setupEventListeners() {
    // 监听浮窗脚本列表事件
    _scriptListSubscription = FloatWindowService.scriptListStream.listen((_) {
      _handleShowScriptList();
    });
  }

  /// 处理显示脚本列表事件
  Future<void> _handleShowScriptList() async {
    try {
      // 加载脚本列表
      await _loadScripts();

      // 将脚本列表发送到Android原生层
      await _sendScriptListToNative();

      // 显示脚本选择对话框
      _showScriptSelectionDialog();
    } catch (e) {
      print('显示脚本列表失败: $e');
    }
  }

  /// 加载脚本列表
  Future<void> _loadScripts() async {
    try {
      _scripts = await ScriptRepository.instance.getAllScripts();
    } catch (e) {
      print('加载脚本列表失败: $e');
      _scripts = [];
    }
  }

  /// 将脚本列表发送到Android原生层
  Future<void> _sendScriptListToNative() async {
    try {
      final scriptIds = _scripts.map((script) => script.id).toList();
      final scriptNames = _scripts.map((script) => script.name).toList();
      final actionCounts = _scripts.map((script) => script.actions.length).toList();

      await FloatWindowService.setScriptList(
        scriptIds: scriptIds,
        scriptNames: scriptNames,
        actionCounts: actionCounts,
      );

      print('脚本列表已发送到原生层，数量: ${_scripts.length}');
    } catch (e) {
      print('发送脚本列表到原生层失败: $e');
    }
  }

  /// 显示脚本选择对话框
  void _showScriptSelectionDialog() {
    print('脚本列表事件触发，脚本数量: ${_scripts.length}');

    if (_scripts.isEmpty) {
      // 显示通知提示用户
      GlobalDialogService().showNotification(
        '脚本列表',
        '暂无脚本，请先添加脚本',
      );
      return;
    }

    // 发送全局事件，让应用的主页面来处理
    EventBus().sendScriptListEvent();
  }

  void dispose() {
    _scriptListSubscription?.cancel();
  }
}