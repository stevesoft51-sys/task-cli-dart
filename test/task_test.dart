import 'dart:io';
import 'package:test/test.dart';
import 'package:task_cli/exceptions/task_exceptions.dart';
import 'package:task_cli/models/priority.dart';
import 'package:task_cli/models/task.dart';
import 'package:task_cli/repositories/task_repository.dart';
import 'package:task_cli/services/json_storage.dart';
import 'package:task_cli/services/task_service.dart';

JsonStorage _createTestStorage() {
  final dir = Directory.systemTemp.createTempSync('task_cli_test_');
  return JsonStorage(fileName: '${dir.path}/test_tasks.json');
}

void main() {
  group('Priority', () {
    test('fromString retourne le bon enum', () {
      expect(Priority.fromString('low'), equals(Priority.low));
      expect(Priority.fromString('medium'), equals(Priority.medium));
      expect(Priority.fromString('high'), equals(Priority.high));
    });

    test('fromString est insensible à la casse', () {
      expect(Priority.fromString('Low'), equals(Priority.low));
      expect(Priority.fromString('MEDIUM'), equals(Priority.medium));
      expect(Priority.fromString('High'), equals(Priority.high));
    });

    test('fromString lance une erreur pour une valeur invalide', () {
      expect(() => Priority.fromString('urgent'), throwsArgumentError);
    });

    test('level retourne le bon poids', () {
      expect(Priority.low.level, equals(1));
      expect(Priority.medium.level, equals(2));
      expect(Priority.high.level, equals(3));
    });
  });

  group('UrgentTask', () {
    test('est marquée en retard si échéance passée', () {
      final task = UrgentTask(
        id: '1',
        title: 'Urgent',
        priority: Priority.high,
        dueDate: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(task.isOverdue, isTrue);
    });

    test('n\'est pas en retard si échéance future', () {
      final task = UrgentTask(
        id: '2',
        title: 'Future',
        priority: Priority.high,
        dueDate: DateTime.now().add(const Duration(days: 1)),
      );
      expect(task.isOverdue, isFalse);
    });

    test('sérialisation et désérialisation JSON', () {
      final task = UrgentTask(
        id: 'urg1',
        title: 'Tâche urgente',
        priority: Priority.high,
        dueDate: DateTime(2026, 7, 1),
        reminderMinutes: 15,
      );
      final json = task.toJson();
      final restored = Task.fromJson(json) as UrgentTask;
      expect(restored.id, equals('urg1'));
      expect(restored.title, equals('Tâche urgente'));
      expect(restored.priority, equals(Priority.high));
      expect(restored.reminderMinutes, equals(15));
    });
  });

  group('TaskService', () {
    late TaskService service;
    late JsonStorage storage;

    setUp(() {
      storage = _createTestStorage();
      final repository = TaskRepository(storage: storage);
      service = TaskService(repository: repository);
    });

    test('ajouter une tâche régulière', () {
      final task = service.addTask('Test task', 'high');
      expect(task.title, equals('Test task'));
      expect(task.priority, equals(Priority.high));
      expect(task.isCompleted, isFalse);
      expect(task, isA<RegularTask>());
    });

    test('ajouter une tâche urgente', () {
      final task = service.addTask('Urgent task', 'high', isUrgent: true);
      expect(task, isA<UrgentTask>());
    });

    test('ajouter une tâche avec titre vide lève une exception', () {
      expect(
        () => service.addTask('  ', 'medium'),
        throwsA(isA<TaskValidationException>()),
      );
    });

    test('lister les tâches triées par priorité', () {
      service.addTask('Low priority', 'low');
      service.addTask('High priority', 'high');
      service.addTask('Medium priority', 'medium');

      final tasks = service.listTasks(sortBy: SortBy.priority);
      expect(tasks[0].priority, equals(Priority.high));
      expect(tasks[1].priority, equals(Priority.medium));
      expect(tasks[2].priority, equals(Priority.low));
    });

    test('lister les tâches triées par date', () {
      service.addTask('Task 1', 'low', dueDate: DateTime(2026, 12, 31));
      service.addTask('Task 2', 'high', dueDate: DateTime(2026, 6, 15));
      service.addTask('Task 3', 'medium', dueDate: DateTime(2026, 9, 1));

      final tasks = service.listTasks(sortBy: SortBy.date);
      expect(tasks[0].title, equals('Task 2'));
      expect(tasks[1].title, equals('Task 3'));
      expect(tasks[2].title, equals('Task 1'));
    });

    test('marquer une tâche comme terminée', () {
      final task = service.addTask('Completable', 'low');
      service.markCompleted(task.id);
      final tasks = service.listTasks();
      expect(tasks.first.isCompleted, isTrue);
    });

    test('marquer une tâche inexistante lève une exception', () {
      expect(
        () => service.markCompleted('nonexistent'),
        throwsA(isA<TaskNotFoundException>()),
      );
    });

    test('supprimer une tâche', () {
      final task = service.addTask('Deletable', 'medium');
      service.deleteTask(task.id);
      expect(service.listTasks(), isEmpty);
    });

    test('supprimer une tâche inexistante lève une exception', () {
      expect(
        () => service.deleteTask('nonexistent'),
        throwsA(isA<TaskNotFoundException>()),
      );
    });

    test('persistance des tâches entre les instanciations', () {
      service.addTask('Persistent task', 'medium');
      service.addTask('Another task', 'high');

      final service2 = TaskService(repository: TaskRepository(storage: storage));
      final tasks = service2.listTasks();
      expect(tasks.length, equals(2));
    });
  });
}
