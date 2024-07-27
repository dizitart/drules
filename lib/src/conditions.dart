import 'package:drules/drules.dart';
import 'package:drules/src/repository.dart';
import 'package:template_expressions/template_expressions.dart' as t;

/// An abstract class representing a condition.
///
/// A condition is a logical expression that evaluates to true or false.
/// The condition can be a simple comparison or a complex expression.
/// The condition can have one or more operands. The operands can be other
/// conditions or values.
abstract class Condition {
  /// The name of the condition.
  String get operator;

  /// Evaluate the condition with the given operands and context.
  bool evaluate(List operands, RuleContext context);
}

class CustomCondition implements Condition {
  final String _operator;
  final bool Function(List, RuleContext) _function;

  CustomCondition(this._operator, this._function);

  @override
  String get operator => _operator;

  @override
  bool evaluate(List operands, RuleContext context) {
    return _function(operands, context);
  }
}

/// Represents a condition that checks if all the conditions are true.
///
/// The condition evaluates to true if all the conditions are true. The
/// condition can have one or more conditions as operands.
class All implements Condition {
  @override
  final String operator = "all";

  @override
  bool evaluate(List operands, RuleContext context) {
    if (operands.isEmpty) {
      throw RuleEngineException('Invalid ALL definition - no operands found');
    }

    var conditionDefitions = operands;
    for (var conditionDefinition in conditionDefitions) {
      var operator = conditionDefinition['operator'] as String;
      var operands = conditionDefinition['operands'] as List;

      var condition = ConditionRepository().findCondition(operator);
      if (condition == null) {
        throw RuleEngineException('Condition is not registered - $operator');
      }

      if (condition.evaluate(operands, context) == false) {
        return false;
      }
    }

    return true;
  }
}

/// Represents a condition that checks if any of the conditions are true.
///
/// The condition evaluates to true if any of the conditions are true. The
/// condition can have one or more conditions as operands.
class Any implements Condition {
  @override
  final String operator = "any";

  @override
  bool evaluate(List operands, RuleContext context) {
    if (operands.isEmpty) {
      throw RuleEngineException('Invalid ANY definition - no operands found');
    }

    var conditionDefitions = operands;
    for (var conditionDefinition in conditionDefitions) {
      var operator = conditionDefinition['operator'] as String;
      var operands = conditionDefinition['operands'] as List;

      var condition = ConditionRepository().findCondition(operator);
      if (condition == null) {
        throw RuleEngineException('Condition is not registered - $operator');
      }

      if (condition.evaluate(operands, context) == true) {
        return true;
      }
    }

    return false;
  }
}

/// Represents a condition that checks if none of the conditions are true.
///
/// The condition evaluates to true if none of the conditions are true. The
/// condition can have one or more conditions as operands.
class None implements Condition {
  @override
  final String operator = 'none';

  @override
  bool evaluate(List operands, RuleContext context) {
    if (operands.isEmpty) {
      throw RuleEngineException('Invalid NONE definition - no operands found');
    }

    var conditionDefitions = operands;
    for (var conditionDefinition in conditionDefitions) {
      var operator = conditionDefinition['operator'] as String;
      var operands = conditionDefinition['operands'] as List;

      var condition = ConditionRepository().findCondition(operator);
      if (condition == null) {
        throw RuleEngineException('Condition is not registered - $operator');
      }

      if (condition.evaluate(operands, context) == true) {
        return false;
      }
    }

    return true;
  }
}

/// Represents a condition that evaluates to true if the operands are equal.
///
/// The condition can have two operands. The first operand is the fact name
/// and the second operand is the value to compare with. The condition evaluates
/// to true if the fact value is equal to the value of the second operand.
class Eq implements Condition {
  @override
  String get operator => "==";

  @override
  bool evaluate(List operands, RuleContext context) {
    if (operands.isEmpty || operands.length < 2) {
      throw RuleEngineException('Invalid EQ definition - invalid operands');
    }

    var first = operands[0];
    var second = operands[1];
    var firstValue = context.getFact(first);

    if (firstValue == null) {
      return false;
    }

    return firstValue == second;
  }
}

