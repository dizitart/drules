import 'package:uuid/uuid.dart';

/// @nodoc
const ruleId = 'ruleId';

/// Exception thrown by the Rule Engine.
class RuleEngineException implements Exception {
  /// A message describing the error.
  final String message;

  RuleEngineException(this.message);

  @override
  String toString() {
    return 'RuleEngineException: $message';
  }
}

/// Represents a JSON rule. A rule is a set of conditions and actions that can
/// be executed when the conditions are met.
///
/// A rule has the following properties:
///
/// - [id]: A unique identifier for the rule.
/// - [name]: A name for the rule.
/// - [priority]: A priority for the rule.
/// - [enabled]: A flag indicating whether the rule is enabled.
/// - [conditions]: A set of conditions that must be met for the rule to be executed.
/// - [actionInfo]: Information about the actions to be executed when the rule is activated.
///
/// A rule can have two types of actions:
///
/// - [onSuccess]: Actions to be executed when the rule is activated successfully.
/// - [onFailure]: Actions to be executed when the rule is not activated successfully.
class Rule {
  /// A unique identifier for the rule.
  ///
  /// If not provided, a random identifier will be generated.
  final String id;

  /// A name for the rule.
  ///
  /// This is optional.
  final String? name;

  /// A priority for the rule.
  ///
  /// Rules with higher priority values are executed first.
  final int priority;

  /// A flag indicating whether the rule is enabled.
  ///
  /// If set to `false`, the rule will not be executed.
  final bool enabled;

  /// A set of conditions that must be met for the rule to be executed.
  ///
  /// The conditions are defined using a [ConditionDefinition] object.
  final ConditionDefinition conditions;

  /// Information about the actions to be executed when the rule is activated.
  ///
  /// The actions are defined using an [ActionInfo] object.
  final ActionInfo actionInfo;

  Rule({
    this.name = '',
    this.priority = 0,
    this.enabled = true,
    required this.conditions,
    required this.actionInfo,
  }) : id = Uuid().v4().toString();

  /// Creates a [Rule] object from a JSON object.
  Rule.fromJson(Map<String, dynamic> json)
      : id = json['id'] ?? Uuid().v4().toString(),
        name = json['name'],
        priority = json['priority'] ?? 0,
        enabled = json['enabled'] ?? true,
        conditions = ConditionDefinition.fromJson(json['conditions']),
        actionInfo = ActionInfo.fromJson(json['actionInfo']);

  /// Converts the [Rule] object to a JSON object.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'priority': priority,
      'enabled': enabled,
      'conditions': conditions.toJson(),
      'actionInfo': actionInfo.toJson(),
    };
  }

  @override
  String toString() {
    return toJson().toString();
  }
}

/// Represents a condition definition. A condition definition is a set of
/// operands and an operator that can be used to evaluate a condition.
///
/// A condition definition has the following properties:
///
/// - [operator]: The operator to be used to evaluate the condition.
/// - [operands]: A list of operands to be used in the evaluation.
///
/// The [operator] property can be one of the following built-in operators or
/// any user-defined operator:
///
/// - `==`: Equal to
/// - `!=`: Not equal to
/// - `>`: Greater than
/// - `>=`: Greater than or equal to
/// - `<`: Less than
/// - `<=`: Less than or equal to
/// - `!`: Negation of the operand
/// - `all`: All operands must be true
/// - `any`: Any operand must be true
/// - `none`: None of the operands must be true
/// - `contains`: The first operand must contain the second operand
/// - `startsWith`: The first operand must start with the second operand
/// - `endsWith`: The first operand must end with the second operand
/// - `matches`: The first operand must match the regular expression in the second operand
/// - `expression`: The first operand must evaluate to true using the expression in the second operand
class ConditionDefinition {
  final String operator;
  final List operands;

  ConditionDefinition({
    required this.operator,
    required this.operands,
  });

  /// Creates a [ConditionDefinition] object from a JSON object.
  Map<String, dynamic> toJson() {
    return {
      'operator': operator,
      'operands': operands,
    };
  }

  /// Converts the [ConditionDefinition] object to a JSON object.
  static ConditionDefinition fromJson(Map<String, dynamic> json) {
    var operator = json['operator'] as String;
    var operands = json['operands'] as List;
    return ConditionDefinition(operator: operator, operands: operands);
  }
}

