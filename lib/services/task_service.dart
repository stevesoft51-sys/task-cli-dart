import 'dart:async';
import 'dart:math';
import '../exceptions/task_exceptions.dart';
import '../models/priority.dart';
import '../models/task.dart';
import '../models/task_extensions.dart';
import '../repositories/task_repository.dart';

enum SortBy { priority, date }

class TaskService {
  final TaskRepository _repository;

  TaskService._(this._repository);

  static Future<TaskService> create({TaskRepository? repository}) async {
    final repo = repository ?? await TaskRepository.create();
    return TaskService._(repo);
  }

  Stream<Task> get taskChanges => _repository.changes;

  Future<List<Task>> listTasks({SortBy sortBy = SortBy.priority}) async {
    final tasks = await _repository.getAll();
    final sorted = [...tasks];
    return switch (sortBy) {
      SortBy.date => sorted.sortedByDate(),
      SortBy.priority => sorted.sortedByPriority(),
    };
  }

  Future<Task> addTask(String title, String priorityStr,
      {DateTime? dueDate, bool isUrgent = false}) async {
    if (!title.isValidTaskTitle) {
      throw TaskValidationException('Le titre ne peut pas etre vide.');
    }

    final priority = Priority.fromString(priorityStr);
    final id = _generateId();

    final task = isUrgent
        ? UrgentTask(id: id, title: title.trim(), priority: priority, dueDate: dueDate)
        : RegularTask(id: id, title: title.trim(), priority: priority, dueDate: dueDate);

    await _repository.add(task);
    return task;
  }

  Future<void> markCompleted(String id) async {
    final task = await _repository.getById(id);
    if (task == null) throw TaskNotFoundException(id);
    task.markCompleted();
    await _repository.update(task);
  }

  Future<void> deleteTask(String id) async {
    await _repository.delete(id);
  }

  Future<List<Task>> filterTasks(bool Function(Task) predicate) async {
    final all = await _repository.getAll();
    return all.where(predicate).toList();
  }

  Future<void> forEachTask(void Function(Task) action) async {
    final all = await _repository.getAll();
    all.forEach(action);
  }

  Future<({int total, int completed, int pending, int urgent, double rate})> getStats() async {
    final all = await _repository.getAll();
    return all.stats;
  }

  Future<String> joinAllTaskTitles() async {
    final all = await _repository.getAll();
    return all.fold<String>('', (acc, t) => acc.isEmpty ? t.title : '$acc, ${t.title}');
  }

  String _generateId() {
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }

  Future<int> get pendingCount async {
    final all = await _repository.getAll();
    return all.pendingTasks.length;
  }

  Future<List<Task>> get urgentOverdueTasks async {
    final all = await _repository.getAll();
    return all.overdueTasks;
  }
}
