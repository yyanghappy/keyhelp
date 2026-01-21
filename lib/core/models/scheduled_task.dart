import 'package:hive/hive.dart';

part 'scheduled_task.g.dart';

@HiveType(typeId: 3)
class ScheduledTask extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String scriptId;

  @HiveField(2)
  DateTime? executeAt;

  @HiveField(3)
  String? cron;

  @HiveField(4)
  bool enabled;

  @HiveField(5)
  DateTime createdAt;

  ScheduledTask({
    required this.id,
    required this.scriptId,
    this.executeAt,
    this.cron,
    required this.enabled,
    required this.createdAt,
  });

  ScheduledTask copyWith({
    String? id,
    String? scriptId,
    DateTime? executeAt,
    String? cron,
    bool? enabled,
    DateTime? createdAt,
  }) {
    return ScheduledTask(
      id: id ?? this.id,
      scriptId: scriptId ?? this.scriptId,
      executeAt: executeAt ?? this.executeAt,
      cron: cron ?? this.cron,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
