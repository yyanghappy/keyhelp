import 'package:flutter/material.dart';

class TouchRecorder extends StatefulWidget {
  final Widget child;
  final Function(double x, double y, DateTime timestamp)? onTap;
  final Function(double startX, double startY, double endX, double endY,
      DateTime timestamp)? onSwipe;
  final Function(double x, double y, DateTime timestamp)? onLongPress;
  final bool isRecording;

  const TouchRecorder({
    super.key,
    required this.child,
    this.onTap,
    this.onSwipe,
    this.onLongPress,
    this.isRecording = false,
  });

  @override
  State<TouchRecorder> createState() => _TouchRecorderState();
}

class _TouchRecorderState extends State<TouchRecorder> {
  double? _startX;
  double? _startY;
  DateTime? _startTime;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return GestureDetector(
      behavior: widget.isRecording
          ? HitTestBehavior.opaque
          : HitTestBehavior.deferToChild,
      onTapDown: (details) {
        if (!widget.isRecording) return;
        _startX = details.globalPosition.dx;
        _startY = details.globalPosition.dy;
        _startTime = DateTime.now();
      },
      onTapUp: (details) {
        if (!widget.isRecording ||
            _startX == null ||
            _startY == null ||
            _startTime == null) return;

        final Duration duration = DateTime.now().difference(_startTime!);
        final double dx = (details.globalPosition.dx - _startX!).abs();
        final double dy = (details.globalPosition.dy - _startY!).abs();
        final DateTime timestamp = DateTime.now();

        if (duration.inMilliseconds < 200 && dx < 10 && dy < 10) {
          widget.onTap?.call(
            details.globalPosition.dx / size.width,
            details.globalPosition.dy / size.height,
            timestamp,
          );
        } else {
          widget.onSwipe?.call(
            _startX! / size.width,
            _startY! / size.height,
            details.globalPosition.dx / size.width,
            details.globalPosition.dy / size.height,
            timestamp,
          );
        }

        _startX = null;
        _startY = null;
        _startTime = null;
      },
      onLongPressEnd: (details) {
        if (!widget.isRecording) return;
        widget.onLongPress?.call(
          details.globalPosition.dx / size.width,
          details.globalPosition.dy / size.height,
          DateTime.now(),
        );
      },
      child: widget.child,
    );
  }
}
