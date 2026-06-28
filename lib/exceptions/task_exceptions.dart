class TaskNotFoundException implements Exception {
  final String taskId;
  TaskNotFoundException(this.taskId);

  @override
  String toString() => 'Tâche introuvable : $taskId';
}

class InvalidPriorityException implements Exception {
  final String value;
  InvalidPriorityException(this.value);

  @override
  String toString() => 'Priorité invalide : $value. Utilisez low, medium ou high.';
}

class TaskValidationException implements Exception {
  final String message;
  TaskValidationException(this.message);

  @override
  String toString() => 'Erreur de validation : $message';
}
