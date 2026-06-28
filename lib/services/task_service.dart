import 'dart:math';
import '../exceptions/task_exceptions.dart';
import '../models/priority.dart';
import '../models/task.dart';
import '../repositories/task_repository.dart';

enum SortBy { priority, date }

class TaskService {
  final TaskRepository _repository;

  TaskService({TaskRepository? repository})
      : _repository = repository ?? TaskRepository();

  Task addTask(String title, String priorityStr, {DateTime? dueDate, bool isUrgent = false}) {
    if (title.trim().isEmpty) {
      throw TaskValidationException('Le titre ne peut pas être vide.');
    }

    final priority = Priority.fromString(priorityStr);
    final id = _generateId();

    final task = isUrgent
        ? UrgentTask(
            id: id,
            title: title.trim(),
            priority: priority,
            dueDate: dueDate,
          )
        : RegularTask(
            id: id,
            title: title.trim(),
            priority: priority,
            dueDate: dueDate,
          );

    _repository.add(task);
    return task;
  }

  List<Task> listTasks({SortBy sortBy = SortBy.priority}) {
    final tasks = List<Task>.from(_repository.getAll());
    if (sortBy == SortBy.date) {
      tasks.sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
    } else {
      tasks.sort((a, b) {
        final priorityCompare = b.priority.level.compareTo(a.priority.level);
        if (priorityCompare != 0) return priorityCompare;
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
    }
    return tasks;
  }

  void markCompleted(String id) {
    final task = _repository.getById(id);
    if (task == null) throw TaskNotFoundException(id);
    task.markCompleted();
    _repository.update(task);
  }

  void deleteTask(String id) {
    _repository.delete(id);
  }

  String _generateId() {
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }
}
