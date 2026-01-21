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

  ExecutionState({
    this.status = ExecutionStatus.idle,
    this.currentIndex = 0,
    this.totalActions = 0,
    this.currentAction,
    this.errorMessage,
    this.elapsedTime = Duration.zero,
    this.logs = const [],
  });

  double get progress => totalActions > 0 ? currentIndex / totalActions : 0.0;

  ExecutionState copyWith({
    ExecutionStatus? status,
    int? currentIndex,
    int? totalActions,
    ScriptAction? currentAction,
    String? errorMessage,
    Duration? elapsedTime,
    List<ExecutionLog>? logs,
  }) {
    return ExecutionState(
      status: status ?? this.status,
      currentIndex: currentIndex ?? this.currentIndex,
      totalActions: totalActions ?? this.totalActions,
      currentAction: currentAction ?? this.currentAction,
      errorMessage: errorMessage ?? this.errorMessage,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      logs: logs ?? this.logs,
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
