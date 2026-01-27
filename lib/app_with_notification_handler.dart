import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keyhelp/config/theme.dart';
import 'features/home/home_page.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:keyhelp/shared/services/event_bus.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'KeyHelp',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyAppWithNotificationHandler extends ConsumerStatefulWidget {
  const MyAppWithNotificationHandler({super.key});

  @override
  ConsumerState<MyAppWithNotificationHandler> createState() =>
      _MyAppWithNotificationHandlerState();
}

class _MyAppWithNotificationHandlerState
    extends ConsumerState<MyAppWithNotificationHandler> {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
        onDidReceiveBackgroundNotificationResponse:
            _onDidReceiveBackgroundNotificationResponse,
      );
    } catch (e) {
      print('初始化通知失败: $e');
    }
  }

  static void _onDidReceiveBackgroundNotificationResponse(
      NotificationResponse notificationResponse) {
    // 处理后台通知点击
    print('收到后台通知点击: ${notificationResponse.payload}');
  }

  void _onDidReceiveNotificationResponse(NotificationResponse notificationResponse) {
    final payload = notificationResponse.payload;
    print('收到通知点击: $payload');

    if (payload == 'show_script_list') {
      // 发送全局事件到主页
      EventBus().sendScriptListEvent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return const MyApp();
  }
}