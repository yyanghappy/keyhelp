import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:keyhelp/core/models/scheduled_task.dart';
import 'package:keyhelp/core/models/script.dart';
import 'package:hive/hive.dart';
import 'script_executor.dart';

class TaskScheduler {
  static final TaskScheduler _instance = TaskScheduler._internal();
  factory TaskScheduler() => _instance;
  TaskScheduler._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  Timer? _schedulerTimer;
  final ScriptExecutor _executor = ScriptExecutor();

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(initializationSettings);

    _startScheduler();
  }

  void _startScheduler() {
    _schedulerTimer?.cancel();
    _schedulerTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkAndExecuteTasks();
    });
    debugPrint('定时任务调度器已启动');
  }

  void _stopScheduler() {
    _schedulerTimer?.cancel();
    _schedulerTimer = null;
    debugPrint('定时任务调度器已停止');
  }

  Future<void> _checkAndExecuteTasks() async {
    try {
      final tasksBox = Hive.box<ScheduledTask>('tasks');
      final scriptsBox = Hive.box<Script>('scripts');
      final now = DateTime.now();

      for (final task in tasksBox.values) {
        if (!task.enabled) continue;

        if (task.executeAt != null && task.executeAt!.isBefore(now)) {
          final script = scriptsBox.get(task.scriptId);
          if (script != null) {
            await _executeTask(task, script);
          }
        }
      }
    } catch (e) {
      debugPrint('检查定时任务失败: $e');
    }
  }

  Future<void> _executeTask(ScheduledTask task, Script script) async {
    try {
      debugPrint('执行定时任务: ${task.id}');

      await _executor.executeScript(script);

      await _showNotification(
        '任务执行完成',
        '脚本 ${script.name} 已成功执行',
      );

      if (task.cron == null) {
        await task.delete();
      }
    } catch (e) {
      debugPrint('执行定时任务失败: $e');
      await _showNotification(
        '任务执行失败',
        '错误: $e',
      );
    }
  }

  Future<void> scheduleTask(ScheduledTask task) async {
    await task.save();
    debugPrint('已安排定时任务: ${task.id}');
  }

  Future<void> cancelTask(String taskId) async {
    final tasksBox = Hive.box<ScheduledTask>('tasks');
    await tasksBox.delete(taskId);
    debugPrint('已取消定时任务: $taskId');
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'keyhelp_tasks',
      'KeyHelp 任务通知',
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
    );
  }

  void dispose() {
    _stopScheduler();
  }
}
