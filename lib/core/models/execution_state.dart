import 'package:keyhelp/core/models/action.dart';

enum ExecutionStatus {
  idle,
  running,
  paused,
  completed,
  failed,
}

class ExecutionState {
  final ExecutionStatus status;
  final int currentIndex;
  final int totalActions;
  final ScriptAction? currentAction;
  final String? errorMessage;
  final Duration elapsedTime;
  final List<ExecutionLog> logs;
  final int currentLoop;
  final int totalLoops;
  final bool isLooping;

  ExecutionState({
    this.status = ExecutionStatus.idle,
    this.currentIndex = 0,
    this.totalActions = 0,
    this.currentAction,
    this.errorMessage,
    this.elapsedTime = Duration.zero,
    this.logs = const [],
    this.currentLoop = 1,
    this.totalLoops = 0,
    this.isLooping = false,
  });

  double get progress {
    if (totalActions == 0) return 0.0;

    if (isLooping && totalLoops > 0) {
      final totalSteps = totalActions * totalLoops;
      final completedSteps = (currentLoop - 1) * totalActions + currentIndex;
      return completedSteps / totalSteps;
    }

    return currentIndex / totalActions;
  }

  ExecutionState copyWith({
    ExecutionStatus? status,
    int? currentIndex,
    int? totalActions,
    ScriptAction? currentAction,
    String? errorMessage,
    Duration? elapsedTime,
    List<ExecutionLog>? logs,
    int? currentLoop,
    int? totalLoops,
    bool? isLooping,
  }) {
    return ExecutionState(
      status: status ?? this.status,
      currentIndex: currentIndex ?? this.currentIndex,
      totalActions: totalActions ?? this.totalActions,
      currentAction: currentAction ?? this.currentAction,
      errorMessage: errorMessage ?? this.errorMessage,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      logs: logs ?? this.logs,
      currentLoop: currentLoop ?? this.currentLoop,
      totalLoops: totalLoops ?? this.totalLoops,
      isLooping: isLooping ?? this.isLooping,
    );
  }
}

class ExecutionLog {
  final DateTime timestamp;
  final int actionIndex;
  final ScriptAction action;
  final String message;
  final bool isSuccess;

  ExecutionLog({
    required this.timestamp,
    required this.actionIndex,
    required this.action,
    required this.message,
    required this.isSuccess,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'actionIndex': actionIndex,
      'actionType': action.type.toString(),
      'message': message,
      'isSuccess': isSuccess,
    };
  }
}
