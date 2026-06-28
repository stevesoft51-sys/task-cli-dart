import 'dart:io';
import 'models/task.dart';
import 'services/task_service.dart';

void main() {
  final service = TaskService();
  print('=== Gestionnaire de Tâches CLI ===');

  while (true) {
    print('\n--- Menu ---');
    print('1. Ajouter une tâche');
    print('2. Lister les tâches');
    print('3. Marquer une tâche comme terminée');
    print('4. Supprimer une tâche');
    print('5. Quitter');
    stdout.write('Choix : ');

    final choice = stdin.readLineSync()?.trim() ?? '';

    try {
      switch (choice) {
        case '1':
          _addTask(service);
        case '2':
          _listTasks(service);
        case '3':
          _markCompleted(service);
        case '4':
          _deleteTask(service);
        case '5':
          print('Au revoir !');
          return;
        default:
          print('Choix invalide.');
      }
    } catch (e) {
      print('Erreur : $e');
    }
  }
}

void _addTask(TaskService service) {
  stdout.write('Titre : ');
  final title = stdin.readLineSync() ?? '';

  stdout.write('Priorité (low/medium/high) : ');
  final priority = stdin.readLineSync() ?? 'medium';

  stdout.write('Date limite (AAAA-MM-JJ, optionnelle) : ');
  final dueInput = stdin.readLineSync() ?? '';
  final dueDate = dueInput.isNotEmpty ? DateTime.tryParse(dueInput) : null;

  stdout.write('Tâche urgente ? (o/n) : ');
  final urgentInput = stdin.readLineSync() ?? 'n';
  final isUrgent = urgentInput.toLowerCase() == 'o';

  final task = service.addTask(title, priority, dueDate: dueDate, isUrgent: isUrgent);
  print('Tâche ajoutée : ${task.title} (${task.type})');
}

void _listTasks(TaskService service) {
  stdout.write('Trier par (priority/date) [defaut: priority] : ');
  final sortInput = stdin.readLineSync() ?? 'priority';
  final sortBy = sortInput.toLowerCase() == 'date' ? SortBy.date : SortBy.priority;

  final tasks = service.listTasks(sortBy: sortBy);
  if (tasks.isEmpty) {
    print('Aucune tâche.');
    return;
  }

  print('\nTâches :');
  for (var i = 0; i < tasks.length; i++) {
    final t = tasks[i];
    final type = t is UrgentTask ? 'URGENTE' : 'normale';
    print('${i + 1}. [${t.id}] $t ($type)');
  }
}

void _markCompleted(TaskService service) {
  stdout.write('ID de la tâche à marquer terminée : ');
  final id = stdin.readLineSync() ?? '';
  service.markCompleted(id);
  print('Tâche marquée comme terminée.');
}

void _deleteTask(TaskService service) {
  stdout.write('ID de la tâche à supprimer : ');
  final id = stdin.readLineSync() ?? '';
  service.deleteTask(id);
  print('Tâche supprimée.');
}
