import '../models/task.dart';
import '../exceptions/task_exceptions.dart';
import '../services/json_storage.dart';
import 'repository.dart';

class TaskRepository extends Repository<Task> {
  final JsonStorage _storage;
  List<Task> _tasks = [];

  TaskRepository({JsonStorage? storage}) : _storage = storage ?? JsonStorage() {
    _load();
  }

  void _load() {
    final data = _storage.read();
    _tasks = data.map((json) => Task.fromJson(json)).toList();
  }

  void _save() {
    _storage.write(_tasks.map((t) => t.toJson()).toList());
  }

  @override
  List<Task> getAll() => List.unmodifiable(_tasks);

  @override
  Task? getById(String id) {
    try {
      return _tasks.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  void add(Task item) {
    _tasks.add(item);
    _save();
  }

  @override
  void update(Task item) {
    final index = _tasks.indexWhere((t) => t.id == item.id);
    if (index == -1) throw TaskNotFoundException(item.id);
    _tasks[index] = item;
    _save();
  }

  @override
  void delete(String id) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) throw TaskNotFoundException(id);
    _tasks.removeAt(index);
    _save();
  }
}
