import 'dart:async';
import '../models/task.dart';
import '../exceptions/task_exceptions.dart';
import '../services/json_storage.dart';
import 'repository.dart';

class TaskRepository extends Repository<Task> {
  final JsonStorage _storage;
  List<Task> _tasks;
  final StreamController<Task> _controller = StreamController<Task>.broadcast();

  TaskRepository._(this._storage, this._tasks);

  static Future<TaskRepository> create({JsonStorage? storage}) async {
    final s = storage ?? JsonStorage();
    final data = await s.read();
    final tasks = data.map((json) => Task.fromJson(json)).toList();
    return TaskRepository._(s, tasks);
  }

  @override
  Stream<Task> get changes => _controller.stream;

  @override
  Future<List<Task>> getAll() async => List.unmodifiable(_tasks);

  @override
  Future<Task?> getById(String id) async {
    try {
      return _tasks.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> add(Task item) async {
    _tasks = [..._tasks, item];
    await _save();
    _controller.add(item);
  }

  @override
  Future<void> update(Task item) async {
    final index = _tasks.indexWhere((t) => t.id == item.id);
    if (index == -1) throw TaskNotFoundException(item.id);
    _tasks = [
      for (var i = 0; i < _tasks.length; i++)
        if (i == index) item else _tasks[i],
    ];
    await _save();
    _controller.add(item);
  }

  @override
  Future<void> delete(String id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) throw TaskNotFoundException(id);
    _tasks = _tasks.where((t) => t.id != id).toList();
    await _save();
  }

  Future<void> _save() async {
    await _storage.write(
      _tasks.map((t) => t.toJson()).toList(),
    );
  }

  void dispose() => _controller.close();
}
