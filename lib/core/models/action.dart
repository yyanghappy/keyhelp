import 'package:hive/hive.dart';

part 'action.g.dart';

@HiveType(typeId: 1)
enum ActionType {
  @HiveField(0)
  tap,

  @HiveField(1)
  swipe,

  @HiveField(2)
  longPress,

  @HiveField(3)
  wait,

  @HiveField(4)
  condition,

  @HiveField(5)
  loop,
}

@HiveType(typeId: 2)
class ScriptAction {
  @HiveField(0)
  ActionType type;

  @HiveField(1)
  double? x;

  @HiveField(2)
  double? y;

  @HiveField(3)
  double? endX;

  @HiveField(4)
  double? endY;

  @HiveField(5)
  int? delayMs;

  @HiveField(6)
  String? condition;

  @HiveField(7)
  int? loopCount;

  ScriptAction({
    required this.type,
    this.x,
    this.y,
    this.endX,
    this.endY,
    this.delayMs,
    this.condition,
    this.loopCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'x': x,
      'y': y,
      'endX': endX,
      'endY': endY,
      'delayMs': delayMs,
      'condition': condition,
      'loopCount': loopCount,
    };
  }
}
