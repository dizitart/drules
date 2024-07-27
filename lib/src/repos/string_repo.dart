import 'dart:convert';

import 'package:drules/drules.dart';

/// A rule repository that loads rules from a list of strings.
///
/// The repository can load rules from a list of strings. The rules are expected
/// to be in JSON format.
class StringRuleRepository extends JsonRuleRepository {
  /// The list of rules to load.
  final List<String> rules;

  StringRuleRepository(this.rules) : assert(rules.isNotEmpty);

  @override
  Stream<String> loadJsonRules() {
    return Stream.fromIterable(rules);
  }

  @override
  Future<String?> loadJsonRuleById(String id) async {
    for (final rule in rules) {
      final ruleMap = jsonDecode(rule);
      if (ruleMap['id'] == id) {
        return rule;
      }
    }
    return null;
  }

  @override
  Stream<String> loadJsonRuleByName(String name) {
    return Stream.fromIterable(rules.where((rule) {
      final ruleMap = jsonDecode(rule);
      return ruleMap['name']?.contains(name) == true;
    }));
  }

  @override
  Future<void> dispose() {
    return Future.value();
  }
}
