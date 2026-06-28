import 'dart:io';
import 'models/priority.dart';
import 'models/task.dart';
import 'services/task_service.dart';

Future<void> main() async {
  final service = await TaskService.create();

  print('=== Gestionnaire de Taches CLI ===');

  // Afficher les stats au demarrage via record
  final stats = await service.getStats();
  print(
    'Stats: ${stats.total} taches, '
    '${stats.completed} terminees, '
    '${stats.pending} en attente, '
    '${stats.urgent} urgentes, '
    '${(stats.rate * 100).toStringAsFixed(1)}% complete\n',
  );

  // S'abonner au flux de changements
  service.taskChanges.listen((task) {
    print('[Notification] Tache modifiee: ${task.title} (${task.type})');
  });

  while (true) {
    print('--- Menu ---');
    print('1. Ajouter une tache');
    print('2. Lister les taches');
    print('3. Filtrer les taches');
    print('4. Statistiques detaillees');
    print('5. Marquer une tache terminee');
    print('6. Supprimer une tache');
    print('7. Quitter');
    stdout.write('Choix : ');

    final choice = stdin.readLineSync()?.trim() ?? '';

    try {
      switch (choice) {
        case '1':
          await _addTask(service);
        case '2':
          await _listTasks(service);
        case '3':
          await _filterTasks(service);
        case '4':
          await _showStats(service);
        case '5':
          await _markCompleted(service);
        case '6':
          await _deleteTask(service);
        case '7':
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

Future<void> _addTask(TaskService service) async {
  stdout.write('Titre : ');
  final title = stdin.readLineSync() ?? '';

  stdout.write('Priorite (low/medium/high) : ');
  final priority = stdin.readLineSync() ?? 'medium';

  stdout.write('Date limite (AAAA-MM-JJ, optionnelle) : ');
  final dueInput = stdin.readLineSync() ?? '';
  final dueDate = dueInput.isNotEmpty ? DateTime.tryParse(dueInput) : null;

  stdout.write('Tache urgente ? (o/n) : ');
  final urgentInput = stdin.readLineSync() ?? 'n';
  final isUrgent = urgentInput.toLowerCase() == 'o';

  final task = await service.addTask(title, priority, dueDate: dueDate, isUrgent: isUrgent);
  final info = task.info;
  print('Ajoutee: ${info.title} (${info.type}, ${info.priority})');
}

Future<void> _listTasks(TaskService service) async {
  stdout.write('Trier par (priority/date) [defaut: priority] : ');
  final sortInput = stdin.readLineSync() ?? 'priority';
  final sortBy = sortInput.toLowerCase() == 'date' ? SortBy.date : SortBy.priority;

  final tasks = await service.listTasks(sortBy: sortBy);
  if (tasks.isEmpty) {
    print('Aucune tache.');
    return;
  }

  print('\nTaches :');
  for (var i = 0; i < tasks.length; i++) {
    final t = tasks[i];
    final type = t is UrgentTask ? 'URGENTE' : 'normale';
    print('${i + 1}. [${t.id}] $t ($type)');
  }
}

Future<void> _filterTasks(TaskService service) async {
  print('\n--- Filtres ---');
  print('1. Taches terminees');
  print('2. Taches en attente');
  print('3. Taches urgentes');
  print('4. Taches en retard');
  print('5. Haute priorite');
  stdout.write('Choix : ');
  final choice = stdin.readLineSync() ?? '';

  List<Task> results;
  switch (choice) {
    case '1':
      results = await service.filterTasks((t) => t.isCompleted);
    case '2':
      results = await service.filterTasks((t) => !t.isCompleted);
    case '3':
      results = await service.filterTasks((t) => t is UrgentTask);
    case '4':
      results = await service.filterTasks((t) => t is UrgentTask && t.isOverdue);
    case '5':
      results = await service.filterTasks((t) => t.priority == Priority.high);
    default:
      print('Filtre invalide.');
      return;
  }

  if (results.isEmpty) {
    print('Aucun resultat.');
    return;
  }

  // Utiliser collection-for et spread
  final display = [
    for (var i = 0; i < results.length; i++) '${i + 1}. ${results[i]}',
    ...['', 'Total: ${results.length} tache(s)'],
  ];
  print('\nResultats :');
  display.forEach(print);
}

Future<void> _showStats(TaskService service) async {
  final stats = await service.getStats();
  print('\n--- Statistiques ---');
  print('Total: ${stats.total}');
  print('Terminees: ${stats.completed}');
  print('En attente: ${stats.pending}');
  print('Urgentes: ${stats.urgent}');
  print('Taux d\'achevement: ${(stats.rate * 100).toStringAsFixed(1)}%');

  final titles = await service.joinAllTaskTitles();
  if (titles.isNotEmpty) {
    print('Toutes les taches: $titles');
  }
}

Future<void> _markCompleted(TaskService service) async {
  stdout.write('ID de la tache a marquer terminee : ');
  final id = stdin.readLineSync() ?? '';
  await service.markCompleted(id);
  print('Tache marquee terminee.');
}

Future<void> _deleteTask(TaskService service) async {
  stdout.write('ID de la tache a supprimer : ');
  final id = stdin.readLineSync() ?? '';
  await service.deleteTask(id);
  print('Tache supprimee.');
}