/// Represents a condition that evaluates to true if the operands are not equal.
///
/// The condition can have two operands. The first operand is the fact name
/// and the second operand is the value to compare with. The condition evaluates
/// to true if the fact value is not equal to the value of the second operand.
class Neq implements Condition {
  @override
  String get operator => "!=";

  @override
  bool evaluate(List operands, RuleContext context) {
    if (operands.isEmpty || operands.length < 2) {
      throw RuleEngineException('Invalid NEQ definition - invalid operands');
    }

    var first = operands[0];
    var second = operands[1];
    var firstValue = context.getFact(first);

    if (firstValue == null) {
      return false;
    }

    return firstValue != second;
  }
}

/// Represents a condition that evaluates to true if the operands are greater
/// than the second operand.
///
/// The condition can have two operands. The first operand is the fact name
/// and the second operand is the value to compare with. The condition evaluates
/// to true if the fact value is greater than the value of the second operand.
class Gt implements Condition {
  @override
  String get operator => ">";

  @override
  bool evaluate(List operands, RuleContext context) {
    if (operands.isEmpty || operands.length < 2) {
      throw RuleEngineException('Invalid GT definition - invalid operands');
    }

    var first = operands[0];
    var second = operands[1];
    var firstValue = context.getFact(first);

    if (firstValue == null) {
      return false;
    }

    return firstValue > second;
  }
}

/// Represents a condition that evaluates to true if the operands are greater
/// than or equal to the second operand.
///
/// The condition can have two operands. The first operand is the fact name
/// and the second operand is the value to compare with. The condition evaluates
/// to true if the fact value is greater than or equal to the value of the
/// second operand.
class Gte implements Condition {
  @override
  String get operator => ">=";

  @override
  bool evaluate(List operands, RuleContext context) {
    if (operands.isEmpty || operands.length < 2) {
      throw RuleEngineException('Invalid GTE definition - invalid operands');
    }

    var first = operands[0];
    var second = operands[1];
    var firstValue = context.getFact(first);

    if (firstValue == null) {
      return false;
    }

    return firstValue >= second;
  }
}

/// Represents a condition that evaluates to true if the operands are less than
/// the second operand.
///
/// The condition can have two operands. The first operand is the fact name
/// and the second operand is the value to compare with. The condition evaluates
/// to true if the fact value is less than the value of the second operand.
class Lt implements Condition {
  @override
  String get operator => "<";

  @override
  bool evaluate(List operands, RuleContext context) {
    if (operands.isEmpty || operands.length < 2) {
      throw RuleEngineException('Invalid LT definition - invalid operands');
    }

    var first = operands[0];
    var second = operands[1];
    var firstValue = context.getFact(first);

    if (firstValue == null) {
      return false;
    }

    return firstValue < second;
  }
}

/// Represents a condition that evaluates to true if the operands are less than
/// or equal to the second operand.
///
/// The condition can have two operands. The first operand is the fact name
/// and the second operand is the value to compare with. The condition evaluates
/// to true if the fact value is less than or equal to the value of the
/// second operand.
class Lte implements Condition {
  @override
  String get operator => "<=";

  @override
  bool evaluate(List operands, RuleContext context) {
    if (operands.isEmpty || operands.length < 2) {
      throw RuleEngineException('Invalid LTE definition - invalid operands');
    }

    var first = operands[0];
    var second = operands[1];
    var firstValue = context.getFact(first);

    if (firstValue == null) {
      return false;
    }

    return firstValue <= second;
  }
}

/// Represents a condition that evaluates to true if the first operand is not
/// true.
///
/// The condition can have one operand. The condition evaluates to true if the
/// value of the first operand is not true.
class Not implements Condition {
  @override
  String get operator => "!";

  @override
  bool evaluate(List operands, RuleContext context) {
    if (operands.isEmpty) {
      throw RuleEngineException('Invalid NOT definition - no operands found');
    }

    var first = operands[0];

    var firstCondition = ConditionRepository().findCondition(first['operator']);
    if (firstCondition == null) {
      throw RuleEngineException(
          'Condition is not registered - ${first['operator']}');
    }

    var firstOperands = first['operands'] as List;
    var firstValue = firstCondition.evaluate(firstOperands, context);

    return !firstValue;
  }
}

