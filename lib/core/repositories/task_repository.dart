import 'package:hive/hive.dart';
import 'package:keyhelp/core/models/scheduled_task.dart';

class TaskRepository {
  static TaskRepository? _instance;
  static TaskRepository get instance {
    _instance ??= TaskRepository._internal();
    return _instance!;
  }
  TaskRepository._internal();

  Future<Box<ScheduledTask>> get _box async => Hive.openBox<ScheduledTask>('tasks');

  Future<List<ScheduledTask>> getAllTasks() async {
    final box = await _box;
    return box.values.toList();
  }

  Future<List<ScheduledTask>> getEnabledTasks() async {
    final box = await _box;
    return box.values.where((task) => task.enabled).toList();
  }

  Future<ScheduledTask?> getTask(String id) async {
    final box = await _box;
    return box.get(id);
  }

  Future<void> saveTask(ScheduledTask task) async {
    final box = await _box;
    await box.put(task.id, task);
  }

  Future<void> deleteTask(String id) async {
    final box = await _box;
    await box.delete(id);
  }

  Future<void> deleteAllTasks() async {
    final box = await _box;
    await box.clear();
  }
}
