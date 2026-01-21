import 'package:flutter/material.dart';
import 'package:keyhelp/core/models/scheduled_task.dart';
import 'package:keyhelp/core/models/script.dart';
import 'package:keyhelp/core/repositories/task_repository.dart';
import 'package:keyhelp/core/repositories/script_repository.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  List<ScheduledTask> _tasks = [];
  List<Script> _scripts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final tasks = await TaskRepository.instance.getAllTasks();
    final scripts = await ScriptRepository.instance.getAllScripts();

    setState(() {
      _tasks = tasks;
      _scripts = scripts;
      _isLoading = false;
    });
  }

  Future<void> _toggleTask(ScheduledTask task) async {
    final updatedTask = task.copyWith(enabled: !task.enabled);
    await TaskRepository.instance.saveTask(updatedTask);
    await _loadData();
  }

  Future<void> _deleteTask(String taskId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个定时任务吗？'),
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
      await TaskRepository.instance.deleteTask(taskId);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('定时任务已删除')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('定时任务'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '暂无定时任务',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) {
                    final task = _tasks[index];
                    final script = _scripts.firstWhere(
                      (s) => s.id == task.scriptId,
                      orElse: () => Script(
                        id: '',
                        name: '未知脚本',
                        actions: [],
                        createdAt: DateTime.now(),
                        durationMs: 0,
                      ),
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: SwitchListTile(
                        value: task.enabled,
                        onChanged: (_) => _toggleTask(task),
                        title: Text(script.name),
                        subtitle: Text(
                          task.executeAt != null
                              ? '执行时间: ${_formatDateTime(task.executeAt!)}'
                              : '周期任务',
                        ),
                        secondary: Icon(
                          task.enabled ? Icons.alarm : Icons.alarm_off,
                          color: task.enabled ? Colors.green : Colors.grey,
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    );
                  },
                ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
