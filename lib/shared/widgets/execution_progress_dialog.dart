import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:keyhelp/core/models/execution_state.dart';
import 'package:keyhelp/core/models/action.dart';
import 'package:keyhelp/features/logs/execution_logs_page.dart';

class ExecutionProgressDialog extends StatefulWidget {
  final Stream<ExecutionState> stateStream;
  final VoidCallback onClose;

  const ExecutionProgressDialog({
    super.key,
    required this.stateStream,
    required this.onClose,
  });

  @override
  State<ExecutionProgressDialog> createState() =>
      _ExecutionProgressDialogState();
}

class _ExecutionProgressDialogState extends State<ExecutionProgressDialog> {
  ExecutionState _state = ExecutionState();
  StreamSubscription<ExecutionState>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _state = state;
        });

        if (state.status == ExecutionStatus.completed ||
            state.status == ExecutionStatus.failed) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              widget.onClose();
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildBody(),
            if (_state.status == ExecutionStatus.completed ||
                _state.status == ExecutionStatus.failed)
              _buildResult(),
            if (_state.status == ExecutionStatus.completed ||
                _state.status == ExecutionStatus.failed)
              _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExecutionLogsPage(state: _state),
                  ),
                );
              },
              icon: const Icon(Icons.description),
              label: const Text('查看日志'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: widget.onClose,
              icon: const Icon(Icons.close),
              label: const Text('关闭'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(),
            color: _getStatusColor(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusTitle(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _getStatusColor(),
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_state.currentIndex}/${_state.totalActions} 动作',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
          if (_state.status == ExecutionStatus.running)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildProgressBar(),
          const SizedBox(height: 16),
          _buildCurrentAction(),
          if (_state.status == ExecutionStatus.running) ...[
            const SizedBox(height: 16),
            _buildStats(),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _state.progress,
            minHeight: 12,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor()),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '进度: ${(_state.progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              '已用时: ${_formatDuration(_state.elapsedTime)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCurrentAction() {
    final action = _state.currentAction;
    if (action == null || _state.status != ExecutionStatus.running) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.play_circle_outline,
            color: Colors.blue.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '动作 ${_state.currentIndex}',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getActionDescription(action),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            icon: Icons.access_time,
            label: '总时长',
            value: _formatDuration(_state.elapsedTime),
          ),
        ),
        Expanded(
          child: _buildStatItem(
            icon: Icons.speed,
            label: '平均速度',
            value: _state.currentIndex > 0
                ? '${(_state.elapsedTime.inMilliseconds / _state.currentIndex).toStringAsFixed(0)}ms/动作'
                : '-',
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _state.status == ExecutionStatus.completed
                ? Icons.check_circle
                : Icons.cancel,
            color: _getStatusColor(),
            size: 48,
          ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _state.status == ExecutionStatus.completed ? '执行成功' : '执行失败',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: _getStatusColor(),
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (_state.status == ExecutionStatus.completed)
                Text(
                  '完成 ${_state.totalActions} 个动作',
                  style: TextStyle(
                    color: _getStatusColor(),
                  ),
                ),
              if (_state.status == ExecutionStatus.failed &&
                  _state.errorMessage != null)
                Text(
                  _state.errorMessage!,
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (_state.status) {
      case ExecutionStatus.idle:
        return Colors.grey;
      case ExecutionStatus.running:
        return Colors.blue;
      case ExecutionStatus.paused:
        return Colors.orange;
      case ExecutionStatus.completed:
        return Colors.green;
      case ExecutionStatus.failed:
        return Colors.red;
    }
  }

  IconData _getStatusIcon() {
    switch (_state.status) {
      case ExecutionStatus.idle:
        return Icons.stop_circle;
      case ExecutionStatus.running:
        return Icons.play_circle;
      case ExecutionStatus.paused:
        return Icons.pause_circle;
      case ExecutionStatus.completed:
        return Icons.check_circle;
      case ExecutionStatus.failed:
        return Icons.cancel;
    }
  }

  String _getStatusTitle() {
    switch (_state.status) {
      case ExecutionStatus.idle:
        return '准备执行';
      case ExecutionStatus.running:
        return '正在执行';
      case ExecutionStatus.paused:
        return '已暂停';
      case ExecutionStatus.completed:
        return '执行完成';
      case ExecutionStatus.failed:
        return '执行失败';
    }
  }

  String _getActionDescription(ScriptAction action) {
    switch (action.type) {
      case ActionType.tap:
        return '点击 (${action.x?.toStringAsFixed(2)}, ${action.y?.toStringAsFixed(2)})';
      case ActionType.swipe:
        return '滑动 (${action.x?.toStringAsFixed(2)}, ${action.y?.toStringAsFixed(2)}) -> (${action.endX?.toStringAsFixed(2)}, ${action.endY?.toStringAsFixed(2)})';
      case ActionType.longPress:
        return '长按 (${action.x?.toStringAsFixed(2)}, ${action.y?.toStringAsFixed(2)})';
      case ActionType.wait:
        return '等待 ${action.delayMs}ms';
      case ActionType.condition:
        return '条件判断: ${action.condition}';
      case ActionType.loop:
        return '循环 ${action.loopCount}次';
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final milliseconds = duration.inMilliseconds % 1000;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${milliseconds.toString().padLeft(3, '0')}';
  }
}
