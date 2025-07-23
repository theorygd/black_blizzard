// log.dart
// Log singleton for recording all game events in English
// Usage: Log().write('message');

part of blackblizzard;

import 'dart:io';

class Log {
  static final Log _instance = Log._internal();
  final List<String> _records = [];
  final String _logFile = 'black_blizzard.log';

  factory Log() {
    return _instance;
  }

  Log._internal();

  void write(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final record = '[$timestamp] $message';
    _records.add(record);
    print('[LOG] $record'); // For debug
  }

  Future<void> flush() async {
    final file = File(_logFile);
    await file.writeAsString(_records.join('\n'), mode: FileMode.write);
  }
}