/// Represents a condition that evaluates to true if the first operand contains
/// the second operand.
///
/// The condition can have two operands. The first operand is the fact name
/// and the second operand is the value to compare with. The condition evaluates
/// to true if the fact value contains the value of the second operand.
class Contains implements Condition {
  @override
  String get operator => "contains";

  @override
  bool evaluate(List operands, RuleContext context) {
    if (operands.isEmpty || operands.length < 2) {
      throw RuleEngineException(
          'Invalid CONTAINS definition - invalid operands');
    }

    var first = operands[0];
    var second = operands[1];
    var firstValue = context.getFact(first);

    if (firstValue == null) {
      return false;
    }

    return firstValue.contains(second);
  }
}

/// Represents a condition that evaluates to true if the first operand starts
/// with the second operand.
///
/// The condition can have two operands. The first operand is the fact name
/// and the second operand is the value to compare with. The condition evaluates
/// to true if the fact value starts with the value of the second operand.
class StartsWith implements Condition {
  @override
  String get operator => "startsWith";

  @override
  bool evaluate(List operands, RuleContext context) {
    if (operands.isEmpty || operands.length < 2) {
      throw RuleEngineException(
          'Invalid STARTSWITH definition - invalid operands');
    }

    var first = operands[0];
    var second = operands[1];
    var firstValue = context.getFact(first);

    if (firstValue == null) {
      return false;
    }

    return firstValue.startsWith(second);
  }
}

/// Represents a condition that evaluates to true if the first operand ends
/// with the second operand.
///
/// The condition can have two operands. The first operand is the fact name
/// and the second operand is the value to compare with. The condition evaluates
/// to true if the fact value ends with the value of the second operand.
class EndsWith implements Condition {
  @override
  String get operator => "endsWith";

  @override
  bool evaluate(List operands, RuleContext context) {
    if (operands.isEmpty || operands.length < 2) {
      throw RuleEngineException(
          'Invalid ENDSWITH definition - invalid operands');
    }

    var first = operands[0];
    var second = operands[1];
    var firstValue = context.getFact(first);

    if (firstValue == null) {
      return false;
    }

    return firstValue.endsWith(second);
  }
}

/// Represents a condition that evaluates to true if the first operand matches
/// the regular expression pattern of the second operand.
///
/// The condition can have two operands. The first operand is the fact name
/// and the second operand is the regular expression pattern to compare with.
class Matches implements Condition {
  @override
  String get operator => "matches";

  @override
  bool evaluate(List operands, RuleContext context) {
    if (operands.isEmpty || operands.length < 2) {
      throw RuleEngineException('Invalid REGEX definition - invalid operands');
    }

    var first = operands[0];
    var second = operands[1];
    var firstValue = context.getFact(first);

    if (firstValue == null) {
      return false;
    }

    if (second == null || second.isEmpty) {
      throw RuleEngineException('Invalid REGEX definition - invalid pattern');
    }

    return RegExp(second).hasMatch(firstValue);
  }
}

/// Represents a condition that evaluates to true if the expression evaluates
/// to is true.
///
/// The condition can have one operand. The operand is the expression to evaluate.
/// The expression is evaluated using the `template_expressions` package.
class ExpressionCondition implements Condition {
  @override
  String get operator => "expression";

  @override
  bool evaluate(List operands, RuleContext context) {
    if (operands.isEmpty) {
      throw RuleEngineException(
          'Invalid EXPRESSION definition - no operands found');
    }

    var expression = operands.first;

    final evaluator = t.ExpressionEvaluator(
      memberAccessors: context.getResolve() ?? [],
    );

    try {
      final parsed = t.Expression.parse(expression);
      return evaluator.eval(
        parsed,
        context.getFacts(),
        onValueAssigned: (name, value) => context.addFact(name, value),
      );
    } catch (e) {
      throw RuleEngineException('Invalid EXPRESSION definition - $expression');
    }
  }
}
