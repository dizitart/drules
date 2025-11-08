import 'dart:async';

import 'package:drules/drules.dart';

/// Type definitions for the enhanced API
typedef ConditionFunction = bool Function(Map<String, dynamic> facts);
typedef ActionCallback = Future<dynamic> Function();
typedef FactProvider = dynamic Function();

/// Enhanced OOP-friendly API for Drules with dynamic fact management
///
/// This class provides a fluent, type-safe alternative to the JSON-based API
/// while maintaining backward compatibility. It's designed for autonomous systems
/// that need to react to environmental changes with automatic fact refresh.
///
/// Features:
/// - Dynamic fact providers that refresh automatically
/// - Type-safe action definitions with condition functions
/// - Non-blocking trigger mechanism
/// - Action chaining support
/// - First match policy per action key
/// - Easy dependency injection integration
class Drules {
  final Map<String, FactProvider> _dynamicFacts = {};
  final Map<String, dynamic> _staticFacts = {};
  final Map<String, _EnhancedAction> _actions = {};
  final RuleContext _context = RuleContext();

  /// Creates a new Drules instance with enhanced OOP-friendly API
  Drules() {
    // Initialize with empty repository that we'll populate dynamically
  }

  /// Adds facts to the context
  ///
  /// Supports both static values and dynamic fact providers:
  /// ```dart
  /// drules.addFacts({
  ///   'staticValue': 42,                           // Static fact
  ///   'dynamicValue': () => service.getCurrentValue(), // Dynamic fact
  /// });
  /// ```
  Drules addFacts(Map<String, dynamic> facts) {
    for (final entry in facts.entries) {
      if (entry.value is Function) {
        _dynamicFacts[entry.key] = entry.value as FactProvider;
      } else {
        _staticFacts[entry.key] = entry.value;
      }
    }
    return this;
  }

  /// Adds a single fact
  Drules addFact(String key, dynamic value) {
    if (value is Function) {
      _dynamicFacts[key] = value as FactProvider;
    } else {
      _staticFacts[key] = value;
    }
    return this;
  }

  /// Adds a type-safe action with condition function
  ///
  /// Example:
  /// ```dart
  /// drules.addAction(
  ///   key: 'lowBatteryAlert',
  ///   condition: (facts) => facts['batteryLevel'] < 20,
  ///   onSuccess: () async {
  ///     await NotificationService.showLowBatteryAlert();
  ///     print('Low battery alert triggered');
  ///   },
  ///   onFail: () => print('Battery level sufficient'),
  /// );
  /// ```
  Drules addAction({
    required String key,
    required ConditionFunction condition,
    ActionCallback? onSuccess,
    ActionCallback? onFail,
  }) {
    _actions[key] = _EnhancedAction(
      key: key,
      condition: condition,
      onSuccess: onSuccess,
      onFail: onFail,
    );
    return this;
  }

  /// Refreshes all dynamic facts by calling their provider functions
  Future<void> _refreshFacts() async {
    // Clear existing facts
    _context.clearFacts();

    // Add static facts
    for (final entry in _staticFacts.entries) {
      _context.addFact(entry.key, entry.value);
    }

    // Refresh dynamic facts
    for (final entry in _dynamicFacts.entries) {
      try {
        final value = entry.value();
        // Handle both sync and async fact providers
        if (value is Future) {
          _context.addFact(entry.key, await value);
        } else {
          _context.addFact(entry.key, value);
        }
      } catch (e) {
        // Graceful handling of fact provider failures
        _context.addFact('${entry.key}_error', e.toString());
      }
    }
  }

  /// Triggers rule evaluation with automatic fact refresh
  ///
  /// Returns a list of results from triggered actions.
  /// Uses first match policy - stops at first matching rule per action key.
  Future<List<ActionResult>> trigger() async {
    await _refreshFacts();

    final results = <ActionResult>[];
    final facts = _context.getFacts();

    // Evaluate each action
    for (final action in _actions.values) {
      try {
        final conditionMet = action.condition(facts);

        if (conditionMet && action.onSuccess != null) {
          final result = await action.onSuccess!();
          results.add(ActionResult(
            output: result,
            exception: null,
          ));
          // First match policy - break after first success
          break;
        } else if (!conditionMet && action.onFail != null) {
          final result = await action.onFail!();
          results.add(ActionResult(
            output: result,
            exception: null,
          ));
        }
      } catch (e, stackTrace) {
        results.add(ActionResult(
          output: null,
          exception: e is Exception ? e : Exception(e.toString()),
          stackTrace: stackTrace,
          shouldContinue: false,
        ));
      }
    }

    return results;
  }

