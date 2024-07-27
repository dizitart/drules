import 'dart:convert';
import 'dart:io';

import 'package:drules/drules.dart';

/// A rule repository that loads rules from file system.
///
/// The repository can load rules from a list of file names or from a directory.
/// The rules are expected to be in JSON format.
///
/// If [fileNames] is provided, the repository will load rules from the files
/// specified in the list. If [directory] is provided, the repository will load
/// rules from all the files in the directory.
///
/// Both [fileNames] and [directory] cannot be empty.
class FileRuleRepository extends JsonRuleRepository {
  /// The list of file names to load rules from.
  final List<String> fileNames;

  /// The directory to load rules from.
  final String directory;

  FileRuleRepository({
    this.fileNames = const [],
    this.directory = '',
  }) : assert(fileNames.isNotEmpty || directory.isNotEmpty);

  @override
  Stream<String> loadJsonRules() async* {
    if (fileNames.isNotEmpty) {
      for (final fileName in fileNames) {
        final file = File(fileName);
        yield await file.readAsString();
      }
    } else {
      final dir = Directory(directory);
      await for (final file in dir.list()) {
        if (file is File) {
          if (file.path.endsWith('.json')) {
            yield await file.readAsString();
          }
        }
      }
    }
  }

  @override
  Future<String?> loadJsonRuleById(String id) async {
    await for (final jsonRule in loadJsonRules()) {
      final ruleMap = jsonDecode(jsonRule);
      if (ruleMap['id'] == id) {
        return jsonRule;
      }
    }
    return null;
  }

  @override
  Stream<String> loadJsonRuleByName(String name) async* {
    await for (final jsonRule in loadJsonRules()) {
      final ruleMap = jsonDecode(jsonRule);
      if (ruleMap['name']?.contains(name) == true) {
        yield jsonRule;
      }
    }
  }

  @override
  Future<void> dispose() {
    return Future.value();
  }
}
