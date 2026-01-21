import 'package:hive/hive.dart';
import 'action.dart';

part 'script.g.dart';

@HiveType(typeId: 0)
class Script extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  List<ScriptAction> actions;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  int durationMs;

  Script({
    required this.id,
    required this.name,
    required this.actions,
    required this.createdAt,
    required this.durationMs,
  });

  Script copyWith({
    String? id,
    String? name,
    List<ScriptAction>? actions,
    DateTime? createdAt,
    int? durationMs,
  }) {
    return Script(
      id: id ?? this.id,
      name: name ?? this.name,
      actions: actions ?? this.actions,
      createdAt: createdAt ?? this.createdAt,
      durationMs: durationMs ?? this.durationMs,
    );
  }

  Duration get duration => Duration(milliseconds: durationMs);
}
