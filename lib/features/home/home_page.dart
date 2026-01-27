import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keyhelp/core/services/accessibility_service.dart';
import 'package:keyhelp/features/scripts/scripts_page.dart';
import 'package:keyhelp/features/record/record_page.dart';
import 'package:keyhelp/features/schedule/schedule_page.dart';
import 'package:keyhelp/features/float_window/float_window_page.dart';

final accessibilityServiceProvider =
    Provider<AccessibilityService>((ref) => AccessibilityService());

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _isChecking = true;
  bool _isServiceEnabled = false;
  Timer? _serviceCheckTimer;

  @override
  void initState() {
    super.initState();
    _checkAccessibilityService();
  }

  @override
  void dispose() {
    _serviceCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkAccessibilityService() async {
    final service = ref.read(accessibilityServiceProvider);
    await service.checkServiceStatus();
    setState(() {
      _isChecking = false;
      _isServiceEnabled = service.isServiceEnabled;
    });
  }

  Future<void> _startServiceCheckPolling() async {
    _serviceCheckTimer?.cancel();
    _serviceCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      final service = ref.read(accessibilityServiceProvider);
      await service.checkServiceStatus();
      if (mounted) {
        setState(() {
          _isServiceEnabled = service.isServiceEnabled;
        });
        // 如果服务已启用，停止轮询
        if (service.isServiceEnabled) {
          timer.cancel();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('无障碍服务已启用！'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  Future<void> _openAccessibilitySettings() async {
    final service = ref.read(accessibilityServiceProvider);
    await service.openAccessibilitySettings();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('请在设置中找到并启用"KeyHelp自动化工具"服务'),
        duration: Duration(seconds: 3),
      ),
    );

    // 开始轮询检测服务状态
    await _startServiceCheckPolling();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KeyHelp'),
        actions: [
          IconButton(
            icon: Icon(
              _isServiceEnabled ? Icons.check_circle : Icons.warning,
              color: _isServiceEnabled ? Colors.green : Colors.orange,
            ),
            onPressed: _openAccessibilitySettings,
            tooltip: '无障碍服务设置',
          ),
        ],
      ),
      body: _isChecking
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (!_isServiceEnabled)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.orange.shade50,
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '无障碍服务未启用',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                '请启用"KeyHelp自动化工具"服务以使用触控模拟功能',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _openAccessibilitySettings,
                          child: const Text('去设置'),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    padding: const EdgeInsets.all(16),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      _buildFeatureCard(
                        context,
                        icon: Icons.play_circle_outline,
                        title: '脚本录制',
                        description: '录制操作步骤',
                        color: Colors.blue,
                        onTap: () {
                          if (!_isServiceEnabled) {
                            _showServiceWarning();
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RecordPage()),
                          );
                        },
                      ),
                      _buildFeatureCard(
                        context,
                        icon: Icons.list_alt,
                        title: '脚本列表',
                        description: '管理所有脚本',
                        color: Colors.green,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ScriptsPage()),
                          );
                        },
                      ),
                      _buildFeatureCard(
                        context,
                        icon: Icons.schedule,
                        title: '定时任务',
                        description: '设置定时执行',
                        color: Colors.orange,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SchedulePage()),
                          );
                        },
                      ),
                      _buildFeatureCard(
                        context,
                        icon: Icons.settings,
                        title: '设置',
                        description: '应用配置',
                        color: Colors.grey,
                        onTap: () {
                          _showSettingsDialog();
                        },
                      ),
                      _buildFeatureCard(
                        context,
                        icon: Icons.picture_in_picture,
                        title: '浮窗设置',
                        description: '跨应用控制',
                        color: Colors.purple,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const FloatWindowPage()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  void _showServiceWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('需要启用无障碍服务'),
        content: const Text(
          '脚本录制和触控模拟功能需要启用"KeyHelp自动化工具"服务。\n\n'
          '请点击右上角的图标或上方的"去设置"按钮，在无障碍设置中找到并启用该服务。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openAccessibilitySettings();
            },
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.accessibility_new),
              title: const Text('无障碍服务'),
              subtitle: Text(
                _isServiceEnabled ? '已启用' : '未启用',
              ),
              trailing: Icon(
                _isServiceEnabled ? Icons.check_circle : Icons.error,
                color: _isServiceEnabled ? Colors.green : Colors.red,
              ),
              onTap: () {
                Navigator.pop(context);
                _openAccessibilitySettings();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('关于'),
              subtitle: const Text('KeyHelp v0.1.0'),
              onTap: () {
                Navigator.pop(context);
                showAboutDialog(
                  context: context,
                  applicationName: 'KeyHelp',
                  applicationVersion: '0.1.0',
                  applicationIcon: const Icon(Icons.smartphone, size: 48),
                  children: const [
                    Text('个人自用的安卓自动化工具'),
                    SizedBox(height: 16),
                    Text('支持脚本录制、定时执行和触控模拟'),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
