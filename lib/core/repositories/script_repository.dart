import 'package:hive/hive.dart';
import 'package:keyhelp/core/models/script.dart';

class ScriptRepository {
  static ScriptRepository? _instance;
  static ScriptRepository get instance {
    _instance ??= ScriptRepository._internal();
    return _instance!;
  }
  ScriptRepository._internal();

  Future<Box<Script>> get _box async => Hive.openBox<Script>('scripts');

  Future<List<Script>> getAllScripts() async {
    final box = await _box;
    return box.values.toList();
  }

  Future<Script?> getScript(String id) async {
    final box = await _box;
    return box.get(id);
  }

  Future<void> saveScript(Script script) async {
    final box = await _box;
    await box.put(script.id, script);
  }

  Future<void> deleteScript(String id) async {
    final box = await _box;
    await box.delete(id);
  }

  Future<void> deleteAllScripts() async {
    final box = await _box;
    await box.clear();
  }
}
