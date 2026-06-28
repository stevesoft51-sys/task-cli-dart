import '../exceptions/task_exceptions.dart';

enum Priority {
  low,
  medium,
  high;

  int get level => switch (this) {
    Priority.low => 1,
    Priority.medium => 2,
    Priority.high => 3,
  };

  static Priority fromString(String value) => switch (value.toLowerCase()) {
    'low' => Priority.low,
    'medium' => Priority.medium,
    'high' => Priority.high,
    _ => throw InvalidPriorityException(value),
  };

  @override
  String toString() => name;
}
