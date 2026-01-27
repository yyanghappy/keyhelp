import 'dart:async';
import 'package:flutter/material.dart';
import 'package:keyhelp/core/models/script.dart';
import 'package:keyhelp/core/repositories/script_repository.dart';
import 'package:keyhelp/shared/services/float_window_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:keyhelp/core/services/script_executor.dart';
import 'package:keyhelp/core/models/execution_state.dart';

/// 全局对话框服务
/// 用于在应用的任何位置显示对话框
class GlobalDialogService {
  static final GlobalDialogService _instance = GlobalDialogService._internal();
  factory GlobalDialogService() => _instance;
  GlobalDialogService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// 显示脚本选择对话框
  Future<void> showScriptSelectionDialog(
      List<Script> scripts, BuildContext context) async {
    if (scripts.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('暂无脚本，请先添加脚本')),
        );
      }
      return;
    }

    if (!context.mounted) return;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择脚本'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: scripts.length,
            itemBuilder: (context, index) {
              final script = scripts[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(script.name),
                subtitle: Text('${script.actions.length} 个动作'),
                onTap: () {
                  Navigator.pop(context);
                  _onScriptSelected(script, context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  /// 处理脚本选择事件
  void _onScriptSelected(Script script, BuildContext context) async {
    // 发送事件到浮窗服务，触发脚本执行
    print('选择脚本: ${script.name}');

    try {
      // 更新浮窗状态
      await FloatWindowService.setCurrentScript(
        scriptId: script.id,
        scriptName: script.name,
      );

      // 更新浮窗执行状态
      await FloatWindowService.updateExecutionState(
        state: '准备运行',
        isPlaying: false,
        isPaused: false,
      );

      // 执行脚本
      await _executeScript(script, context);
    } catch (e) {
      print('执行脚本失败: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('执行脚本失败: $e')),
        );
      }
    }
  }

  /// 执行脚本
  Future<void> _executeScript(Script script, BuildContext context) async {
    print('开始执行脚本: ${script.name}');

    final executor = ScriptExecutor();

    try {
      // 订阅执行状态变化
      final stateSubscription = executor.stateStream.listen((state) {
        switch (state.status) {
          case ExecutionStatus.running:
            FloatWindowService.updateExecutionState(
              state: '执行中',
              isPlaying: true,
              isPaused: false,
            );
            break;
          case ExecutionStatus.paused:
            FloatWindowService.updateExecutionState(
              state: '已暂停',
              isPlaying: true,
              isPaused: true,
            );
            break;
          case ExecutionStatus.completed:
            FloatWindowService.updateExecutionState(
              state: '执行完成',
              isPlaying: false,
              isPaused: false,
            );
            break;
          case ExecutionStatus.failed:
            FloatWindowService.updateExecutionState(
              state: '执行失败',
              isPlaying: false,
              isPaused: false,
            );
            break;
          default:
            break;
        }
      });

      // 执行脚本
      await executor.executeScript(script);

      // 取消订阅
      stateSubscription.cancel();
    } catch (e) {
      print('脚本执行异常: $e');
      // 更新浮窗状态
      await FloatWindowService.updateExecutionState(
        state: '执行失败',
        isPlaying: false,
        isPaused: false,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('脚本执行失败: $e')),
        );
      }
    } finally {
      executor.dispose();
    }
  }

  /// 显示通知
  Future<void> showNotification(String title, String body,
      {String? payload}) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'keyhelp_global',
        'KeyHelp 全局通知',
        importance: Importance.max,
        priority: Priority.high,
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await _notificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );
    } catch (e) {
      print('显示通知失败: $e');
    }
  }
}