  /// Triggers specific actions by their keys
  ///
  /// Useful for action chaining scenarios:
  /// ```dart
  /// await drules.triggerSpecific(['networkFailover', 'dataUsageMonitor']);
  /// ```
  Future<List<ActionResult>> triggerSpecific(List<String> actionKeys) async {
    await _refreshFacts();

    final results = <ActionResult>[];
    final facts = _context.getFacts();

    for (final key in actionKeys) {
      final action = _actions[key];
      if (action == null) continue;

      try {
        final conditionMet = action.condition(facts);

        if (conditionMet && action.onSuccess != null) {
          final result = await action.onSuccess!();
          results.add(ActionResult(
            output: result,
            exception: null,
          ));
        } else if (!conditionMet && action.onFail != null) {
          final result = await action.onFail!();
          results.add(ActionResult(
            output: result,
            exception: null,
          ));
        }
      } catch (e, stackTrace) {
        results.add(ActionResult(
          output: null,
          exception: e is Exception ? e : Exception(e.toString()),
          stackTrace: stackTrace,
          shouldContinue: false,
        ));
      }
    }

    return results;
  }

  /// Gets current fact values (after refresh)
  Future<Map<String, dynamic>> getCurrentFacts() async {
    await _refreshFacts();
    return _context.getFacts();
  }

  /// Removes an action by key
  Drules removeAction(String key) {
    _actions.remove(key);
    return this;
  }

  /// Removes a fact by key
  Drules removeFact(String key) {
    _staticFacts.remove(key);
    _dynamicFacts.remove(key);
    return this;
  }

  /// Clears all actions
  Drules clearActions() {
    _actions.clear();
    return this;
  }

  /// Clears all facts
  Drules clearFacts() {
    _staticFacts.clear();
    _dynamicFacts.clear();
    return this;
  }

  /// Gets the underlying rule context for advanced scenarios
  RuleContext get context => _context;

  /// Disposes resources
  Future<void> dispose() async {
    _actions.clear();
    _staticFacts.clear();
    _dynamicFacts.clear();
  }
}

/// Internal class representing an enhanced action
class _EnhancedAction {
  final String key;
  final ConditionFunction condition;
  final ActionCallback? onSuccess;
  final ActionCallback? onFail;

  const _EnhancedAction({
    required this.key,
    required this.condition,
    this.onSuccess,
    this.onFail,
  });
}

// --- Logical operator helpers for nested conditions ---

/// Returns a condition that is true if all provided conditions are true.
ConditionFunction all(List<ConditionFunction> conditions) {
  return (facts) => conditions.every((c) => c(facts));
}

/// Returns a condition that is true if any provided condition is true.
ConditionFunction any(List<ConditionFunction> conditions) {
  return (facts) => conditions.any((c) => c(facts));
}

/// Returns a condition that is true if none of the provided conditions are true.
ConditionFunction none(List<ConditionFunction> conditions) {
  return (facts) => !conditions.any((c) => c(facts));
}

/// Returns a condition that is the negation of the provided condition.
ConditionFunction not(ConditionFunction condition) {
  return (facts) => !condition(facts);
}

/// Returns a condition for equality.
ConditionFunction eq(String key, dynamic value) {
  return (facts) => facts[key] == value;
}

/// Returns a condition for inequality.
ConditionFunction neq(String key, dynamic value) {
  return (facts) => facts[key] != value;
}

/// Returns a condition for greater than.
ConditionFunction gt(String key, num value) {
  return (facts) => facts[key] != null && facts[key] > value;
}

/// Returns a condition for less than.
ConditionFunction lt(String key, num value) {
  return (facts) => facts[key] != null && facts[key] < value;
}

/// Returns a condition for greater than or equal.
ConditionFunction gte(String key, num value) {
  return (facts) => facts[key] != null && facts[key] >= value;
}

/// Returns a condition for less than or equal.
ConditionFunction lte(String key, num value) {
  return (facts) => facts[key] != null && facts[key] <= value;
}

/// Returns a condition for contains (for String or List).
ConditionFunction contains(String key, dynamic value) {
  return (facts) {
    final v = facts[key];
    if (v is String) return v.contains(value.toString());
    if (v is Iterable) return v.contains(value);
    return false;
  };
}

/// Returns a condition for startsWith (for String).
ConditionFunction startsWith(String key, String value) {
  return (facts) => facts[key] is String && facts[key].startsWith(value);
}

/// Returns a condition for endsWith (for String).
ConditionFunction endsWith(String key, String value) {
  return (facts) => facts[key] is String && facts[key].endsWith(value);
}
