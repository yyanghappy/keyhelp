import 'package:flutter/material.dart';
import 'package:keyhelp/core/models/script.dart';
import 'package:keyhelp/core/repositories/script_repository.dart';
import 'package:keyhelp/core/services/script_executor.dart';
import 'package:keyhelp/core/models/execution_state.dart';
import 'package:keyhelp/shared/widgets/execution_progress_dialog.dart';

class ScriptsPage extends StatefulWidget {
  const ScriptsPage({super.key});

  @override
  State<ScriptsPage> createState() => _ScriptsPageState();
}

class _ScriptsPageState extends State<ScriptsPage> {
  List<Script> _scripts = [];
  bool _isLoading = true;
  ScriptExecutor? _executor;
  bool _isLooping = false;
  int _loopCount = 0;

  @override
  void initState() {
    super.initState();
    _loadScripts();
  }

  @override
  void dispose() {
    _executor?.dispose();
    super.dispose();
  }

  Future<void> _loadScripts() async {
    setState(() {
      _isLoading = true;
    });

    final scripts = await ScriptRepository.instance.getAllScripts();

    setState(() {
      _scripts = scripts;
      _isLoading = false;
    });
  }

  Future<void> _deleteScript(String scriptId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个脚本吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ScriptRepository.instance.deleteScript(scriptId);
      await _loadScripts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('脚本已删除')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('脚本列表'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _scripts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_open,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '暂无脚本',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '点击录制按钮开始创建脚本',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _scripts.length,
                  itemBuilder: (context, index) {
                    final script = _scripts[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
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
                        subtitle: Text(
                          '${script.actions.length} 个动作 • ${_formatDuration(script.duration)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.play_arrow),
                              onPressed: () async {
                                final result = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => _buildLoopDialog(),
                                );

                                if (result == null) return;

                                _executor = ScriptExecutor();

                                if (!mounted) return;

                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => ExecutionProgressDialog(
                                    stateStream: _executor!.stateStream,
                                    onClose: () => Navigator.pop(context),
                                    onStop: () {
                                      _executor?.stopExecution();
                                    },
                                  ),
                                );

                                await _executor!.executeScript(
                                  script,
                                  loop: _isLooping,
                                  loopCount: _loopCount,
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              color: Colors.red,
                              onPressed: () => _deleteScript(script.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildLoopDialog() {
    return AlertDialog(
      title: const Text('循环设置'),
      content: StatefulBuilder(
        builder: (context, setDialogState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('启用循环'),
                value: _isLooping,
                onChanged: (value) {
                  setDialogState(() {
                    _isLooping = value;
                  });
                },
              ),
              if (_isLooping)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '循环次数',
                      hintText: '0 表示无限循环',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _loopCount = int.tryParse(value) ?? 0;
                    },
                  ),
                ),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('开始执行'),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
