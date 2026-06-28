import '../models/priority.dart';

abstract interface class Prioritizable {
  Priority get priority;
  DateTime? get dueDate;
}
