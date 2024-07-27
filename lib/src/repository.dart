import 'dart:convert';

import 'package:drules/drules.dart';
import 'package:drules/src/actions.dart';
import 'package:drules/src/conditions.dart';

/// Represents a repository of rules.
///
/// A rule repository is a collection of rules that can be queried by name or id.
abstract class RuleRepository {
  /// Finds all rules in the repository.
  ///
  /// Returns a list of rules.
  Future<List<Rule>> findAllRules();

  /// Finds a rule by id.
  ///
  /// Returns the rule or null if not found.
  Future<Rule?> findById(String id);

  /// Finds rules by name.
  ///
  /// Returns a list of rules.
  Future<List<Rule>> findByName(String name);

  /// Disposes the repository.
  Future<void> dispose();
}

/// Represents a json based rule repository.
///
/// A json rule repository is a collection of rules stored in json format.
abstract class JsonRuleRepository implements RuleRepository {
  /// Loads all json rules.
  ///
  /// Returns a stream of json rules.
  Stream<String> loadJsonRules();

  /// Loads a json rule by id.
  ///
  /// Returns the json rule or null if not found.
  Future<String?> loadJsonRuleById(String id);

  /// Loads a json rule by name.
  ///
  /// Returns a stream of json rules.
  Stream<String> loadJsonRuleByName(String name);

  @override
  Future<List<Rule>> findAllRules() async {
    var jsonRules = loadJsonRules();
    return _parseRules(jsonRules);
  }

  @override
  Future<Rule?> findById(String id) async {
    var jsonRule = await loadJsonRuleById(id);
    if (jsonRule == null) {
      return null;
    }
    var ruleMap = jsonDecode(jsonRule);
    return Rule.fromJson(ruleMap);
  }

  @override
  Future<List<Rule>> findByName(String name) async {
    var jsonRules = loadJsonRuleByName(name);
    return _parseRules(jsonRules);
  }

  Future<List<Rule>> _parseRules(Stream<String> jsonRules) async {
    var rules = <Rule>[];

    await for (var jsonRule in jsonRules) {
      var ruleMap = jsonDecode(jsonRule);
      var rule = Rule.fromJson(ruleMap);
      rules.add(rule);
    }
    return rules;
  }
}

///@nodoc
class ActionRepository {
  static final ActionRepository _actionRepository =
      ActionRepository._internal();
  final _actionMap = <String, Action>{};

  factory ActionRepository() {
    return _actionRepository;
  }

  ActionRepository._internal() {
    init();
  }

  void init() {
    registerAction(Stop());
    registerAction(Print());
    registerAction(Chain());
    registerAction(Pipe());
    registerAction(Parallel());
    registerAction(ExpressionAction());
  }

  void registerAction(Action action) {
    _actionMap[action.action] = action;
  }

  Action? findAction(String name) {
    return _actionMap[name];
  }

  void dispose() {
    _actionMap.clear();
  }
}

///@nodoc
class ConditionRepository {
  static final ConditionRepository _conditionRepository =
      ConditionRepository._internal();
  final _conditionMap = <String, Condition>{};

  factory ConditionRepository() {
    return _conditionRepository;
  }

  ConditionRepository._internal() {
    init();
  }

  void init() {
    registerCondition(All());
    registerCondition(Any());
    registerCondition(None());
    registerCondition(Eq());
    registerCondition(Neq());
    registerCondition(Gt());
    registerCondition(Gte());
    registerCondition(Lt());
    registerCondition(Lte());
    registerCondition(Not());
    registerCondition(Contains());
    registerCondition(StartsWith());
    registerCondition(EndsWith());
    registerCondition(Matches());
    registerCondition(ExpressionCondition());
  }

  void registerCondition(Condition condition) {
    _conditionMap[condition.operator] = condition;
  }

  Condition? findCondition(String operator) {
    return _conditionMap[operator];
  }

  void dispose() {
    _conditionMap.clear();
  }
}
