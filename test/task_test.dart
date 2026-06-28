import 'dart:io';
import 'package:test/test.dart';
import 'package:task_cli/exceptions/task_exceptions.dart';
import 'package:task_cli/interfaces/prioritizable.dart';
import 'package:task_cli/models/priority.dart';
import 'package:task_cli/models/task.dart';
import 'package:task_cli/models/task_extensions.dart';
import 'package:task_cli/repositories/task_repository.dart';
import 'package:task_cli/services/json_storage.dart';
import 'package:task_cli/services/task_service.dart';

JsonStorage _createTestStorage() {
  final dir = Directory.systemTemp.createTempSync('task_cli_test_');
  return JsonStorage(fileName: '${dir.path}/test_tasks.json');
}

Future<TaskRepository> _createEmptyRepo({JsonStorage? storage}) async {
  final s = storage ?? _createTestStorage();
  await s.write([]);
  return TaskRepository.create(storage: s);
}

void main() {
  group('Priority (switch expressions Dart 3)', () {
    test('fromString retourne le bon enum', () {
      expect(Priority.fromString('low'), equals(Priority.low));
      expect(Priority.fromString('medium'), equals(Priority.medium));
      expect(Priority.fromString('high'), equals(Priority.high));
    });

    test('fromString est insensible a la casse', () {
      expect(Priority.fromString('Low'), equals(Priority.low));
      expect(Priority.fromString('MEDIUM'), equals(Priority.medium));
    });

    test('fromString leve InvalidPriorityException', () {
      expect(() => Priority.fromString('urgent'), throwsA(isA<InvalidPriorityException>()));
    });

    test('level retourne le bon poids (switch expression)', () {
      expect(Priority.low.level, equals(1));
      expect(Priority.medium.level, equals(2));
      expect(Priority.high.level, equals(3));
    });
  });

  group('UrgentTask', () {
    test('isOverdue true si echeance passee', () {
      final task = UrgentTask(
        id: '1', title: 'Test', priority: Priority.high,
        dueDate: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(task.isOverdue, isTrue);
    });

    test('isOverdue false si echeance future', () {
      final task = UrgentTask(
        id: '2', title: 'Test', priority: Priority.high,
        dueDate: DateTime.now().add(const Duration(days: 1)),
      );
      expect(task.isOverdue, isFalse);
    });

    test('serialisation et deserialisation JSON', () {
      final task = UrgentTask(
        id: 'urg1', title: 'Urgente', priority: Priority.high,
        dueDate: DateTime(2026, 7, 1), reminderMinutes: 15,
      );
      final json = task.toJson();
      final restored = Task.fromJson(json) as UrgentTask;
      expect(restored.id, equals('urg1'));
      expect(restored.reminderMinutes, equals(15));
    });

    test('toString utilise pattern matching (switch)', () {
      final task = UrgentTask(
        id: '3', title: 'Test', priority: Priority.high,
        dueDate: DateTime.now().add(const Duration(days: 1)),
      );
      expect(task.toString(), contains('Rappel: 30min'));
    });
  });

  group('Task info record', () {
    test('info retourne un record avec les bonnes valeurs', () {
      final task = RegularTask(id: 'r1', title: 'Test', priority: Priority.medium);
      final info = task.info;
      expect(info.type, equals('regular'));
      expect(info.title, equals('Test'));
      expect(info.priority, equals(Priority.medium));
      expect(info.isDone, isFalse);
    });
  });

  group('Prioritizable interface', () {
    test('Task implemente Prioritizable', () {
      final task = RegularTask(id: '1', title: 'Test', priority: Priority.high);
      expect(task, isA<Prioritizable>());
      expect((task as Prioritizable).priority, equals(Priority.high));
    });

    test('UrgentTask implemente Prioritizable', () {
      final task = UrgentTask(id: '2', title: 'Urgent', priority: Priority.medium);
      expect(task, isA<Prioritizable>());
    });
  });

  group('TaskListExtensions', () {
    test('stats retourne un record correct', () {
      final tasks = [
        RegularTask(id: '1', title: 'A', priority: Priority.high, isCompleted: true),
        RegularTask(id: '2', title: 'B', priority: Priority.medium),
        UrgentTask(id: '3', title: 'C', priority: Priority.high),
      ];
      final stats = tasks.stats;
      expect(stats.total, equals(3));
      expect(stats.completed, equals(1));
      expect(stats.pending, equals(2));
      expect(stats.urgent, equals(1));
      expect(stats.rate, closeTo(1 / 3, 0.01));
    });

    test('completedTasks / pendingTasks', () {
      final tasks = [
        RegularTask(id: '1', title: 'A', priority: Priority.low, isCompleted: true),
        RegularTask(id: '2', title: 'B', priority: Priority.medium),
      ];
      expect(tasks.completedTasks.length, equals(1));
      expect(tasks.pendingTasks.length, equals(1));
    });

    test('sortedByPriority trie correctement', () {
      final tasks = [
        RegularTask(id: '1', title: 'Low', priority: Priority.low),
        RegularTask(id: '2', title: 'High', priority: Priority.high),
        RegularTask(id: '3', title: 'Medium', priority: Priority.medium),
      ];
      final sorted = tasks.sortedByPriority();
      expect(sorted[0].priority, equals(Priority.high));
      expect(sorted[1].priority, equals(Priority.medium));
      expect(sorted[2].priority, equals(Priority.low));
    });
  });

  group('StringTaskExtensions', () {
    test('isValidTaskTitle', () {
      expect(''.isValidTaskTitle, isFalse);
      expect('  '.isValidTaskTitle, isFalse);
      expect('Hello'.isValidTaskTitle, isTrue);
    });

    test('capitalized', () {
      expect('hello'.capitalized, equals('Hello'));
      expect('HELLO'.capitalized, equals('Hello'));
    });
  });

  group('TaskService (async, higher-order, records)', () {
    late TaskService service;
    late JsonStorage storage;

    setUp(() async {
      storage = _createTestStorage();
      await storage.write([]);
      final repo = await _createEmptyRepo(storage: storage);
      service = await TaskService.create(repository: repo);
    });

    test('ajouter une tache', () async {
      final task = await service.addTask('Test task', 'high');
      expect(task.title, equals('Test task'));
      expect(task.priority, equals(Priority.high));
    });

    test('ajouter une tache urgente', () async {
      final task = await service.addTask('Urgent task', 'high', isUrgent: true);
      expect(task, isA<UrgentTask>());
    });

    test('titre vide leve TaskValidationException', () async {
      await expectLater(
        () => service.addTask('  ', 'medium'),
        throwsA(isA<TaskValidationException>()),
      );
    });

    test('lister taches triees par priorite', () async {
      await service.addTask('Low', 'low');
      await service.addTask('High', 'high');
      await service.addTask('Medium', 'medium');

      final tasks = await service.listTasks(sortBy: SortBy.priority);
      expect(tasks[0].priority, equals(Priority.high));
      expect(tasks[1].priority, equals(Priority.medium));
      expect(tasks[2].priority, equals(Priority.low));
    });

    test('marquer terminee', () async {
      final task = await service.addTask('Completable', 'low');
      await service.markCompleted(task.id);
      final tasks = await service.listTasks();
      expect(tasks.first.isCompleted, isTrue);
    });

    test('marquer inexistante leve TaskNotFoundException', () async {
      await expectLater(
        () => service.markCompleted('nonexistent'),
        throwsA(isA<TaskNotFoundException>()),
      );
    });

    test('supprimer une tache', () async {
      final task = await service.addTask('Deletable', 'medium');
      await service.deleteTask(task.id);
      expect(await service.listTasks(), isEmpty);
    });

    test('filterTasks avec predicate (higher-order)', () async {
      await service.addTask('A', 'high', isUrgent: true);
      await service.addTask('B', 'low');
      await service.addTask('C', 'high');

      final urgent = await service.filterTasks((t) => t is UrgentTask);
      expect(urgent.length, equals(1));
    });

    test('getStats retourne un record', () async {
      await service.addTask('A', 'high');
      await service.addTask('B', 'low');
      final stats = await service.getStats();
      expect(stats.total, equals(2));
      expect(stats.completed, equals(0));
      expect(stats.rate, equals(0.0));
    });

    test('joinAllTaskTitles utilise fold', () async {
      await service.addTask('Alpha', 'high');
      await service.addTask('Beta', 'low');
      final result = await service.joinAllTaskTitles();
      expect(result, contains('Alpha'));
      expect(result, contains('Beta'));
    });

    test('stream emet lors de l ajout', () async {
      final emitted = <Task>[];
      service.taskChanges.listen((t) => emitted.add(t));
      await service.addTask('StreamTest', 'medium');
      await Future.delayed(const Duration(milliseconds: 50));
      expect(emitted.length, equals(1));
      expect(emitted.first.title, equals('StreamTest'));
    });

    test('persistance entre instanciations', () async {
      await service.addTask('Persistent', 'medium');
      await service.addTask('Another', 'high');

      final repo2 = await TaskRepository.create(storage: storage);
      final service2 = await TaskService.create(repository: repo2);
      final tasks = await service2.listTasks();
      expect(tasks.length, equals(2));
    });
  });

  group('JsonStorage avec Isolate', () {
    test('ecrit et lit via Isolate.run', () async {
      final storage = _createTestStorage();
      final data = [{'test': 'value', 'num': 42}];
      await storage.write(data);
      final result = await storage.read();
      expect(result.length, equals(1));
      expect(result[0]['test'], equals('value'));
    });
  });
}
