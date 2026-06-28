import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
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

  Future<List<Map<String, dynamic>>> read() async {
    final file = File(filePath);
    if (!file.existsSync()) return [];
    final content = await file.readAsString();
    if (content.trim().isEmpty) return [];
    return Isolate.run(() => (jsonDecode(content) as List).cast<Map<String, dynamic>>());
  }

  Future<void> write(List<Map<String, dynamic>> data) async {
    final file = File(filePath);
    final content = await Isolate.run(() => jsonEncode(data));
    await file.writeAsString(content);
  }
}
