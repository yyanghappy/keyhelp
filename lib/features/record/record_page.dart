import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keyhelp/core/services/accessibility_service.dart';
import 'package:keyhelp/core/services/script_recorder.dart';
import 'package:keyhelp/core/repositories/script_repository.dart';
import 'package:keyhelp/shared/widgets/touch_recorder.dart';
import 'package:keyhelp/shared/widgets/recording_overlay.dart';
import 'package:keyhelp/shared/widgets/recording_preview.dart';

final recorderProvider = Provider<ScriptRecorder>((ref) {
  return ScriptRecorder();
});

class RecordPage extends ConsumerStatefulWidget {
  const RecordPage({super.key});

  @override
  ConsumerState<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends ConsumerState<RecordPage> {
  final TextEditingController _nameController = TextEditingController();
  bool _isRecording = false;
  int _actionCount = 0;
  String _duration = '00:00:00';
  DateTime? _startTime;
  Timer? _timer;
  StreamSubscription? _eventSubscription;
  final AccessibilityService _accessibilityService = AccessibilityService();

  @override
  void initState() {
    super.initState();
    _nameController.text = '脚本_${DateTime.now().millisecondsSinceEpoch}';
    _setupAccessibilityListener();
  }

  void _setupAccessibilityListener() {
    _eventSubscription = _accessibilityService.eventStream.listen((event) {
      if (!_isRecording) return;

      final eventType = (event['eventType'] as String? ?? '').toLowerCase();
      final bounds = event['bounds'] as Map?;
      final packageName = event['packageName'] as String? ?? '';

      if (eventType != 'click') return;
      if (packageName == 'com.keyhelp.app')
        return; // TouchRecorder 会处理当前 app 的事件

      if (bounds != null) {
        final left = bounds['left'] as int? ?? 0;
        final top = bounds['top'] as int? ?? 0;
        final right = bounds['right'] as int? ?? 0;
        final bottom = bounds['bottom'] as int? ?? 0;

        if (left > 0 || top > 0 || right > 0 || bottom > 0) {
          // 计算中心坐标
          final centerX = (left + right) / 2;
          final centerY = (top + bottom) / 2;

          // 使用固定屏幕尺寸进行归一化（避免后台获取不准）
          // 1080x2400 是常见的屏幕分辨率
          const screenWidth = 1080.0;
          const screenHeight = 2400.0;

          // 归一化并限制在 0-1 范围内
          final normalizedX = (centerX / screenWidth).clamp(0.0, 1.0);
          final normalizedY = (centerY / screenHeight).clamp(0.0, 1.0);

          final recorder = ref.read(recorderProvider);
          recorder.recordTap(normalizedX, normalizedY, DateTime.now());

          setState(() {
            _actionCount++;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _timer?.cancel();
    _eventSubscription?.cancel();
    super.dispose();
  }

  void _toggleRecording() {
    final recorder = ref.read(recorderProvider);

    if (recorder.isRecording) {
      recorder.stopRecording();
      _timer?.cancel();
      setState(() {
        _isRecording = false;
        _duration = '00:00:00';
      });
    } else {
      _startTime = DateTime.now();
      recorder.startRecording();
      setState(() {
        _isRecording = true;
        _actionCount = 0;
        _duration = '00:00:00';
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_startTime == null) return;
        final durationVal = DateTime.now().difference(_startTime!);
        setState(() {
          _duration = _formatDuration(durationVal);
        });
      });
    }
  }

  void _onTap(double x, double y, DateTime timestamp) {
    if (!_isRecording) return;

    final recorder = ref.read(recorderProvider);
    recorder.recordTap(x, y, timestamp);

    setState(() {
      _actionCount++;
    });
  }

  void _onSwipe(
    double startX,
    double startY,
    double endX,
    double endY,
    DateTime timestamp,
  ) {
    if (!_isRecording) return;

    final recorder = ref.read(recorderProvider);
    recorder.recordSwipe(startX, startY, endX, endY, timestamp);

    setState(() {
      _actionCount++;
    });
  }

  void _onLongPress(double x, double y, DateTime timestamp) {
    if (!_isRecording) return;

    final recorder = ref.read(recorderProvider);
    recorder.recordLongPress(x, y, timestamp);

    setState(() {
      _actionCount++;
    });
  }

  void _onPositionChanged(int index, double newX, double newY) {
    final recorder = ref.read(recorderProvider);
    final actions = recorder.actions;

    if (index >= 0 && index < actions.length) {
      final action = actions[index];
      action.x = newX;
      action.y = newY;
      setState(() {});
    }
  }

  void _showPreview() {
    final recorder = ref.read(recorderProvider);
    debugPrint('预览: recorder.actions.length = ${recorder.actions.length}');
    for (var i = 0; i < recorder.actions.length; i++) {
      final action = recorder.actions[i];
      debugPrint(
          '预览: action[$i] type=${action.type}, x=${action.x}, y=${action.y}');
    }
    if (recorder.actions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无录制内容')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecordingPreview(
          actions: recorder.actions,
          onClear: () {
            recorder.clearRecording();
            setState(() {
              _actionCount = 0;
            });
            Navigator.pop(context);
          },
          onPositionChanged: _onPositionChanged,
        ),
      ),
    );
  }

  Future<void> _saveScript() async {
    final recorder = ref.read(recorderProvider);
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入脚本名称')),
      );
      return;
    }

    if (recorder.actions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有录制任何动作')),
      );
      return;
    }

    final script = recorder.createScript(name);

    await ScriptRepository.instance.saveScript(script);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('脚本已保存: ${script.name}')),
      );

      setState(() {
        _isRecording = false;
        _actionCount = 0;
        _duration = '00:00:00';
      });

      Navigator.pop(context);
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return RecordingOverlay(
      isRecording: _isRecording,
      child: TouchRecorder(
        isRecording: _isRecording,
        onTap: _onTap,
        onSwipe: _onSwipe,
        onLongPress: _onLongPress,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('脚本录制'),
            backgroundColor: _isRecording ? Colors.red : null,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '脚本名称',
                    border: OutlineInputBorder(),
                  ),
                  enabled: !_isRecording,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _isRecording
                        ? Colors.red.shade50
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _isRecording
                            ? Icons.fiber_manual_record
                            : Icons.radio_button_unchecked,
                        size: 80,
                        color: _isRecording ? Colors.red : Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isRecording ? '录制中...' : '未录制',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _duration,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '已录制 $_actionCount 个动作',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _toggleRecording,
                      icon: Icon(_isRecording ? Icons.stop : Icons.play_arrow),
                      label: Text(_isRecording ? '停止' : '开始'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isRecording ? Colors.red : Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                    if (!_isRecording && _actionCount > 0)
                      ElevatedButton.icon(
                        onPressed: _showPreview,
                        icon: const Icon(Icons.visibility),
                        label: const Text('预览'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (!_isRecording && _actionCount > 0)
                      ElevatedButton.icon(
                        onPressed: _saveScript,
                        icon: const Icon(Icons.save),
                        label: const Text('保存'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                if (!_isRecording)
                  Column(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 32, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text(
                        '点击"开始"后，在屏幕任意位置执行操作即可录制',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      const Icon(Icons.touch_app, size: 32, color: Colors.red),
                      const SizedBox(height: 8),
                      Text(
                        '正在录制您的操作...',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.red,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '点击屏幕任意位置',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.red[300],
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
