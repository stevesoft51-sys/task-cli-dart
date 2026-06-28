# Task CLI — Gestionnaire de tâches en Dart

Application en ligne de commande pour gérer des tâches avec persistance JSON.

## Fonctionnalités

- Ajouter une tâche (titre, priorité, date limite, type urgent/régulier)
- Lister les tâches triées par priorité ou par date
- Marquer une tâche comme terminée
- Supprimer une tâche
- Persistance automatique dans `~/.task_cli/tasks.json`

## Prérequis

- Dart SDK ^3.12.0

## Lancer l'application

```bash
dart run
```

## Lancer les tests

```bash
dart test
```

## Structure du projet

```
lib/
  main.dart              # Point d'entrée CLI
  models/                # Task (abstraite), RegularTask, UrgentTask, Priority
  interfaces/            # Prioritizable
  repositories/          # Repository<T> générique, TaskRepository
  services/              # TaskService, JsonStorage
  exceptions/            # Exceptions personnalisées
test/
  task_test.dart         # Tests unitaires
```
