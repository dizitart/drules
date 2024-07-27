import 'package:async/async.dart';
import 'package:drules/drules.dart';
import 'package:drules/src/repository.dart';
import 'package:template_expressions/template_expressions.dart' as t;

const lastResult = 'lastResult';

/// An abstract class representing an action.
abstract class Action {
  /// The name of the action.
  String get action;

  /// Execute the action with the given parameters and context.
  Future<ActionResult> execute(List parameters, RuleContext context);
}

/// Represents a custom action that is defined by the user.
///
/// The user can define a custom action by providing a name and a function
/// that takes a list of parameters and a [RuleContext] and returns a [Future].
/// The function should return the result of the action.
class CustomAction implements Action {
  final String _action;
  final Future Function(List, RuleContext) _function;

  CustomAction(this._action, this._function);

  @override
  String get action => _action;

  @override
  Future<ActionResult> execute(List parameters, RuleContext context) async {
    var result = await _function(parameters, context);
    return ActionResult(
      output: result,
      exception: null,
    );
  }
}

/// Represents an action that can execute a Dart expression.
///
/// The expression is evaluated using the `template_expressions` package.
/// The expression can be a simple Dart expression or a template expression.
/// The result of the expression is returned as the output of the action.
class ExpressionAction implements Action {
  @override
  String get action => "expression";

  @override
  Future<ActionResult> execute(List parameters, RuleContext context) async {
    var expression = parameters.first;
    final evaluator = t.ExpressionEvaluator(
      memberAccessors: context.getResolve() ?? [],
    );

    final parsed = t.Expression.parse(expression);
    var output = evaluator.eval(
      parsed,
      context.getFacts(),
      onValueAssigned: (name, value) => context.addFact(name, value),
    );

    return ActionResult(
      output: output,
    );
  }
}

/// Represents an action that should stop further execution of the rule or
/// other actions in the pipeline.
///
/// This action is useful when you want to stop the execution of the rule
/// based on some condition.
class Stop implements Action {
  @override
  String get action => "stop";

  @override
  Future<ActionResult> execute(List parameters, RuleContext context) async {
    return ActionResult(
      output: null,
      exception: null,
      shouldContinue: false,
    );
  }
}

/// Represents an action that should print a message to the console.
///
/// The message can be a simple string or a template expression. The message
/// is evaluated using the `template_expressions` package.
///
/// The evaluated message is also returned as the output of the action.
class Print implements Action {
  @override
  String get action => "print";

  @override
  Future<ActionResult> execute(List parameters, RuleContext context) async {
    if (parameters.isEmpty) {
      throw RuleEngineException('Invalid PRINT parameters - $parameters');
    }

    var param = parameters.first;

    // resolve and evaluate the print message
    final template = t.Template(value: param);

    final message = await template.processAsync(
      context: context.getFacts(),
      memberAccessors: context.getResolve() ?? [],
    );

    print('Rule Engine: $message');
    return ActionResult(
      output: message,
      exception: null,
    );
  }
}

/// Represents a form of execution where all actions are executed as a series
/// of commands where the second action does not depened on the output of
/// the first action. The results of each action is returned as `childResults`
/// in the final result.
///
/// If any of the child result's `shouldContinue` is false, then the chain
/// should not continue.
///
/// The order of the actions is guaranteed and the output of the last action
/// is returned as the output of the chain.
class Chain implements Action {
  @override
  String get action => "chain";

  @override
  Future<ActionResult> execute(List parameters, RuleContext context) async {
    if (parameters.isEmpty) {
      throw RuleEngineException('Invalid CHAIN parameters - $parameters');
    }

    var childResults = <ActionResult>[];

    for (var actionDefinition in parameters) {
      var operation = actionDefinition['operation'] as String;
      var parameters = actionDefinition['parameters'] as List;

      var action = ActionRepository().findAction(operation);
      if (action == null) {
        throw RuleEngineException(
            'No action is registered with name $operation.');
      }

      var result = await action.execute(parameters, context);
      childResults.add(result);

      if (!result.shouldContinue) {
        break;
      }
    }

    // if any of the child results is false, then the chain should not continue
    var shouldContinue =
        childResults.every((element) => element.shouldContinue);

    return ActionResult(
      output: childResults.last.output,
      exception: null,
      childResults: childResults,
      shouldContinue: shouldContinue,
    );
  }
}

/// Represents a form of execution where the output of the previous action
/// is fed as the input of the next action. The output of the last action is
/// added as fact in the [RuleContext] with the key `lastResult`. The results
/// of each action is returned as `childResults` in the final result.
///
/// If any of the child result's `shouldContinue` is false, then the pipeline
/// should not continue.
///
/// The order of the actions is guaranteed and the output of the last action
/// is returned as the output of the pipeline.
class Pipe implements Action {
  @override
  String get action => "pipe";

  @override
  Future<ActionResult> execute(List parameters, RuleContext context) async {
    if (parameters.isEmpty) {
      throw RuleEngineException('Invalid PIPE parameters - $parameters');
    }

    var childResults = <ActionResult>[];
    ActionResult? result;

    for (var actionDefinition in parameters) {
      var operation = actionDefinition['operation'] as String;
      var parameters = actionDefinition['parameters'] as List;

      var action = ActionRepository().findAction(operation);
      if (action == null) {
        throw RuleEngineException(
            'No action is registered with name $operation.');
      }

      result = await action.execute(parameters, context);
      context.addFact(lastResult, result.output);
      childResults.add(result);

      if (!result.shouldContinue) {
        break;
      }
    }

    var shouldContinue =
        childResults.every((element) => element.shouldContinue);

    return ActionResult(
      output: result?.output,
      exception: null,
      childResults: childResults,
      shouldContinue: shouldContinue,
    );
  }
}

/// Represents a form of execution where all actions are executed in parallel
/// and no order is guaranteed. The results of each action is returned as
/// `childResults` in the final result.
///
/// There is no effect of the `shouldContinue` of the child results on the
/// parallel execution.
class Parallel implements Action {
  @override
  String get action => "parallel";

  @override
  Future<ActionResult> execute(List parameters, RuleContext context) async {
    if (parameters.isEmpty) {
      throw RuleEngineException('Invalid PARALLEL parameters - $parameters');
    }

    var futures = FutureGroup<ActionResult>();

    for (var actionDefinition in parameters) {
      var operation = actionDefinition['operation'] as String;
      var parameters = actionDefinition['parameters'] as List;

      var action = ActionRepository().findAction(operation);
      if (action == null) {
        throw RuleEngineException(
            'No action is registered with name $operation.');
      }

      futures.add(action.execute(parameters, context));
    }

    futures.close();

    var results = await futures.future;
    var shouldContinue = results.every((element) => element.shouldContinue);

    return ActionResult(
      output: results.last.output,
      exception: null,
      childResults: results,
      shouldContinue: shouldContinue,
    );
  }
}
