import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'app_with_notification_handler.dart';
import 'core/models/script.dart';
import 'core/models/action.dart';
import 'core/models/scheduled_task.dart';
import 'shared/services/float_window_service.dart';
import 'core/services/global_recording_manager.dart';
import 'core/services/global_script_selector.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(ScriptAdapter());
  Hive.registerAdapter(ScriptActionAdapter());
  Hive.registerAdapter(ScheduledTaskAdapter());
  Hive.registerAdapter(ActionTypeAdapter());

  await Hive.openBox<Script>('scripts');
  await Hive.openBox<ScheduledTask>('tasks');

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // 初始化浮窗服务并启动全局录制管理器
  await FloatWindowService.initialize();
  GlobalRecordingManager();
  GlobalScriptSelector();

  runApp(const ProviderScope(child: MyAppWithNotificationHandler()));
}
