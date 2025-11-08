import 'package:drules/src/rule.dart';
import 'package:template_expressions/template_expressions.dart';

/// Represents a rule context. The rule context is used to evaluate the conditions
/// and execute the actions of a rule.
///
/// A rule context contains information about facts, conditions, and actions that
/// are used to evaluate the rules.
class RuleContext {
  final Map<String, dynamic> _context = {};
  final Facts _facts;

  RuleContext({
    Map<String, dynamic> facts = const {},
    List<MemberAccessor> resolve = const [],
  }) : _facts = Facts(facts) {
    _context['resolve'] = resolve;
  }

  /// Returns the current rule ID.
  String? get currentRuleId => _facts._dataMap[ruleId];

  /// Returns the value of a fact with the specified key.
  ///
  /// If the key is not found in the context, the key is evaluated as an expression
  /// using the [ExpressionEvaluator] class.
  dynamic getFact(String key) {
    if (_facts.fields.contains(key)) {
      return _facts[key];
    } else {
      final evaluator = ExpressionEvaluator(
        memberAccessors: getResolve() ?? [],
      );

      final parsed = Expression.parse(key);
      var output = evaluator.eval(
        parsed,
        getFacts(),
        onValueAssigned: (name, value) => addFact(name, value),
      );

      return output;
    }
  }

  /// Returns the list of [MemberAccessor] objects used to access the fields
  /// of a user-defined object.
  dynamic getResolve() {
    return _context['resolve'];
  }

  /// Returns the facts stored in the context.
  Map<String, dynamic> getFacts() {
    return _facts._dataMap;
  }

  /// Adds a fact to the context with the specified key and value.
  void addFact(String key, dynamic value) {
    _facts._dataMap[key] = value;
  }

  void clearFacts() {
    _facts._dataMap.clear();
  }

  /// Returns the error message associated with the current activation.
  dynamic getError() {
    return _facts['error'];
  }
}

/// @nodoc
class Facts {
  final Map<String, dynamic> _dataMap = {};

  Facts(Map<String, dynamic> data) {
    _dataMap.addAll(data);
  }

  dynamic operator [](String field) {
    if (_isEmbedded(field) && !containsKey(field)) {
      return _deepGet(field);
    }
    return _dataMap[field];
  }

  bool containsKey(String key) => _dataMap.containsKey(key);

  Set<String> get fields => _getFieldsInternal(_dataMap, "");

  bool _isEmbedded(String field) {
    return field.contains('.');
  }

  dynamic _deepGet(String field) {
    if (_isEmbedded(field)) {
      return _getByEmbeddedKey(field);
    } else {
      return null;
    }
  }

  dynamic _getByEmbeddedKey(String embeddedKey) {
    var path = embeddedKey.split('.');

    // split the key
    if (path.isEmpty) {
      return null;
    }

    // get current level value and scan to next level using remaining keys
    return _recursiveGet(this[path[0]], path.sublist(1));
  }

  dynamic _recursiveGet(dynamic value, List<String> splits) {
    if (value == null) {
      return null;
    }

    if (splits.isEmpty) {
      return value;
    }

    if (value is Map<String, dynamic>) {
      // if the current level value is map, scan to the next level with remaining keys
      return _recursiveGet(value[splits[0]], splits.sublist(1));
    }

    if (value is Iterable) {
      // if the current level value is an iterable

      // get the first key
      var key = splits[0];
      if (_isInteger(key)) {
        // if the current key is an integer
        int index = _asInteger(key);

        // check index lower bound
        if (index < 0) {
          throw RuleEngineException("Invalid index $index to access fact "
              "inside context");
        }

        // check index upper bound
        if (index >= value.length) {
          throw RuleEngineException("Invalid index $index to access fact "
              "inside context");
        }

        // get the value at the index from the list
        // if there are remaining keys, scan to the next level
        return _recursiveGet(value.elementAt(index), splits.sublist(1));
      } else {
        // if the current key is not an integer, then decompose the
        // list and scan each of the element of the
        // list using remaining keys and return a list of all returned
        // elements from each of the list items.
        return _decompose(value, splits);
      }
    }

    // if no match found return null
    return null;
  }

  List<dynamic> _decompose(Iterable value, List<String> splits) {
    var items = <dynamic>{};

    // iterate each item
    for (var item in value) {
      // scan the item using remaining keys
      var result = _recursiveGet(item, splits);

      if (result != null) {
        if (result is Iterable) {
          // if the result is an iterable, add all items to the list
          items.addAll(result);
        } else {
          // if the result is not an iterable, add the result to the list
          items.add(result);
        }
      }
    }

    return items.toList();
  }

  bool _isInteger(String value) {
    if (value.isEmpty) {
      return false;
    }
    return int.tryParse(value) != null;
  }

  int _asInteger(String value) {
    var result = int.tryParse(value);
    if (result == null) return -1;
    return result;
  }

  Set<String> _getFieldsInternal(Map<String, dynamic> dataMap, String prefix) {
    var fields = <String>{};

    // iterate top level keys
    for (var pair in dataMap.entries) {
      var value = pair.value;
      if (value is Map<String, dynamic>) {
        // if the value is a document, traverse its fields recursively,
        // prefix would be the field name of the document
        if (prefix.isEmpty) {
          // level-1 fields
          fields.addAll(_getFieldsInternal(value, pair.key));
        } else {
          // level-n fields, separated by field separator
          fields.addAll(_getFieldsInternal(
              value,
              "$prefix"
              ".${pair.key}"));
        }
      } else {
        // if there is no more embedded document, add the field to the list
        // and if this is an embedded document then prefix its name by parent fields,
        // separated by field separator
        if (prefix.isEmpty) {
          fields.add(pair.key);
        } else {
          fields.add("$prefix.${pair.key}");
        }
      }
    }
    return fields;
  }
}
