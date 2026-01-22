import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keyhelp/shared/services/float_window_service.dart';
import 'package:keyhelp/core/services/script_executor.dart';
import 'package:keyhelp/core/models/script.dart';
import 'package:keyhelp/core/repositories/script_repository.dart';

class FloatWindowPage extends ConsumerStatefulWidget {
  const FloatWindowPage({super.key});

  @override
  ConsumerState<FloatWindowPage> createState() => _FloatWindowPageState();
}

class _FloatWindowPageState extends ConsumerState<FloatWindowPage> {
  bool _isChecking = true;
  bool _hasPermission = false;
  bool _isFloating = false;
  List<Script> _scripts = [];
  ScriptExecutor? _executor;
  bool _isExecuting = false;
  StreamSubscription<bool>? _windowStateSubscription;
  StreamSubscription<void>? _scriptListSubscription;

  @override
  void initState() {
    super.initState();
    _setupEventListeners();
    _loadData();
  }

  void _setupEventListeners() {
    _windowStateSubscription =
        FloatWindowService.windowStateStream.listen((isOpen) {
      if (mounted) {
        setState(() {
          _isFloating = isOpen;
        });
      }
    });

    _scriptListSubscription = FloatWindowService.scriptListStream.listen((_) {
      if (mounted) {
        _showScriptSelectionDialog();
      }
    });
  }

  Future<void> _loadData() async {
    await Future.wait([
      _checkPermission(),
      _loadScripts(),
    ]);

    if (mounted) {
      setState(() {
        _isChecking = false;
      });
    }
  }

  Future<void> _checkPermission() async {
    await FloatWindowService.initialize();

    final hasPermission = await FloatWindowService.checkPermission();
    final isFloating = await FloatWindowService.isFloating();

    if (mounted) {
      setState(() {
        _hasPermission = hasPermission;
        _isFloating = isFloating;
      });
    }
  }

  Future<void> _loadScripts() async {
    final scripts = await ScriptRepository.instance.getAllScripts();

    if (mounted) {
      setState(() {
        _scripts = scripts;
      });
    }
  }

  Future<void> _requestPermission() async {
    await FloatWindowService.requestPermission();

    await Future.delayed(const Duration(seconds: 2));
    await _checkPermission();
  }

  Future<void> _toggleFloatWindow() async {
    if (_isFloating) {
      await FloatWindowService.hideFloatWindow();
      setState(() {
        _isFloating = false;
      });
    } else {
      if (!_hasPermission) {
        _showPermissionDialog();
        return;
      }

      await FloatWindowService.showFloatWindow();
      setState(() {
        _isFloating = true;
      });
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('需要浮窗权限'),
        content: const Text(
          '浮窗功能需要"在其他应用上层显示"权限。\n\n'
          '请授予权限以使用浮窗功能。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _requestPermission();
            },
            child: const Text('去授权'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('浮窗设置'),
      ),
      body: _isChecking
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: SwitchListTile(
                    title: const Text('启用浮窗'),
                    subtitle: const Text('在其他应用上方显示控制浮窗'),
                    value: _isFloating,
                    onChanged: (value) => _toggleFloatWindow(),
                  ),
                ),
                const SizedBox(height: 16),
                if (!_hasPermission)
                  Card(
                    color: Colors.orange.shade50,
                    child: ListTile(
                      leading: const Icon(Icons.warning, color: Colors.orange),
                      title: const Text('浮窗权限未授予'),
                      subtitle: const Text('点击此处申请浮窗权限'),
                      onTap: _requestPermission,
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    ),
                  ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '使用说明',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        _buildInstructionItem(
                          icon: Icons.touch_app,
                          title: '拖动移动',
                          description: '按住浮窗可以拖动位置',
                        ),
                        const SizedBox(height: 12),
                        _buildInstructionItem(
                          icon: Icons.close,
                          title: '关闭浮窗',
                          description: '点击 X 按钮关闭浮窗',
                        ),
                        const SizedBox(height: 12),
                        _buildInstructionItem(
                          icon: Icons.play_arrow,
                          title: '快速执行',
                          description: '浮窗中可快速执行脚本',
                        ),
                        const SizedBox(height: 12),
                        _buildInstructionItem(
                          icon: Icons.stop,
                          title: '立即停止',
                          description: '在任何应用中都能停止脚本',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '快捷脚本',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '点击浮窗中的脚本列表按钮',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                        if (_scripts.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 16),
                            child: Text(
                              '暂无脚本',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        else
                          ...List.generate(
                            _scripts.take(5).length,
                            (index) => ListTile(
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
                              title: Text(_scripts[index].name),
                              subtitle:
                                  Text('${_scripts[index].actions.length} 个动作'),
                              trailing: Icon(Icons.play_circle_outline),
                              onTap: () {},
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _showScriptSelectionDialog() {
    if (_scripts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无脚本，请先添加脚本')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择脚本'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _scripts.length,
            itemBuilder: (context, index) {
              final script = _scripts[index];
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
                  _executeScript(script);
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

  Future<void> _executeScript(Script script) async {
    try {
      setState(() {
        _isExecuting = true;
      });

      _executor = ScriptExecutor();

      // 更新浮窗状态
      await FloatWindowService.setCurrentScript(
        scriptId: script.id,
        scriptName: script.name,
      );
      await FloatWindowService.updateExecutionState(
        state: '准备运行',
        isPlaying: false,
        isPaused: false,
      );

      await _executor!.executeScript(script);

      if (mounted) {
        setState(() {
          _isExecuting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExecuting = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('执行失败: $e')),
      );
    }
  }

  Widget _buildInstructionItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
