import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

class JsonStorage {
  final String filePath;

  JsonStorage({String? fileName})
      : filePath = p.join(_getDataDir(), fileName ?? 'tasks.json');

  static String _getDataDir() {
    final dir = Directory(p.join(
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.',
      '.task_cli',
    ));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir.path;
  }

  List<Map<String, dynamic>> read() {
    final file = File(filePath);
    if (!file.existsSync()) return [];
    final content = file.readAsStringSync();
    if (content.trim().isEmpty) return [];
    return (jsonDecode(content) as List).cast<Map<String, dynamic>>();
  }

  void write(List<Map<String, dynamic>> data) {
    final file = File(filePath);
    file.writeAsStringSync(jsonEncode(data));
  }
}