/// Represents information about the actions to be executed when a rule is activated.
///
/// The [ActionInfo] object has the following properties:
///
/// - [onSuccess]: The action to be executed when the rule is activated successfully.
/// - [onFailure]: The action to be executed when the rule is not activated successfully.
///
/// The [onSuccess] and [onFailure] properties are defined using an [ActionDefinition] object.
class ActionInfo {
  /// The action to be executed when the rule is activated successfully.
  final ActionDefinition? onSuccess;

  /// The action to be executed when the rule execution fails due to an error.
  final ActionDefinition? onFailure;

  ActionInfo({this.onSuccess, this.onFailure});

  /// Converts the [ActionInfo] object to a JSON object.
  Map<String, dynamic> toJson() {
    return {
      'onSuccess': onSuccess?.toJson(),
      'onFailure': onFailure?.toJson(),
    };
  }

  /// Creates an [ActionInfo] object from a JSON object.
  static ActionInfo fromJson(Map<String, dynamic> json) {
    var onSuccess = json['onSuccess'] != null
        ? ActionDefinition.fromJson(json['onSuccess'])
        : null;
    var onFailure = json['onFailure'] != null
        ? ActionDefinition.fromJson(json['onFailure'])
        : null;
    return ActionInfo(onSuccess: onSuccess, onFailure: onFailure);
  }
}

/// Represents an action definition. An action definition is a set of parameters
/// that can be used to execute an action.
///
/// An action definition has the following properties:
///
/// - [operation]: The operation to be executed.
/// - [parameters]: A list of parameters to be used in the operation.
///
/// The [operation] property can be one of the following built-in operations or
/// any user-defined operation:
///
/// - `print`: Prints the output to the console.
/// - `expression`: Evaluates a Dart expression.
/// - `stop`: Stops further execution of the rule or other actions in the pipeline.
/// - `chain`: All actions in the chain must be executed in the order they are defined.
/// - `parallel`: All actions in the parallel block must be executed in parallel.
/// - `pipe`: The output of one action is passed as input to the next action.
class ActionDefinition {
  /// The operation to be executed.
  final String operation;

  /// A list of parameters to be used in the operation.
  final List parameters;

  ActionDefinition({
    required this.operation,
    required this.parameters,
  });

  /// Converts the [ActionDefinition] object to a JSON object.
  Map<String, dynamic> toJson() {
    return {
      'operation': operation,
      'parameters': parameters,
    };
  }

  /// Creates an [ActionDefinition] object from a JSON object.
  static ActionDefinition fromJson(Map<String, dynamic> json) {
    var operation = json['operation'] as String;
    var parameters = json['parameters'] as List;
    return ActionDefinition(operation: operation, parameters: parameters);
  }
}

/// Represents the result of a rule execution.
class RuleResult {
  /// The unique identifier of the rule.
  final String ruleId;

  /// A flag indicating whether the rule was executed successfully without
  /// any error.
  final bool isSuccess;

  /// The result of the action executed by the rule.
  final ActionResult actionResult;

  RuleResult({
    required this.ruleId,
    required this.isSuccess,
    required this.actionResult,
  });

  @override
  String toString() {
    return 'RuleResult: { ruleId: $ruleId, '
        'isSuccess: $isSuccess, '
        'actionResult: $actionResult }';
  }
}

/// Represents the result of an action execution.
class ActionResult {
  /// The output of the action.
  final dynamic output;

  /// A flag indicating whether the action should continue executing other actions.
  final bool shouldContinue;

  /// The exception thrown by the action.
  final Exception? exception;

  /// The stack trace of the exception thrown by the action.
  final StackTrace? stackTrace;

  /// The list of child results of the action.
  final List<ActionResult> childResults;

  ActionResult({
    this.output,
    this.exception,
    this.stackTrace,
    this.shouldContinue = true,
    this.childResults = const [],
  });

  @override
  String toString() {
    if (exception != null) {
      return 'ActionResult: { exception: $exception, stackTrace: $stackTrace}';
    } else {
      return 'ActionResult: { output: $output, shouldContinue: $shouldContinue, '
          'childResults: $childResults}';
    }
  }
}
