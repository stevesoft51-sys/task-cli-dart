enum Priority {
  low,
  medium,
  high;

  int get level {
    switch (this) {
      case Priority.low:
        return 1;
      case Priority.medium:
        return 2;
      case Priority.high:
        return 3;
    }
  }

  @override
  String toString() => name;

  static Priority fromString(String value) {
    switch (value.toLowerCase()) {
      case 'low':
        return Priority.low;
      case 'medium':
        return Priority.medium;
      case 'high':
        return Priority.high;
      default:
        throw ArgumentError('Priorité invalide : $value. Utilisez low, medium ou high.');
    }
  }
}
