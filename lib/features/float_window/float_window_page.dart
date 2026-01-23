import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keyhelp/core/models/script.dart';
import 'package:keyhelp/core/models/execution_state.dart';
import 'package:keyhelp/core/services/script_executor.dart';
import 'package:keyhelp/core/services/game_recorder_service.dart';
import 'package:keyhelp/shared/services/float_window_service.dart';
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
  Script? _currentScript;
  StreamSubscription<bool>? _windowStateSubscription;
  StreamSubscription<void>? _scriptListSubscription;
  StreamSubscription<void>? _recordSubscription;
  StreamSubscription<void>? _saveSubscription;
  StreamSubscription<void>? _playSubscription;
  StreamSubscription<void>? _pauseSubscription;
  StreamSubscription<void>? _stopSubscription;
  StreamSubscription<ExecutionState>? _executorStateSubscription;

  // 添加 GameRecorderService 实例
  final GameRecorderService _recorder = GameRecorderService();

  @override
  void dispose() {
    _windowStateSubscription?.cancel();
    _scriptListSubscription?.cancel();
    _recordSubscription?.cancel();
    _saveSubscription?.cancel();
    _playSubscription?.cancel();
    _pauseSubscription?.cancel();
    _stopSubscription?.cancel();
    _executorStateSubscription?.cancel();
    _recorder.dispose();
    super.dispose();
  }

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

    _recordSubscription = FloatWindowService.recordStream.listen((_) {
      _handleRecord();
    });

    _saveSubscription = FloatWindowService.saveStream.listen((_) {
      _handleSave();
    });

    _playSubscription = FloatWindowService.playStream.listen((_) {
      _handlePlay();
    });

    _pauseSubscription = FloatWindowService.pauseStream.listen((_) {
      _handlePause();
    });

    _stopSubscription = FloatWindowService.stopStream.listen((_) {
      _handleStop();
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
      // 取消之前可能的订阅
      _executorStateSubscription?.cancel();

      setState(() {
        _isExecuting = true;
        _currentScript = script;
      });

      _executor = ScriptExecutor();

      // 更新浮窗状态
      await FloatWindowService.setCurrentScript(
        scriptId: script.id,
        scriptName: script.name,
      );

      // 先设置为准备运行状态
      await FloatWindowService.updateExecutionState(
        state: '准备运行',
        isPlaying: false,
        isPaused: false,
      );

      // 订阅执行状态变化，及时更新浮窗显示
      _executorStateSubscription = _executor!.stateStream.listen((state) {
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
            if (mounted) {
              setState(() {
                _isExecuting = false;
              });
            }
            break;
          case ExecutionStatus.failed:
            FloatWindowService.updateExecutionState(
              state: '执行失败',
              isPlaying: false,
              isPaused: false,
            );
            if (mounted) {
              setState(() {
                _isExecuting = false;
              });
            }
            break;
          default:
            break;
        }
      });

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('执行失败: $e')),
        );
      }
    }
  }

  void _handleRecord() {
    debugPrint('=== 处理录制按钮点击 ===');
    debugPrint('当前录制状态: ${_recorder.isRecording}');

    if (_recorder.isRecording) {
      debugPrint('执行停止录制逻辑 - 当前已有录制进行中');
      _recorder.stopRecording();
      debugPrint('停止录制完成');
      // 更新浮窗状态为"录制完成"
      FloatWindowService.updateRecordingState(
        state: '录制完成',
        isRecording: false,
      );
    } else {
      debugPrint('执行开始录制逻辑 - 当前无录制进行');
      _recorder.startRecording();
      debugPrint('开始录制完成');
      // 更新浮窗状态为"录制中"
      FloatWindowService.updateRecordingState(
        state: '录制中',
        isRecording: true,
      );
    }
    debugPrint('=== 录制按钮处理结束 ===');
  }

  void _handleSave() {
    _showSaveDialog();
  }

  Future<void> _showSaveDialog() async {
    if (_recorder.actionCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有录制任何动作')),
      );
      return;
    }

    final nameController = TextEditingController(
      text: '游戏脚本_${DateTime.now().millisecondsSinceEpoch}',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('保存脚本'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: '脚本名称',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入脚本名称')),
                );
                return;
              }

              Navigator.pop(context);
              final script = await _recorder.saveScript(name);
              if (script != null && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('脚本已保存: ${script.name}')),
                );
                // 保存后清空录制
                _recorder.clearRecording();
                // 更新浮窗状态
                FloatWindowService.updateRecordingState(
                  state: '未录制',
                  isRecording: false,
                );
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _handlePlay() {
    if (_currentScript != null && _executor != null && _isExecuting) {
      // 暂停中恢复执行
      // TODO: 实现 resume 方法
    } else if (_currentScript != null && !_isExecuting) {
      // 重新开始执行
      _executeScript(_currentScript!);
    }
  }

  void _handlePause() {
    if (_executor != null && _isExecuting) {
      // TODO: 实现 pause 方法
    }
  }

  void _handleStop() {
    if (_executor != null && _isExecuting) {
      // TODO: 实现 stop 方法
      if (mounted) {
        setState(() {
          _isExecuting = false;
        });
      }
      FloatWindowService.updateExecutionState(
        state: '已停止',
        isPlaying: false,
        isPaused: false,
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
