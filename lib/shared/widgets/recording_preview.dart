import 'package:flutter/material.dart';
import 'package:keyhelp/core/models/action.dart';

class RecordingPreview extends StatelessWidget {
  final List<ScriptAction> actions;
  final VoidCallback onClear;
  final Function(int index, double newX, double newY)? onPositionChanged;

  const RecordingPreview({
    super.key,
    required this.actions,
    required this.onClear,
    this.onPositionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('录制预览'),
        actions: [
          if (actions.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: onClear,
              tooltip: '清空录制',
            ),
        ],
      ),
      body: actions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.touch_app_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无录制内容',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : InteractiveViewer(
              minScale: 0.5,
              maxScale: 3.0,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final height = constraints.maxHeight;

                  return Container(
                    width: width,
                    height: height,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Stack(
                      children: [
                        _buildGrid(),
                        ...actions.asMap().entries.map((entry) {
                          return _buildActionMarker(
                            entry.value,
                            entry.key,
                            width,
                            height,
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            ),
      bottomSheet: actions.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '已录制 ${actions.length} 个动作',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '提示：双击动作可调整位置',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildGrid() {
    return CustomPaint(
      painter: GridPainter(),
    );
  }

  Widget _buildActionMarker(
    ScriptAction action,
    int index,
    double width,
    double height,
  ) {
    return Positioned(
      left: action.x != null ? (action.x! * width - 20) : null,
      top: action.y != null ? (action.y! * height - 20) : null,
      child: GestureDetector(
        onDoubleTap: () => _showEditDialog(action, index),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getActionColor(action.type),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getActionColor(ActionType type) {
    switch (type) {
      case ActionType.tap:
        return Colors.blue;
      case ActionType.swipe:
        return Colors.green;
      case ActionType.longPress:
        return Colors.orange;
      case ActionType.wait:
        return Colors.grey;
      case ActionType.condition:
        return Colors.purple;
      case ActionType.loop:
        return Colors.teal;
    }
  }

  void _showEditDialog(ScriptAction action, int index) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final xController =
        TextEditingController(text: action.x?.toStringAsFixed(2) ?? '0.00');
    final yController =
        TextEditingController(text: action.y?.toStringAsFixed(2) ?? '0.00');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('调整动作 ${index + 1}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: xController,
              decoration: const InputDecoration(
                labelText: 'X 坐标 (0.00-1.00)',
                suffixText: '%',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: yController,
              decoration: const InputDecoration(
                labelText: 'Y 坐标 (0.00-1.00)',
                suffixText: '%',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final newX = double.tryParse(xController.text) ?? action.x ?? 0.0;
              final newY = double.tryParse(yController.text) ?? action.y ?? 0.0;
              onPositionChanged?.call(index, newX, newY);
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 0.5;

    const gridSize = 50.0;

    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
